function det = readYoloLabels(txtPath, imgW, imgH)
%READYOLOLABELS  Parse a YOLO-format detection/label file into pixel boxes.
%
%   det = readYoloLabels(txtPath, imgW, imgH) reads a standard YOLO label
%   file whose lines are:  <class> <cx> <cy> <w> <h>  (all normalised to
%   [0,1]) and returns a struct grouping the boxes by the four classes used
%   in this study.
%
%   Class map (see test/classes.txt):
%       0 = eary  -> EWA  (ear with awns)
%       1 = earn  -> EOA  (ear without awns / ear body)
%       2 = grain -> individual grains
%       3 = rect  -> RECT scale reference (10 x 100 mm)
%
%   Every box is returned in pixel coordinates as [x1 y1 x2 y2] (top-left,
%   bottom-right). EWA/EOA/RECT are single boxes (1x4, empty if missing);
%   grains is an Nx4 matrix.
%
%   This is the sole interface between the deep-learning (YOLO, Python)
%   stage and the morphological image-processing (MATLAB) stage of the
%   pipeline described in Section 2.3 of the manuscript.

    raw = [];
    if isfile(txtPath)
        raw = readmatrix(txtPath, 'FileType', 'text');
    end

    det = struct('EWA', [], 'EOA', [], 'RECT', [], 'grains', zeros(0,4));
    if isempty(raw)
        return;
    end

    % Convert every normalised (cx,cy,w,h) row to pixel [x1 y1 x2 y2].
    cls = raw(:,1);
    cx  = raw(:,2) * imgW;   cy = raw(:,3) * imgH;
    w   = raw(:,4) * imgW;   h  = raw(:,5) * imgH;
    boxes = [cx - w/2, cy - h/2, cx + w/2, cy + h/2];

    getFirst = @(c) firstBox(boxes(cls == c, :));
    det.EWA    = getFirst(0);
    det.EOA    = getFirst(1);
    det.RECT   = getFirst(3);
    det.grains = boxes(cls == 2, :);
end

function b = firstBox(m)
    if isempty(m)
        b = [];
    else
        b = m(1, :);   % one ear / one ruler per image
    end
end
