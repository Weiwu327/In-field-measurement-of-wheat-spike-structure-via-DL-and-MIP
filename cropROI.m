function [roi, box] = cropROI(img, box)
%CROPROI  Crop an image region given a [x1 y1 x2 y2] pixel box.
%
%   [roi, box] = cropROI(img, box) returns the cropped sub-image and the
%   integer-clamped box actually used. Empty box -> empty roi.

    roi = [];
    if isempty(box)
        return;
    end

    [H, W, ~] = size(img);
    x1 = max(1, floor(box(1)));  y1 = max(1, floor(box(2)));
    x2 = min(W, ceil(box(3)));   y2 = min(H, ceil(box(4)));
    box = [x1 y1 x2 y2];
    roi = img(y1:y2, x1:x2, :);
end
