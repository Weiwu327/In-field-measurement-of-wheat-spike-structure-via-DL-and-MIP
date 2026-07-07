function [BEWA, BEOA, BA, ExBimg] = preprocessSpike(ewaROI)
%PREPROCESSSPIKE  Excess-Blue preprocessing of the ear-with-awns crop.
%
%   [BEWA, BEOA, BA, ExBimg] = preprocessSpike(ewaROI) reproduces the awn
%   extraction of the original code (extract_awn.m) and Section 2.5.2:
%
%     1. Excess-Blue index on the RAW double channels (Eq.7):
%           ExB = 2.7*B - R - G
%        The wheat spike (yellow/brown) is much less blue than the bluish
%        cardboard, so it appears DARK in ExB.
%     2. Local adaptive threshold with dark foreground polarity, then
%        binarise and INVERT to obtain the whole spike:
%           T     = adaptthresh(ExB, 0.4, 'ForegroundPolarity','dark',
%                               'Statistic','mean');
%           spike = ~imbinarize(ExB, T);
%     3. Remove small regions (area < 200) and fill small holes (< 100)
%        -> BEWA (complete spike: ear body + awns).
%     4. Opening with a disk removes the thin awns -> BEOA (ear body).
%     5. BA = BEWA - BEOA -> the awns only.
%
%   The opening disk radius is calibrated to the crop width (15 px at the
%   ~1043 px reference width the method was tuned on).

    rgb = im2double(ewaROI);
    R = rgb(:,:,1);  G = rgb(:,:,2);  B = rgb(:,:,3);

    % --- Eq.(7): Excess-Blue on raw channels ----------------------------
    ExBimg = 2.7*B - R - G;

    % --- adaptive threshold (dark foreground) + invert -> spike ---------
    T   = adaptthresh(ExBimg, 0.4, 'ForegroundPolarity', 'dark', ...
                      'Statistic', 'mean');
    BW  = imbinarize(ExBimg, T);
    spike = ~BW;

    % --- clean: drop small blobs, fill small holes ----------------------
    spike = bwareaopen(spike, 200);
    spike = fillsmallholes(spike, 100);
    BEWA  = spike;

    % --- opening removes the thin awns -> ear body BEOA -----------------
    rOpen = max(8, round(15/1043 * size(BEWA, 2)));   % 15 px @ 1043 px wide
    BEOA  = imopen(BEWA, strel('disk', rOpen));

    % --- awns = spike minus ear body ------------------------------------
    BA = BEWA & ~BEOA;
    BA = bwareaopen(BA, 20);
end
