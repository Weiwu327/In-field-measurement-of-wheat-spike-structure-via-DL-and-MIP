function s4 = stage4_remainingTraits(s3)
%STAGE4_REMAININGTRAITS  Stage 4 - all remaining traits in the square frame.
%
%   s4 = stage4_remainingTraits(s3) measures every trait that depends on the
%   (square-padded) EOA image and/or the grain label from Stage 3. The
%   ear-body mask is taken from the BLACK-padded square (EOA-b) and the
%   grains from the grain label, both in the SAME S x S frame, so grain
%   positions, the ear MBR/angle, and the distributions are all consistent.
%
%       ES        ear area                          (EOA-b mask) [mm^2]
%       EL_MBR    ear length, min-bounding-rect      (EOA-b mask) [mm]
%       EW_MBR    ear width,  min-bounding-rect      (EOA-b mask) [mm]
%       GN        grain number                       (grain txt)
%       SPN       spikelet number (PD/QD fusion)     (grain txt)
%       SPGN      spikelet grain number = GN/SPN
%       GD        grain distribution                 [mm]
%       SPD       spikelet distribution              [mm]
%       SPGD      spikelet grain distribution        [mm]

    asop   = s3.asop;
    eoaImg = imread(s3.eoaBlackPath);        % black-padded square
    S      = size(eoaImg, 1);

    % --- ear-body mask (ear on black background) -> MBR + area ----------
    BEOA = earBodyMask(eoaImg);
    [~, Lpx, Wpx, angleDeg] = minBoundingBox(BEOA);
    s4.EL_MBR = Lpx * asop;
    s4.EW_MBR = Wpx * asop;
    s4.ES     = nnz(BEOA) * asop^2;

    % --- grains (same S x S frame) -> GN, SPN ---------------------------
    grainBoxes = readGrainLabel(s3.grainTxt, S, S);
    spk = measureSpikeletNumber(grainBoxes, angleDeg);
    s4.GN  = spk.GN;
    s4.SPN = spk.SPN;

    % --- distribution traits --------------------------------------------
    d = measureDistributionTraits(spk, asop);
    s4.SPGN = d.SPGN;  s4.GD = d.GD;  s4.SPD = d.SPD;  s4.SPGD = d.SPGD;

    s4.spk = spk;  s4.BEOA = BEOA;  s4.angleDeg = angleDeg;

    fprintf(['[Stage 4] EL(MBR)=%.2fmm EW(MBR)=%.2fmm ES=%.1fmm^2 | ' ...
             'GN=%d SPN=%d SPGN=%.2f\n'], s4.EL_MBR, s4.EW_MBR, s4.ES, ...
             s4.GN, s4.SPN, s4.SPGN);
end

% ------------------------------------------------------------------------
function BEOA = earBodyMask(eoaSquare)
%EARBODYMASK  Ear-body mask from the black-padded EOA square.
%   The ear sits on a black background, so a simple luminance threshold is
%   robust; ExB is used as a fallback.
    g  = im2uint8(rgb2grayIfNeeded(eoaSquare));
    bw = imbinarize(g);                       % ear (bright) vs black pad
    bw = imfill(bw, 'holes');
    bw = bwareaopen(bw, 50);
    if any(bw(:))
        bw = bwareafilt(bw, 1);
    else
        [~, bw] = preprocessSpike(eoaSquare);  % fallback
    end
    BEOA = bw;
end

function g = rgb2grayIfNeeded(im)
    if size(im,3) == 3, g = rgb2gray(im); else, g = im; end
end
