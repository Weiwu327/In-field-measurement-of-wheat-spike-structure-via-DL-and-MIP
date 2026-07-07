% demo_pipeline.m
% ===========================================================================
% Complete 4-stage demo on the bundled ./data folder.
%
% The data/ folder contains one spike's worth of files, mapped to the stages:
%   Stage 1 (input+output) : 'original image.jpg' + 'original image.txt'
%                            (full image + YOLO RECT/EOA/EWA detection)
%   Stage 2 (crops)        : RECT.jpg, EWA.jpg, EOA.jpg
%   Stage 3 (grain model)  : EOA-w.jpg (square, white pad) is the grain-YOLO
%                            input; EOA-w.txt is its output. EOA-b.jpg
%                            (square, black pad) is used for the ear mask.
%
% Because the provided crops are full resolution while 'original image.jpg'
% is a low-res preview, this demo consumes the PROVIDED intermediate files
% directly (it does not re-crop). Each block is labelled with its stage.
% ===========================================================================

here    = fileparts(mfilename('fullpath'));
addpath(here);
dataDir = fullfile(here, 'data');

% ---- Stage 1 : original image + detection (given) -------------------------
origImg = fullfile(dataDir, 'original image.jpg');
detTxt  = fullfile(dataDir, 'original image.txt');
ii = imfinfo(origImg);
fprintf('[Stage 1] %s (%dx%d)  detection: %s\n', 'original image.jpg', ...
        ii.Width, ii.Height, 'original image.txt');

% ---- Stage 2 : ear size (DL) from the provided EOA crop -------------------
rectImg = imread(fullfile(dataDir, 'RECT.jpg'));
ewaImg  = imread(fullfile(dataDir, 'EWA.jpg'));
eoaImg  = imread(fullfile(dataDir, 'EOA.jpg'));
EL_DL_px = size(eoaImg, 1);      % crop height = ear length
EW_DL_px = size(eoaImg, 2);      % crop width  = ear width
fprintf('[Stage 2] ear size (px): EL=%d EW=%d\n', EL_DL_px, EW_DL_px);

% ---- Stage 3 : ASOP + awn traits; grain detection output (given) ---------
[asop, PN_rect] = computeASOP(rectImg);
[BEWA, BEOA_ewa, BA] = preprocessSpike(ewaImg);
AN = measureAwnNumber(BEOA_ewa, BA);
AL = measureAwnLength(BEWA, BEOA_ewa, BA, AN.value, asop);
AS = nnz(BA) * asop^2;
fprintf(['[Stage 3] ASOP=%.5f mm/px | AN(TQ)=%.1f AL(DF)=%.2fmm ' ...
         'AS=%.1fmm^2\n'], asop, AN.TQ, AL.DF, AS);

% Package Stage-3 outputs the way Stage 4 expects them. The grain label and
% the black square are the model I/O provided in data/.
s3 = struct();
s3.asop = asop;  s3.PN_rect = PN_rect;  s3.AN = AN;  s3.AL = AL;  s3.AS = AS;
s3.eoaBlackPath = fullfile(dataDir, 'EOA-b.jpg');   % ear mask input
s3.grainTxt     = fullfile(dataDir, 'EOA-w.txt');   % grain YOLO output

% ---- Stage 4 : remaining traits (square frame) ---------------------------
s4 = stage4_remainingTraits(s3);

% ---- assemble the full trait row -----------------------------------------
T = table();
T.name  = "demo";
T.ASOP  = asop;                 T.PN_rect = PN_rect;
T.AN_TQ = AN.TQ; T.AN_ME = AN.ME; T.AN_MD = AN.MD;
T.AL_DF = AL.DF; T.AL_RA = AL.RA; T.AL_ED = AL.ED;
T.AS    = AS;
T.EL_DL = EL_DL_px * asop;      T.EL_MBR = s4.EL_MBR;
T.EW_DL = EW_DL_px * asop;      T.EW_MBR = s4.EW_MBR;
T.ES    = s4.ES;
T.GN    = s4.GN;  T.SPN = s4.SPN;  T.SPGN = s4.SPGN;
T.GD    = s4.GD;  T.SPD = s4.SPD;  T.SPGD = s4.SPGD;

disp('===== 12 wheat-spike traits =====');
disp(T);

% ---- verification figure --------------------------------------------------
figure('Name', 'demo_pipeline', 'Color', 'w');
tiledlayout(1, 4, 'Padding', 'compact', 'TileSpacing', 'compact');
nexttile; imshow(rectImg);  title(sprintf('RECT  ASOP=%.4f', asop));
nexttile; imshow(BA);       title(sprintf('Awns  AN=%.0f', AN.TQ));
nexttile; imshow(s4.BEOA);  title(sprintf('Ear mask  EL=%.1f EW=%.1f mm', s4.EL_MBR, s4.EW_MBR));
nexttile; imshow(imread(s3.eoaBlackPath)); hold on;   % grains by spikelet
sq  = size(imread(s3.eoaBlackPath), 1);
gbx = readGrainLabel(s3.grainTxt, sq, sq);
lab = s4.spk.label;  cmap = lines(max(s4.spk.SPN,1));
for i = 1:size(gbx,1)
    r = [gbx(i,1) gbx(i,2) gbx(i,3)-gbx(i,1) gbx(i,4)-gbx(i,2)];
    rectangle('Position', r, 'EdgeColor', cmap(lab(i),:), 'LineWidth', 1.5);
end
title(sprintf('Grains GN=%d  SPN=%d', s4.GN, s4.SPN)); hold off;
