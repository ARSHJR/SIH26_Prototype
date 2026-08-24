function results = evaluateClassifier(net, testDS)
% EVALUATECLASSIFIER  Report both 5-class and binary-referable-DR metrics.
% Remember: the PS's >90%/>85% target is for the BINARY referable-DR (Grade>=2)
% framing specifically — report both, but don't panic if 5-class accuracy is
% modest for this prototype. That's expected and fine to state honestly.

    predictedLabels = classify(net, testDS);
    trueLabels = testDS.Labels;

    % --- 5-class metrics ---
    confMat = confusionmat(trueLabels, predictedLabels);
    accuracy5class = sum(diag(confMat)) / sum(confMat, 'all');

    % --- Quadratic Weighted Kappa (standard DR grading metric) ---
    qwk = computeQWK(double(trueLabels) - 1, double(predictedLabels) - 1, 5);

    % --- Binary referable-DR framing (Grade 0-1 = not referable, 2-4 = referable) ---
    trueReferable = double(trueLabels) >= 3;   % categorical indices are 1-based (grade 2 = index 3)
    predReferable = double(predictedLabels) >= 3;

    tp = sum(trueReferable & predReferable);
    tn = sum(~trueReferable & ~predReferable);
    fp = sum(~trueReferable & predReferable);
    fn = sum(trueReferable & ~predReferable);

    sensitivity = tp / (tp + fn);
    specificity = tn / (tn + fp);

    results.accuracy5class = accuracy5class;
    results.qwk = qwk;
    results.confusionMatrix = confMat;
    results.sensitivity = sensitivity;
    results.specificity = specificity;

    fprintf('\n=== Evaluation Results ===\n');
    fprintf('5-class exact accuracy: %.1f%%\n', accuracy5class * 100);
    fprintf('Quadratic Weighted Kappa: %.3f\n', qwk);
    fprintf('Referable DR (Grade 2+) sensitivity: %.1f%%\n', sensitivity * 100);
    fprintf('Referable DR (Grade 2+) specificity: %.1f%%\n', specificity * 100);
    fprintf('(PS target: >90%% sensitivity, >85%% specificity — this prototype\n');
    fprintf(' is demonstrating pipeline feasibility, not chasing that number yet)\n');
end

function kappa = computeQWK(trueLabels, predLabels, numClasses)
% Standard quadratic weighted kappa implementation
    O = confusionmat(trueLabels, predLabels, 'Order', 0:numClasses-1);
    N = sum(O, 'all');

    w = zeros(numClasses);
    for i = 1:numClasses
        for j = 1:numClasses
            w(i,j) = ((i-j)^2) / ((numClasses-1)^2);
        end
    end

    histTrue = sum(O, 2);
    histPred = sum(O, 1);
    E = (histTrue * histPred) / N;

    kappa = 1 - (sum(w .* O, 'all') / sum(w .* E, 'all'));
end
