function enhanced = enhanceImage(img)
% ENHANCEIMAGE  Adaptive enhancement for borderline fundus images.
% Applies CLAHE on the green channel (best lesion contrast in fundus photography),
% illumination normalization, and light denoising.

    img = im2double(img);

    if size(img, 3) == 3
        green = img(:,:,2);   % green channel shows DR lesions best
    else
        green = img;
    end

    % --- CLAHE ---
    greenCLAHE = adapthisteq(green, 'ClipLimit', 0.01, 'Distribution', 'rayleigh');

    % --- Illumination normalization: subtract a heavily blurred version
    % (approximates uneven background lighting) ---
    background = imgaussfilt(greenCLAHE, 30);
    normalized = greenCLAHE - background + mean(background, 'all');
    normalized = mat2gray(normalized);

    % --- Light denoising ---
    denoised = imgaussfilt(normalized, 0.5);

    if size(img, 3) == 3
        enhanced = img;
        enhanced(:,:,2) = denoised;
    else
        enhanced = denoised;
    end
end
