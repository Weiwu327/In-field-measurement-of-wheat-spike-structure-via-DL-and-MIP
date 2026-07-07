function [sq, off] = padToSquare(img, padVal)
%PADTOSQUARE  Centre-pad an image to a square (side = max(H,W)).
%
%   [sq, off] = padToSquare(img, padVal) pads IMG with the constant value
%   padVal (0 = black, 255 = white) so the result is square, with the
%   original content CENTRED (matching the EOA-w / EOA-b square crops used
%   for grain detection). off = [xoff yoff] is the top-left pixel offset of
%   the original content inside the square (0-based), in case you need to
%   map coordinates back to the un-padded crop.

    [H, W, C] = size(img);
    S = max(H, W);
    if nargin < 2, padVal = 0; end

    sq = uint8(padVal) + zeros(S, S, C, 'uint8');
    xoff = floor((S - W) / 2);
    yoff = floor((S - H) / 2);
    sq(yoff+(1:H), xoff+(1:W), :) = img;
    off = [xoff, yoff];
end
