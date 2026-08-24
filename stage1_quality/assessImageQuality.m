function [isGradeable, report] = assessImageQuality(img)
% ASSESSIMAGEQUALITY  Quick heuristic quality gate for fundus images.
% Checks focus (sharpness), illumination uniformity, and field-of-view coverage.
% Returns isGradeable (bool) and a report struct explaining why, for the
% "recapture feedback" requirement in the PS.
%
% This is deliberately simple/classical — good enough for a feasibility demo.
% Thresholds below are rough starting points; tune them against a few real
% good/bad images from your dataset rather than trusting these blindly.

    if size(img, 3) == 3
        gray = rgb2gray(img);
    else
        gray = img;
    end
    gray = im2double(gray);

    % --- Focus / sharpness: Laplacian variance ---
    lap = fspecial('laplacian');
    sharpness = var(imfilter(gray, lap, 'replicate'), 0, 'all');
    % Calibrated against 10 real IDRiD test images (sharpness 0.00026-0.00039,
    % all normal in-focus fundus photos) vs. the same 10 images with heavy
    % Gaussian blur applied (sharpness 0.0000057-0.0000069) — nearly two
    % orders of magnitude apart. 0.0005 was above the real-image cluster
    % entirely, rejecting every real image as "out of focus". 0.0001 sits
    % between the two clusters with margin on both sides.
    focusOK = sharpness > 0.0001;

    % --- Illumination uniformity ---
    meanIntensity = mean(gray, 'all');
    stdIntensity = std(gray, 0, 'all');
    illuminationOK = meanIntensity > 0.15 && meanIntensity < 0.85 && stdIntensity > 0.05;

    % --- Field of view: fraction of non-black (retina-covered) pixels ---
    fovMask = gray > 0.05;
    fovCoverage = sum(fovMask, 'all') / numel(fovMask);
    fovOK = fovCoverage > 0.35;   % TUNE — depends on how images are cropped

    isGradeable = focusOK && illuminationOK && fovOK;

    report.sharpness = sharpness;
    report.focusOK = focusOK;
    report.meanIntensity = meanIntensity;
    report.illuminationOK = illuminationOK;
    report.fovCoverage = fovCoverage;
    report.fovOK = fovOK;

    if ~isGradeable
        reasons = {};
        if ~focusOK, reasons{end+1} = 'out of focus'; end
        if ~illuminationOK, reasons{end+1} = 'poor illumination'; end
        if ~fovOK, reasons{end+1} = 'insufficient field of view'; end
        report.recaptureMessage = ['Recapture needed: ' strjoin(reasons, ', ')];
    else
        report.recaptureMessage = 'Image accepted for grading';
    end
end
