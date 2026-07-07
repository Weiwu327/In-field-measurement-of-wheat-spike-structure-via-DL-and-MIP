function new = fillsmallholes(bw, threshold)
%FILLSMALLHOLES  Fill only holes smaller than THRESHOLD pixels.
%   Holes (background regions enclosed by foreground) with area < threshold
%   are filled; larger holes are left open. Ported from the original code.

    filled     = imfill(bw, 'holes');
    holes      = filled & ~bw;
    bigholes   = bwareaopen(holes, threshold);
    smallholes = holes & ~bigholes;
    new        = bw | smallholes;
end
