function T = measureSpikeTraits(imgPath, labelPath)
%MEASURESPIKETRAITS  Measure the 12 wheat-spike traits from one image.
%
%   T = measureSpikeTraits(imgPath, labelPath) runs the full morphological
%   image-processing stage (Section 2.5) on a single field image, using the
%   YOLO detection results in labelPath (standard YOLO txt:
%   <class> <cx> <cy> <w> <h>, classes 0=eary/EWA, 1=earn/EOA, 2=grain,
%   3=rect). Returns a 1-row table with every trait.
%
%   Pipeline:
%     1. computeASOP        - pixel -> mm scale from the RECT ruler.
%     2. preprocessSpike    - ExB masks: BEWA (spike), BEOA (ear), BA (awns).
%     3. measureAwnNumber   - AN via convex-hull/skeleton intersections.
%     4. measureAwnLength   - AL by DF / RA / ED.
%     5. measureEarSize     - EL, EW by DL box and MBR.
%     6. measureSpikeletNumber - GN, SPN by PD/QD grouping fusion.
%     7. measureOtherTraits - AS, ES, GD, SPD, SPGN, SPGD.
%
%   Example:
%     T = measureSpikeTraits('test/xxx.jpg', 'labels/xxx.txt');

    img = imread(imgPath);
    [H, W, ~] = size(img);
    det = readYoloLabels(labelPath, W, H);

    assert(~isempty(det.RECT), 'No RECT box in %s', labelPath);
    assert(~isempty(det.EWA),  'No EWA (eary) box in %s', labelPath);
    assert(~isempty(det.EOA),  'No EOA (earn) box in %s', labelPath);

    % 1. scale ------------------------------------------------------------
    rectROI = cropROI(img, det.RECT);
    [asop, PN_rect] = computeASOP(rectROI);

    % 2. spike preprocessing on the EWA crop ------------------------------
    ewaROI = cropROI(img, det.EWA);
    [BEWA, BEOA, BA] = preprocessSpike(ewaROI);

    % 3-4. awn traits -----------------------------------------------------
    AN = measureAwnNumber(BEOA, BA);
    AL = measureAwnLength(BEWA, BEOA, BA, AN.value, asop);

    % 5. ear size (BEOA extracted again inside the EOA crop frame) --------
    eoaROI = cropROI(img, det.EOA);
    BEOAcrop = earBodyMask(eoaROI);
    [EL, EW, mbr] = measureEarSize(det.EOA, BEOAcrop, asop);

    % 6. grain / spikelet number -----------------------------------------
    grainsInEOA = shiftBoxes(det.grains, det.EOA);   % into EOA-crop frame
    spk = measureSpikeletNumber(grainsInEOA, mbr.angleDeg);

    % 7. other traits -----------------------------------------------------
    other = measureOtherTraits(BA, BEOA, spk, asop);

    % ---- assemble output row -------------------------------------------
    T = table();
    T.image   = string(imgPath);
    T.ASOP    = asop;        T.PN_rect = PN_rect;
    T.AN_TQ   = AN.TQ;       T.AN_ME = AN.ME;   T.AN_MD = AN.MD;
    T.AL_DF   = AL.DF;       T.AL_RA = AL.RA;   T.AL_ED = AL.ED;
    T.EL_MBR  = EL.MBR;      T.EL_DL = EL.DL;
    T.EW_MBR  = EW.MBR;      T.EW_DL = EW.DL;
    T.GN      = spk.GN;      T.SPN   = spk.SPN;
    T.AS      = other.AS;    T.ES    = other.ES;
    T.SPGN    = other.SPGN;  T.GD    = other.GD;
    T.SPD     = other.SPD;   T.SPGD  = other.SPGD;
end

% ------------------------------------------------------------------------
function BEOA = earBodyMask(eoaROI)
%EARBODYMASK  Ear-body binary mask inside the EOA crop, via ExB (Eq.7).
    [~, BEOA] = preprocessSpike(eoaROI);      % opening removes stray awns
    if ~any(BEOA(:))
        % Fallback: whole-crop foreground if the ExB mask came back empty.
        g = rgb2gray(im2uint8(eoaROI));
        BEOA = imfill(imbinarize(g), 'holes');
        BEOA = bwareafilt(BEOA, 1);
    end
end

function b = shiftBoxes(boxes, refBox)
%SHIFTBOXES  Translate full-image boxes into a crop's local frame.
    if isempty(boxes), b = zeros(0,4); return; end
    dx = refBox(1); dy = refBox(2);
    b = boxes - [dx dy dx dy];
end
