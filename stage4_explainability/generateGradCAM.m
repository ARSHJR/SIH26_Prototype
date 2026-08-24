function [heatmap, overlayImg] = generateGradCAM(net, img, predictedClass)
% GENERATEGRADCAM  Grad-CAM attention overlay for a single prediction.
%
% Verified working against the actual trained network (a DAGNetwork from
% trainNetwork/squeezenet, see stage3_classifier/trainDRClassifier.m) on
% this MATLAB R2026a install: gradCAM() runs directly on a DAGNetwork, no
% conversion to dlnetwork needed.

    % squeezenet's last feature map before global pooling is 'relu_conv10'
    % (confirmed via net.Layers on the actual trained network — squeezenet
    % has no 'activation_49_relu', that was a resnet50 layer name and this
    % network isn't resnet50). gradCAM also auto-selects this same layer by
    % default, but it's named explicitly here for clarity.
    scoreMap = gradCAM(net, img, predictedClass, 'FeatureLayer', 'relu_conv10');

    heatmap = mat2gray(scoreMap);

    % --- Overlay heatmap on original image ---
    heatmapResized = imresize(heatmap, [size(img,1) size(img,2)]);
    overlayImg = labeloverlay(img, heatmapResized > 0.5, 'Colormap', 'autumn', 'Transparency', 0.5);
end
