% RUNRETRAINWITHSEED  Retrain from scratch against the newly-seeded
% (rng(42)) train/val/test split, then save the network and the exact
% test-set file list so the held-out set is auditable.
addpath('../data_prep');

idridRoot = 'C:\basicallyD\Internships_Courses\University of Edinburgh\UQ-Internship\local-replication-phase\datasets\LMOD+\home\jd2899\project\IDRID';

fprintf('Preparing seeded dataset split (rng(42) inside prepareDataset.m)...\n');
[trainDS, valDS, testDS] = prepareDataset(idridRoot);

fprintf('Train: %d, Val: %d, Test: %d\n', numel(trainDS.Files), numel(valDS.Files), numel(testDS.Files));

trainFiles = trainDS.Files;
valFiles = valDS.Files;
testFiles = testDS.Files;
save('splitFileLists.mat', 'trainFiles', 'valFiles', 'testFiles');

fprintf('\nTraining classifier (5 epochs, squeezenet, Grade-1 oversampling)...\n');
net = trainDRClassifier(trainDS, valDS);

save('../trainedDRNet.mat', 'net');
fprintf('Saved retrained network to trainedDRNet.mat\n');
