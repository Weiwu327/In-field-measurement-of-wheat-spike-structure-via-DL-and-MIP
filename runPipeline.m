function [T, S] = runPipeline(imgPath, workDir)
%RUNPIPELINE  Full 4-stage wheat-spike trait measurement for one image.
%
%   [T, S] = runPipeline(imgPath) runs the four stages in order and returns
%   a 1-row table T of all 12 traits (plus the alternative methods) and a
%   struct S holding every stage's outputs.
%
%   Stage 1  stage1_detect          original image -> RECT/EOA/EWA txt   [YOLO]
%   Stage 2  stage2_earSizeAndCrop  txt -> ear size (DL, px) + 3 crops
%   Stage 3  stage3_scaleAwnGrain   crops -> ASOP, awn traits, grain txt  [YOLO]
%   Stage 4  stage4_remainingTraits EOA crop + grain txt -> all remaining
%
%   NOTE: Stages 1 and 3 contain user-provided YOLO detection blocks. Until
%   you fill those in, runPipeline will stop at the empty-detector assert.
%   You can also run any stage standalone (e.g. feed a hand-made txt to
%   Stage 2) - see demo_pipeline.m.
%
%   workDir is where crops / label txts are written (default:
%   '<image_dir>/<image_name>_rois').

    [imgDir, base] = fileparts(imgPath);
    if nargin < 2 || isempty(workDir)
        workDir = fullfile(imgDir, [base '_rois']);
    end
    if ~exist(workDir, 'dir'), mkdir(workDir); end

    detTxt = fullfile(workDir, [base '.txt']);

    % ---- run the four stages -------------------------------------------
    S.detTxt = stage1_detect(imgPath, detTxt);
    S.s2 = stage2_earSizeAndCrop(imgPath, S.detTxt, workDir);
    S.s3 = stage3_scaleAwnGrain(S.s2, workDir);
    S.s4 = stage4_remainingTraits(S.s3);

    T = assembleTable(base, S);
end

% ------------------------------------------------------------------------
function T = assembleTable(name, S)
%ASSEMBLETABLE  Merge the four stages into one trait row (mm units).
    s2 = S.s2;  s3 = S.s3;  s4 = S.s4;
    asop = s3.asop;

    T = table();
    T.name    = string(name);
    T.ASOP    = asop;              T.PN_rect = s3.PN_rect;
    % awn (Stage 3)
    T.AN_TQ   = s3.AN.TQ;          T.AN_ME = s3.AN.ME;   T.AN_MD = s3.AN.MD;
    T.AL_DF   = s3.AL.DF;          T.AL_RA = s3.AL.RA;   T.AL_ED = s3.AL.ED;
    T.AS      = s3.AS;
    % ear size: DL from Stage 2 (px -> mm here), MBR from Stage 4
    T.EL_DL   = s2.EL_DL_px * asop; T.EL_MBR = s4.EL_MBR;
    T.EW_DL   = s2.EW_DL_px * asop; T.EW_MBR = s4.EW_MBR;
    T.ES      = s4.ES;
    % grain / spikelet (Stage 4)
    T.GN      = s4.GN;             T.SPN  = s4.SPN;    T.SPGN = s4.SPGN;
    T.GD      = s4.GD;             T.SPD  = s4.SPD;    T.SPGD = s4.SPGD;
end
