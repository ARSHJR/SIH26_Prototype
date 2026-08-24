% RUNEVALUATION  Driver: load trained net + IDRiD test split, run evaluateClassifier.
addpath('../data_prep');

idridRoot = 'C:\basicallyD\Internships_Courses\University of Edinburgh\UQ-Internship\local-replication-phase\datasets\LMOD+\home\jd2899\project\IDRID';

fprintf('Loading trained network...\n');
loaded = load('../trainedDRNet.mat');
net = loaded.net;

fprintf('Preparing dataset (same split logic used for training)...\n');
[~, ~, testDS] = prepareDataset(idridRoot);

inputSize = net.Layers(1).InputSize;
fprintf('Network input size: %s\n', mat2str(inputSize));
fprintf('Test set size: %d images\n', numel(testDS.Files));

% Resize on read (no augmentation) so classify() gets correctly-sized
% input while testDS stays a plain imageDatastore -- evaluateClassifier
% reads testDS.Labels directly, so we keep that contract intact.
targetSize = inputSize(1:2);
testDS.ReadFcn = @(filename) imresize(readAsRGB(filename), targetSize);

results = evaluateClassifier(net, testDS);

save('evaluationResults.mat', 'results');
fprintf('\nSaved results to stage3_classifier/evaluationResults.mat\n');

function img = readAsRGB(filename)
    img = imread(filename);
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end
end
