function s2 = stage2_earSizeAndCrop(imgPath, detTxt, cropDir)
%STAGE2_EARSIZEANDCROP  Stage 2 - preliminary ear size + crop the ROIs.
%
%   s2 = stage2_earSizeAndCrop(imgPath, detTxt, cropDir) uses the Stage-1
%   detection boxes to (a) compute the preliminary EAR SIZE by the detection
%   -box (DL) method, and (b) crop the RECT, EWA and EOA subimages for the
%   later stages. NO other trait or method is computed here (by design):
%   ear length/width are the only quantities derivable directly from the
%   boxes, and the DL method needs nothing but the box dimensions.
%
%   Because the pixel->mm scale (ASOP) is only known after Stage 3, ear size
%   is returned here in PIXELS; the millimetre value is finalised later
%   (EL_DL_mm = EL_DL_px * ASOP).
%
%   Returns struct s2:
%       EL_DL_px, EW_DL_px  ear length/width from the EOA box, in pixels
%       eoaBox              [x1 y1 x2 y2] EOA box (pixels)
%       rectPath, ewaPath, eoaPath   paths to the three saved crops
%       imgW, imgH          original image size
%
%   cropDir defaults to '<image_dir>/<image_name>_rois'.

    img = imread(imgPath);
    [H, W, ~] = size(img);
    det = readYoloLabels(detTxt, W, H);

    assert(~isempty(det.RECT), '[Stage 2] No RECT box in %s', detTxt);
    assert(~isempty(det.EWA),  '[Stage 2] No EWA (eary) box in %s', detTxt);
    assert(~isempty(det.EOA),  '[Stage 2] No EOA (earn) box in %s', detTxt);

    [~, base] = fileparts(imgPath);
    if nargin < 3 || isempty(cropDir)
        cropDir = fullfile(fileparts(imgPath), [base '_rois']);
    end
    if ~exist(cropDir, 'dir'), mkdir(cropDir); end

    % --- crop and save the three ROIs -----------------------------------
    s2.eoaBox   = det.EOA;
    s2.rectPath = fullfile(cropDir, [base '_RECT.jpg']);
    s2.ewaPath  = fullfile(cropDir, [base '_EWA.jpg']);
    s2.eoaPath  = fullfile(cropDir, [base '_EOA.jpg']);
    eoaCrop = cropROI(img, det.EOA);
    imwrite(cropROI(img, det.RECT), s2.rectPath);
    imwrite(cropROI(img, det.EWA),  s2.ewaPath);
    imwrite(eoaCrop, s2.eoaPath);

    % --- preliminary ear size: detection-box (DL) method, in pixels -----
    % Taken from the EOA CROP dimensions (height = ear length, width = ear
    % width) so it stays at the same pixel scale as ASOP (both full-res
    % crops); ears are imaged upright.
    s2.EL_DL_px = size(eoaCrop, 1);
    s2.EW_DL_px = size(eoaCrop, 2);

    s2.imgW = W;  s2.imgH = H;

    fprintf('[Stage 2] ear size (px): EL=%.1f EW=%.1f | crops -> %s\n', ...
            s2.EL_DL_px, s2.EW_DL_px, cropDir);
end
