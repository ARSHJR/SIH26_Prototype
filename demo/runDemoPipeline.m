function runDemoPipeline(imagePath, net)
% RUNDEMOPIPELINE  Chain Stage 1 -> Stage 3 -> Stage 4 on one sample image
% and produce an annotated report. This is the actual demo moment for your
% PPT/pitch — run this live if possible, or record it.
%
% USAGE:
%   load('trainedDRNet.mat');   % from Stage 3
%   runDemoPipeline('path/to/sample_fundus.jpg', net);

    addpath('../stage1_quality');
    addpath('../stage4_explainability');

    img = imread(imagePath);

    % --- Stage 1: Quality gate ---
    [isGradeable, qualityReport] = assessImageQuality(img);
    fprintf('Stage 1 — Quality Assessment: %s\n', qualityReport.recaptureMessage);

    if ~isGradeable
        fprintf('Image rejected. Demo stops here — this IS the correct behavior for a bad image.\n');
        fprintf('Try again with a clearer sample image, or use this as your "rejection" demo case.\n');
        return;
    end

    enhancedImg = enhanceImage(img);

    % --- Stage 3: Classification ---
    inputSize = net.Layers(1).InputSize;
    resizedImg = imresize(enhancedImg, inputSize(1:2));
    [predictedLabel, scores] = classify(net, resizedImg);
    confidence = max(scores);

    fprintf('Stage 3 — Predicted ICDR Grade: %s (raw confidence: %.1f%%)\n', ...
        string(predictedLabel), confidence * 100);

    % --- Stage 4: Explainability ---
    [heatmap, overlayImg] = generateGradCAM(net, resizedImg, predictedLabel);

    % --- Assemble annotated report figure ---
    figure('Name', 'DR Screening Report');
    subplot(1,3,1); imshow(img); title('Original');
    subplot(1,3,2); imshow(enhancedImg); title('Enhanced (Stage 1)');
    subplot(1,3,3); imshow(overlayImg); title(sprintf('Grade %s, Grad-CAM (Stage 4)', string(predictedLabel)));

    fprintf('\n=== Annotated Report ===\n');
    fprintf('Grade: %s\n', string(predictedLabel));
    fprintf('Confidence: %.1f%%\n', confidence * 100);
    fprintf('Referable: %s\n', string(double(predictedLabel) >= 3));
    fprintf('(This is the report format your ophthalmologist reviewer would see —\n');
    fprintf(' designed for a <30-second glance-and-confirm workflow per the PS)\n');
end
