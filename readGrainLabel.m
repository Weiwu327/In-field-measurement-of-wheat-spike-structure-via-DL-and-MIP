function boxes = readGrainLabel(txtPath, imgW, imgH)
%READGRAINLABEL  Read a YOLO grain label (class-agnostic) into pixel boxes.
%
%   boxes = readGrainLabel(txtPath, imgW, imgH) reads the second-stage grain
%   detection label produced by YOLO26n on the EOA crop. Every row is
%   treated as a grain regardless of its class index (the single-grain model
%   only has one class), and is returned as [x1 y1 x2 y2] in the pixel frame
%   of the EOA crop (imgW x imgH).

    boxes = zeros(0,4);
    if ~isfile(txtPath)
        return;
    end
    raw = readmatrix(txtPath, 'FileType', 'text');
    if isempty(raw)
        return;
    end
    if size(raw,2) >= 5
        cx = raw(:,2)*imgW;  cy = raw(:,3)*imgH;
        w  = raw(:,4)*imgW;  h  = raw(:,5)*imgH;
    else                      % tolerate files without a leading class column
        cx = raw(:,1)*imgW;  cy = raw(:,2)*imgH;
        w  = raw(:,3)*imgW;  h  = raw(:,4)*imgH;
    end
    boxes = [cx - w/2, cy - h/2, cx + w/2, cy + h/2];
end
