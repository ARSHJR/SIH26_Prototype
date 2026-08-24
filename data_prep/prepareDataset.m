function [trainDS, valDS, testDS] = prepareDataset(idridRootPath)
% PREPAREDATASET  Load IDRiD into train/val/test image datastores,
%   labeled by ICDR grade (0-4). IDRiD-only for the 12-hour demo —
%   APTOS integration deferred to the MVP phase.
%
% USAGE:
%   [trainDS, valDS, testDS] = prepareDataset( ...
%       'C:\basicallyD\Internships_Courses\University of Edinburgh\UQ-Internship\local-replication-phase\datasets\LMOD+\home\jd2899\project\IDRID');
%
% Structure assumed:
%   idridRootPath\Testing\IDRiD_XXX\visualization.png   (confirmed: raw fundus image)
%   idridRootPath\Testing\IDRiD_XXX\information.json
%   idridRootPath\Training\IDRiD_XXX\...  (same layout)
%
% This script doesn't know your information.json's exact field name for
% the DR grade. On the FIRST file it reads, it prints all available JSON
% fields so you (or Claude Code) can confirm/correct LABEL_FIELD_CANDIDATES
% below before it silently processes the rest.

    IMAGE_FILENAME = 'visualization.png';
    % Each candidate is a dot-path, tried in order. The ICDR grade lives
    % nested under "metadata" in this dataset's information.json (confirmed
    % 2026-08-25 against IDRiD_408), not at the top level.
    LABEL_FIELD_CANDIDATES = {'metadata.retinopathy_grade', 'retinopathy_grade', ...
        'metadata.grade', 'grade', 'metadata.dr_grade', 'dr_grade', ...
        'metadata.DR_grade', 'DR_grade', 'metadata.label', 'label', ...
        'metadata.diagnosis', 'diagnosis', 'metadata.severity', 'severity'};

    idridFiles = {};
    idridLabels = [];
    fieldNamesPrinted = false;

    for splitFolder = ["Testing", "Training"]
        splitPath = fullfile(idridRootPath, splitFolder);
        if ~isfolder(splitPath)
            warning('Expected folder not found: %s — skipping', splitPath);
            continue;
        end

        imageDirs = dir(splitPath);
        imageDirs = imageDirs([imageDirs.isdir] & ~startsWith({imageDirs.name}, '.'));

        for k = 1:numel(imageDirs)
            imgFolder = fullfile(splitPath, imageDirs(k).name);
            imgFile = fullfile(imgFolder, IMAGE_FILENAME);
            jsonFile = fullfile(imgFolder, 'information.json');

            if ~isfile(imgFile) || ~isfile(jsonFile)
                warning('Missing expected files in %s — skipping this image', imgFolder);
                continue;
            end

            info = jsondecode(fileread(jsonFile));

            if ~fieldNamesPrinted
                fprintf('\n=== First information.json — available fields ===\n');
                disp(fieldnames(info));
                fprintf('Script will try these field names for the DR grade, in order: %s\n', ...
                    strjoin(LABEL_FIELD_CANDIDATES, ', '));
                fprintf('If none match what you see above, edit LABEL_FIELD_CANDIDATES in this script.\n\n');
                fieldNamesPrinted = true;
            end

            grade = [];
            for c = 1:numel(LABEL_FIELD_CANDIDATES)
                fpath = LABEL_FIELD_CANDIDATES{c};
                grade = getNestedField(info, strsplit(fpath, '.'));
                if ~isempty(grade)
                    break;
                end
            end

            if isempty(grade)
                warning('No matching grade field found in %s — skipping. Check the printed field names above.', jsonFile);
                continue;
            end

            idridFiles{end+1, 1} = char(imgFile); %#ok<AGROW>
            idridLabels(end+1, 1) = double(grade); %#ok<AGROW>
        end
    end

    fprintf('IDRiD: found %d usable images with labels\n', numel(idridFiles));

    if numel(idridFiles) == 0
        error('No usable images found. Check IMAGE_FILENAME / LABEL_FIELD_CANDIDATES / idridRootPath.');
    end

    idridLabels = categorical(idridLabels);
    imds = imageDatastore(idridFiles, 'Labels', idridLabels);

    fprintf('\nClass distribution:\n');
    summary(imds.Labels)

    % ---- Split ----
    % Very small dataset (~20 images total per prior discussion) — a
    % stratified 70/15/15 split per class will likely fail (some classes
    % may have only 3-4 images total). Fall back gracefully if so.
    try
        [trainDS, valDS, testDS] = splitEachLabel(imds, 0.7, 0.15, 0.15, 'randomized');
    catch ME
        warning('Stratified 70/15/15 split failed (%s) — too few images per class for this tiny subset. Falling back to 80/20 train/test, reusing test as validation.', ME.message);
        [trainDS, testDS] = splitEachLabel(imds, 0.8, 'randomized');
        valDS = testDS;
    end

    fprintf('\nDataset prepared: %d train, %d val, %d test images\n', ...
        numel(trainDS.Files), numel(valDS.Files), numel(testDS.Files));
    fprintf('(This is a small feasibility-demo dataset, not MVP-scale — expect noisy metrics)\n');
end

function val = getNestedField(s, pathParts)
% GETNESTEDFIELD  Walk a dot-path (as cellstr) of struct field names.
%   Returns [] if any part of the path doesn't exist.
    val = [];
    cur = s;
    for i = 1:numel(pathParts)
        if isstruct(cur) && isfield(cur, pathParts{i})
            cur = cur.(pathParts{i});
        else
            return;
        end
    end
    val = cur;
end
