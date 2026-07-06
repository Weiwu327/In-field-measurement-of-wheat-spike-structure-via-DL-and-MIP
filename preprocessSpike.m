function [BEWA, BEOA, BA, ExBimg] = preprocessSpike(ewaROI)
%PREPROCESSSPIKE  Colour-index preprocessing of the ear-with-awns crop.
%
%   [BEWA, BEOA, BA, ExBimg] = preprocessSpike(ewaROI) implements the image
%   preprocessing of Section 2.5.2(1) and the awn extraction of 2.5.2(2).
%
%   Steps:
%     1. Excess-Blue colour index (Eq.7):  ExB = 1.4*b - g   on normalised
%        r,g,b channels. Wheat spike (yellow/brown) contrasts strongly with
%        the blue-ish cardboard background, so ExB isolates the whole spike
%        (ear body + awns).
%     2. Local adaptive thresholding of the ExB grayscale + binarisation
%        -> BEWA (Fig.2d), the complete spike (ear body + awns).
%     3. Opening (removes the thin awns) -> BEOA (Fig.2e), the ear body.
%     4. BA = BEWA - BEOA, then denoise -> the awns only (Fig.2f).
%
%   Outputs are logical masks the size of the EWA crop.

    rgb = im2double(ewaROI);
    R = rgb(:,:,1);  G = rgb(:,:,2);  B = rgb(:,:,3);

    % --- Eq.(7): normalised channels then Excess-Blue -------------------
    s = R + G + B + eps;
    r = R ./ s;   g = G ./ s;   b = B ./ s;
    ExBimg = 1.4 * b - g;                       % excess blue
    ExBimg = mat2gray(ExBimg);                  % scale to [0,1] for display

    % Spike is *low* ExB (not blue) against the *high* ExB background.
    % Work on the complementary index so the spike becomes the bright object.
    spikeIdx = 1 - ExBimg;

    % --- local adaptive threshold + binarisation -> BEWA ----------------
    T    = adaptthresh(spikeIdx, 0.45, 'NeighborhoodSize', ...
                       2*floor(size(spikeIdx)/16)+1);
    BEWA = imbinarize(spikeIdx, T);
    BEWA = imfill(BEWA, 'holes');
    BEWA = bwareaopen(BEWA, 30);                % drop specks
    BEWA = keepLargest(BEWA);                   % keep the spike blob

    % --- opening removes the thin awns -> ear body BEOA -----------------
    % Awn width is a few pixels; the opening radius is scaled to the crop.
    rOpen = max(3, round(0.02 * size(BEWA, 2)));
    BEOA  = imopen(BEWA, strel('disk', rOpen));
    BEOA  = keepLargest(BEOA);

    % --- awns = spike minus ear body, denoised --------------------------
    BA = BEWA & ~BEOA;
    BA = bwareaopen(BA, 10);
end

function bw = keepLargest(bw)
%KEEPLARGEST  Largest connected component, or the input if it is empty.
    if any(bw(:))
        bw = bwareafilt(bw, 1);
    end
end
