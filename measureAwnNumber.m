function [AN, counts, sortedCounts] = measureAwnNumber(BEOA, BA)
%MEASUREAWNNUMBER  Awn number by convex-hull / skeleton intersections.
%
%   [AN, counts, sortedCounts] = measureAwnNumber(BEOA, BA) implements
%   Section 2.5.2(2) and Table A3 (AN).
%
%   Idea (Fig.2g-k): the awn skeleton (SKBA) radiates outward from the ear
%   body. The convex hull of the ear body (CBEOA) is progressively dilated;
%   at each dilation step the number of points where the hull boundary
%   crosses the awn skeleton estimates the awn number. Because the count
%   depends on the dilation ("expansion threshold"), the hull is expanded in
%   50 steps, the step size being 1/50 of the image height and the final
%   step equal to the full height.
%
%   The 50 intersection counts are stored in COUNTS, sorted ascending into
%   SORTEDCOUNTS, and summarised three ways (Table A3):
%       ME = mean, MD = median, TQ = third quartile (75th percentile).
%   The paper reports TQ as the most accurate, so AN returns the TQ value;
%   AN.ME / AN.MD / AN.TQ give all three.

    H = size(BEOA, 1);

    % (h) skeleton of the awns, spurs pruned (original used MinBranchLength 5
    % + small-component removal); (g) convex hull of the ear body.
    SKBA = bwskel(logical(BA), 'MinBranchLength', 5);
    SKBA = bwareaopen(SKBA, 20);
    CBEOA = bwconvhull(logical(BEOA));

    % Distance to the ear-body convex hull, computed ONCE. Dilating the hull
    % by radius r (Euclidean) is exactly {D <= r}; a thin band |D - r| <= w
    % is the (thick) expanded hull contour - matching the original code that
    % drew the hull boundary and dilated it by a disk of radius 3 before
    % intersecting with the awn skeleton. This avoids 50 slow imdilate calls.
    D = bwdist(CBEOA);
    band = 1.5;                                   % ~3 px thick ring (disk 3)

    nSteps = 50;
    counts = zeros(1, nSteps);
    for k = 1:nSteps
        radius = k * H / nSteps;                   % step = H/50, end = H
        ring = abs(D - radius) <= band;            % expanded hull contour
        inter = ring & SKBA;                       % (i)/(j) contour ∩ skeleton
        % Each awn crosses the contour as one small blob -> count blobs.
        counts(k) = numComponents(inter);
    end

    sortedCounts = sort(counts, 'ascend');       % array A'

    AN     = struct();
    AN.ME  = mean(sortedCounts);                 % ME
    AN.MD  = median(sortedCounts);               % MD
    AN.TQ  = quantile(sortedCounts, 0.75);       % TQ (recommended)
    AN.value = AN.TQ;                            % default reported statistic
end

function n = numComponents(bw)
    if ~any(bw(:))
        n = 0;
    else
        cc = bwconncomp(bw, 8);
        n  = cc.NumObjects;
    end
end
