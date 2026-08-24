function net = trainDRClassifier(trainDS, valDS)
% TRAINDRCLASSIFIER  Fine-tune squeezenet for ICDR 0-4 grading.
%
% Verified working end-to-end on this machine (MATLAB R2026a, Deep Learning
% Toolbox) against the real IDRiD dataset: 5 epochs, squeezenet backbone,
% trainNetwork (not trainnet — no deprecation issue on this version).
% resnet50/resnet18/googlenet/mobilenetv2/efficientnetb0/alexnet all require
% support-package installs not present here, so squeezenet (bundled with
% Deep Learning Toolbox) is the backbone actually in use — see the layer
% names below, which are squeezenet's, not resnet50's.
%
% For a 12-hour feasibility demo: keep MaxEpochs low (3-5). You are NOT
% trying to hit the 90%/85% target right now — you're proving the training
% loop runs and loss decreases.

    % --- Load pretrained backbone ---
    % resnet50/resnet18/googlenet/mobilenetv2/efficientnetb0/alexnet all
    % require separate support-package installs that aren't present on this
    % machine (verified via exist()/direct load — all failed with
    % nnet_cnn:supportpackages:NotInstalled). squeezenet ships with Deep
    % Learning Toolbox itself, so it's what's actually usable here.
    net = squeezenet;
    lgraph = layerGraph(net);

    numClasses = 5;   % ICDR grades 0-4

    % --- Replace final classification layers ---
    % squeezenet classifies via a 1x1 conv ('conv10'), not a fully-connected
    % layer — confirmed by inspecting lgraph.Layers on this MATLAB version.
    newConv = convolution2dLayer(1, numClasses, 'Name', 'new_conv10');
    lgraph = replaceLayer(lgraph, 'conv10', newConv);
    newClassLayer = classificationLayer('Name', 'new_classoutput');
    lgraph = replaceLayer(lgraph, 'ClassificationLayer_predictions', newClassLayer);

    % --- Class imbalance handling: oversample Grade 1 (training set only) ---
    % Grade 1 is badly underrepresented (~17 samples). Duplicate its training
    % files ~4x (~17 -> ~65-70 effective samples) so augmentation sees enough
    % of that class. valDS/testDS are left at the real class distribution so
    % reported metrics stay honest.
    grade1Mask = trainDS.Labels == categorical(1);
    grade1Files = trainDS.Files(grade1Mask);
    grade1Labels = trainDS.Labels(grade1Mask);
    oversampleFactor = 4;
    extraFiles = repmat(grade1Files, oversampleFactor - 1, 1);
    extraLabels = repmat(grade1Labels, oversampleFactor - 1, 1);

    trainDS = imageDatastore([trainDS.Files; extraFiles], ...
        'Labels', [trainDS.Labels; extraLabels]);

    % --- Data augmentation (helps with the small dataset) ---
    augmenter = imageDataAugmenter( ...
        'RandRotation', [-15 15], ...
        'RandXReflection', true, ...
        'RandXTranslation', [-10 10], ...
        'RandYTranslation', [-10 10]);

    inputSize = net.Layers(1).InputSize;
    augTrainDS = augmentedImageDatastore(inputSize(1:2), trainDS, 'DataAugmentation', augmenter);
    augValDS = augmentedImageDatastore(inputSize(1:2), valDS);

    % augmentedImageDatastore defaults to MiniBatchSize=128 for its own
    % internal reads — it warps/resizes that many FULL-RESOLUTION source
    % images (4288x2848 here) at once before downsizing, which OOM'd
    % (confirmed: warpImage2D threw "Out of memory" reading only ~2 batches
    % in). Align it to the training MiniBatchSize below so it downsizes in
    % much smaller chunks.
    trainingMiniBatchSize = 16;
    augTrainDS.MiniBatchSize = trainingMiniBatchSize;
    augValDS.MiniBatchSize = trainingMiniBatchSize;

    % --- Training options ---
    % NOTE: for a 12-hour demo, keep MaxEpochs LOW (e.g. 3-5) — you're
    % demonstrating the pipeline works, not chasing final accuracy.
    options = trainingOptions('adam', ...
        'InitialLearnRate', 1e-4, ...
        'MaxEpochs', 5, ...             % keep low for time budget
        'MiniBatchSize', trainingMiniBatchSize, ...
        'ValidationData', augValDS, ...
        'ValidationFrequency', 20, ...
        'Plots', 'none', ...            % 'training-progress' needs a GUI; use 'none' for batch runs
        'DispatchInBackground', false, ...  % background workers OOM'd on these large (4288x2848) source images
        'OutputNetwork', 'best-validation-loss', ...
        'Verbose', true);

    % --- Train ---
    net = trainNetwork(augTrainDS, lgraph, options);

    fprintf('Training complete. Save this network before moving to Stage 4:\n');
    fprintf('  save(''trainedDRNet.mat'', ''net'');\n');
end
