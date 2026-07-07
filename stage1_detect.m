function detTxt = stage1_detect(imgPath, detTxt)
%STAGE1_DETECT  Stage 1 - detect RECT / EOA / EWA on the original image.
%
%   detTxt = stage1_detect(imgPath, detTxt) runs the first-stage YOLO
%   detector on the full field image and writes the detection result as a
%   YOLO-format label file (one line per box: <class> <cx> <cy> <w> <h>,
%   normalised). Returns the path to that txt file.
%
%   Class convention (project classes.txt): 0=eary(EWA), 1=earn(EOA),
%   3=rect. (Grains are NOT detected here; that happens in Stage 3 on the
%   EOA crop.)
%
%   >>> YOU PROVIDE THE MODEL <<<
%   The detection itself (model file, weights, thresholds, inference call)
%   is supplied by you. Fill in the marked block below so that `boxes` ends
%   up as an N-by-5 matrix, each row [class cx cy w h] with cx,cy,w,h
%   normalised to [0,1]. Everything around it (I/O, txt writing) is done.
%
%   If detTxt is omitted, it defaults to <image>.txt next to the image.

    if nargin < 2 || isempty(detTxt)
        [p, b] = fileparts(imgPath);
        detTxt = fullfile(p, [b '.txt']);
    end

    img = imread(imgPath);                 %#ok<NASGU>  (available to detector)
    [H, W, ~] = size(img);                 %#ok<ASGLU>

    % ===================================================================
    % >>> BEGIN user-provided detection (Stage 1 model + parameters) <<<
    %
    %   Run your YOLO-series model on `img` and populate `boxes`:
    %       boxes = [class cx cy w h];      % N x 5, values normalised [0,1]
    %       classes: 0=eary(EWA), 1=earn(EOA), 3=rect
    %
    %   Example skeleton (pseudo-code):
    %       net    = <load your model once, e.g. importNetwork / a detector>;
    %       [bb, sc, lbl] = detect(net, img);       % bb = [x y w h] pixels
    %       boxes  = <convert bb+lbl to normalised [class cx cy w h]>;
    %
    boxes = zeros(0, 5);   % <-- replace with your detector output
    %
    % >>> END user-provided detection <<<
    % ===================================================================

    if isempty(boxes)
        % Detector not wired in: reuse an existing label file if present
        % (lets you validate later stages with a hand-made / converted txt).
        assert(isfile(detTxt) && dirBytes(detTxt) > 0, ['stage1_detect: ' ...
            '`boxes` is empty and no existing %s to reuse. Wire in your ' ...
            'YOLO detector in the marked block.'], detTxt);
        fprintf('[Stage 1] detector empty; reusing existing %s\n', detTxt);
        return;
    end

    writeYoloTxt(detTxt, boxes);
    fprintf('[Stage 1] %s -> %s (%d boxes)\n', imgPath, detTxt, size(boxes,1));
end

% ------------------------------------------------------------------------
function writeYoloTxt(txtPath, boxes)
%WRITEYOLOTXT  Write an N-by-5 [class cx cy w h] matrix as a YOLO label file.
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
