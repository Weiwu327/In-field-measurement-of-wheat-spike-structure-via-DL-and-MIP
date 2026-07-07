function [asop, PN_rect, bwRect] = computeASOP(rectROI)
%COMPUTEASOP  Actual Size Of One Pixel from the RECT scale reference.
%
%   [asop, PN_rect, bwRect] = computeASOP(rectROI) implements Section 2.5.1
%   and Eq.(6) of the manuscript. The rectangular ruler on the background
%   board is 10 x 100 mm, i.e. an actual area of 1000 mm^2.
%
%   Processing chain (Fig. A5):
%       (a) RECT crop (from YOLO)
%       (b) local adaptive threshold
%       (c) binarisation
%       (d) closing operation
%       (e) filling operation
%   PN_rect is then the number of white (==1) pixels in the filled binary
%   image.
%
%   Eq.(6):  ASOP = sqrt( S_real / PN_rect )      [mm per pixel]
%   with S_real = 1000 mm^2. Returning the side length of one pixel lets us
%   convert lengths with a single factor (px * ASOP) and areas with ASOP^2
%   (px * ASOP^2 -> mm^2).

    S_real = 1000;   % mm^2, RECT = 10 x 100 mm

    g = toGray(rectROI);

    % (b) local adaptive threshold + (c) binarisation.
    T  = adaptthresh(g, 0.5, 'ForegroundPolarity', 'dark', ...
                     'NeighborhoodSize', 2*floor(size(g)/16)+1);
    bw = imbinarize(g, T);
    % RECT is the dark ruler on a light board -> foreground is the dark part.
    if mean(bw(:)) > 0.5
        bw = ~bw;
    end

    % (d) closing then (e) filling to obtain a solid rectangle.
    bw = imclose(bw, strel('disk', 5));
    bw = imfill(bw, 'holes');

    % Keep only the largest connected component (the ruler itself).
    bw = bwareafilt(bw, 1);

    PN_rect = nnz(bw);
    asop    = sqrt(S_real / max(PN_rect, 1));
    bwRect  = bw;
end

function g = toGray(im)
    if size(im, 3) == 3
        g = rgb2gray(im);
    else
        g = im;
    end
    if ~isa(g, 'uint8')
        g = im2uint8(g);
    end
end
