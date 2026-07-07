function s3 = stage3_scaleAwnGrain(s2, outDir)
%STAGE3_SCALEAWNGRAIN  Stage 3 - pixel scale, awn traits, grain detection.
%
%   s3 = stage3_scaleAwnGrain(s2, outDir) performs the three pixel-level
%   jobs of this stage on the crops produced in Stage 2:
%     1. RECT crop -> ASOP, the actual size of one pixel (mm/px)      [Eq.6]
%     2. EWA  crop -> awn traits AN, AL (DF/RA/ED) and awn area AS
%     3. EOA  crop -> pad to a SQUARE, then detect grains on the square with
%                     a YOLO model. Two square versions are made:
%                       * EOA-w (white pad)  -> model input for grain YOLO
%                       * EOA-b (black pad)  -> ear-body masking in Stage 4
%                     The grain label is written in the SQUARE frame.
%
%   Why square-pad: the single-grain detector is trained on square inputs;
%   padding (not resizing) keeps the pixel scale, so ASOP still applies and
%   the grain coordinates stay consistent with the Stage-4 ear-body mask
%   (which uses the same-size EOA-b square).
%
%   Returns struct s3:
%       asop, PN_rect
%       AN (.TQ/.ME/.MD/.value)  AL (.DF/.RA/.ED/.value)  AS (mm^2)
%       eoaWhitePath, eoaBlackPath  square crops (model input / mask input)
%       grainTxt                    grain label in the square frame
%       squareSize                  side length S of the square (pixels)
%
%   outDir defaults to the folder of the EOA crop.

    if nargin < 2 || isempty(outDir), outDir = fileparts(s2.eoaPath); end
    [~, base] = fileparts(s2.eoaPath);

    % ---- 1. scale from the RECT crop (Eq.6) ----------------------------
    rectImg = imread(s2.rectPath);
    [asop, PN_rect] = computeASOP(rectImg);
    s3.asop = asop;  s3.PN_rect = PN_rect;

    % ---- 2. awn traits from the EWA crop -------------------------------
    ewaImg = imread(s2.ewaPath);
    [BEWA, BEOA_ewa, BA] = preprocessSpike(ewaImg);
    s3.AN = measureAwnNumber(BEOA_ewa, BA);
    s3.AL = measureAwnLength(BEWA, BEOA_ewa, BA, s3.AN.value, asop);
    s3.AS = nnz(BA) * asop^2;

    % ---- 3a. pad the EOA crop to a square (white for YOLO, black for mask)
    eoaImg = imread(s2.eoaPath);
    eoaWhite = padToSquare(eoaImg, 255);
    eoaBlack = padToSquare(eoaImg, 0);
    S = size(eoaWhite, 1);
    s3.squareSize   = S;
    s3.eoaWhitePath = fullfile(outDir, [base '-w.jpg']);
    s3.eoaBlackPath = fullfile(outDir, [base '-b.jpg']);
    imwrite(eoaWhite, s3.eoaWhitePath);
    imwrite(eoaBlack, s3.eoaBlackPath);

    grainTxt = fullfile(outDir, [base '-w.txt']);

    % ---- 3b. grain detection on the white square -----------------------
    % ===================================================================
    % >>> BEGIN user-provided grain detection (Stage 3 model + params) <<<
    %
    %   Run your single-grain YOLO model on `eoaWhite` (the S x S image) and
    %   populate `grainBoxes` as N x 5, each row [class cx cy w h] normalised
    %   to the SQUARE size S. Class value is arbitrary (single class).
    %
    %       [bb, sc] = detect(<your grain model>, eoaWhite);   % bb pixels
    %       grainBoxes = <convert to normalised [class cx cy w h]>;
    %
    grainBoxes = zeros(0, 5);   % <-- replace with your grain detector output
    %
    % >>> END user-provided grain detection <<<
    % ===================================================================

    if isempty(grainBoxes) && isfile(grainTxt) && dirBytes(grainTxt) > 0
        fprintf('[Stage 3] grain detector empty; reusing existing %s\n', grainTxt);
    else
        writeYoloTxt(grainTxt, grainBoxes);
    end
    s3.grainTxt = grainTxt;

    ng = size(readmatrix(grainTxt, 'FileType', 'text'), 1);
    fprintf(['[Stage 3] ASOP=%.5f mm/px | AN(TQ)=%.1f AL(DF)=%.2fmm ' ...
             'AS=%.1fmm^2 | square=%dpx grains=%d\n'], asop, s3.AN.TQ, ...
             s3.AL.DF, s3.AS, S, ng);
end

% ------------------------------------------------------------------------
function writeYoloTxt(txtPath, boxes)
    fid = fopen(txtPath, 'w');
    assert(fid > 0, 'Cannot open %s for writing', txtPath);
    cleaner = onCleanup(@() fclose(fid));
    for i = 1:size(boxes, 1)
        fprintf(fid, '%d %.6f %.6f %.6f %.6f\n', round(boxes(i,1)), boxes(i,2:5));
    end
end

function n = dirBytes(p)
    info = dir(p);  n = info.bytes;
end
