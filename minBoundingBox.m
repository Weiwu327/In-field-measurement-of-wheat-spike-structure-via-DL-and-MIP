function [corners, L, W, angleDeg] = minBoundingBox(bw)
%MINBOUNDINGBOX  Minimum-area (rotated) bounding rectangle of a mask.
%
%   [corners, L, W, angleDeg] = minBoundingBox(bw) returns the minimum
%   bounding rectangle (MBR) of the foreground of BW using the rotating
%   calipers method on the convex hull.
%
%   corners  : 4x2 vertex coordinates [x y], ordered around the rectangle.
%   L, W     : the longer (length) and shorter (width) side, in pixels.
%   angleDeg : orientation of the LONG side w.r.t. the image x-axis, in
%              degrees, matching Eq.(8) of the manuscript. Rotating the crop
%              by (90 - angleDeg) makes the ear upright.

    [ys, xs] = find(bw);
    pts = [xs, ys];
    if size(pts, 1) < 3
        corners = []; L = 0; W = 0; angleDeg = 0; return;
    end

    k = convhull(pts(:,1), pts(:,2));
    hull = pts(k, :);                 % closed polygon, last == first

    bestArea = inf;
    corners  = [];
    L = 0; W = 0; angleDeg = 0;

    for i = 1:size(hull,1)-1
        edge = hull(i+1,:) - hull(i,:);
        theta = atan2(edge(2), edge(1));      % align this edge with x-axis
        Rmat  = [cos(-theta) -sin(-theta); sin(-theta) cos(-theta)];
        rot   = (Rmat * hull')';

        minx = min(rot(:,1)); maxx = max(rot(:,1));
        miny = min(rot(:,2)); maxy = max(rot(:,2));
        area = (maxx-minx) * (maxy-miny);

        if area < bestArea
            bestArea = area;
            % rectangle corners in rotated frame, mapped back.
            c = [minx miny; maxx miny; maxx maxy; minx maxy];
            corners = (Rmat \ c')';           % inverse rotation
            side1 = maxx - minx;              % along the edge
            side2 = maxy - miny;
            if side1 >= side2
                L = side1; W = side2; longDir = theta;
            else
                L = side2; W = side1; longDir = theta + pi/2;
            end
            angleDeg = mod(rad2deg(longDir), 180);
        end
    end
end
