function res = measureSpikeletNumber(grainBoxes, angleDeg)
%MEASURESPIKELETNUMBER  Spikelet number by PD/QD grouping fusion.
%
%   res = measureSpikeletNumber(grainBoxes, angleDeg) implements Section
%   2.5.3(2), steps (a)-(f), Eq.(9) and Table A3 (SPN, GN).
%
%   grainBoxes : Nx4 grain detection boxes [x1 y1 x2 y2] in the EOA-crop
%                frame (pixel coordinates).
%   angleDeg   : orientation of the ear long axis (from minBoundingBox);
%                grain centres are rotated by (90 - angleDeg) so the ear
%                stands upright, reproducing the REOA of Fig.3d.
%
%   Returns a struct:
%       GN        - grain number (rows of grainBoxes)
%       SPN       - spikelet number (number of fused groups, set C)
%       label     - GNx1 spikelet id per grain (1..SPN)
%       GC        - GNx2 upright grain centres [x y], x measured from the
%                   ear centreline, y increasing up the ear
%       grainLen  - mean grain length in pixels
%       T         - classification threshold (Eq.9)
%
%   Classification logic:
%       PD (set A): sort grains by y, group while the gap to the next grain
%                   (difference of ordinates) is below T  -> same spikelet.
%       QD (set B): draw an oblique line of slope k = +/-0.4 through each
%                   centre (k>0 left of the centreline, k<0 right), take its
%                   y-intercept, sort, and group while the intercept gap is
%                   below T. This catches grains of one spikelet that sit at
%                   different heights (the triangular arrangement).
%       Fusion (set C): grains linked in EITHER A or B are merged; the
%                   connected components are the spikelets.

    res = struct('GN', 0, 'SPN', 0, 'label', [], 'GC', zeros(0,2), ...
                 'grainLen', 0, 'T', 0);

    N = size(grainBoxes, 1);
    res.GN = N;
    if N == 0
        return;
    end

    % --- grain centres and grain length in the crop frame ---------------
    cx = (grainBoxes(:,1) + grainBoxes(:,3)) / 2;
    cy = (grainBoxes(:,2) + grainBoxes(:,4)) / 2;
    bw = grainBoxes(:,3) - grainBoxes(:,1);
    bh = grainBoxes(:,4) - grainBoxes(:,2);
    grainLen = mean(max(bw, bh));           % longer box side ~ grain length
    res.grainLen = grainLen;

    % --- rotate centres so the ear is upright (Fig.3c->3d) --------------
    phi = deg2rad(90 - angleDeg);
    Rm  = [cos(phi) -sin(phi); sin(phi) cos(phi)];
    P   = ([cx cy] - mean([cx cy], 1)) * Rm.';

    % Coordinate system (step a): x from the ear centreline, y up the ear.
    x =  P(:,1) - mean(P(:,1));             % centreline at x = 0
    y = -P(:,2);                            % image row grows down -> flip
    res.GC = [x, y];

    % --- Eq.(9): classification threshold -------------------------------
    T = grainLen / 3;
    res.T = T;

    % --- set A: difference of ordinates (PD) ----------------------------
    [~, ordY] = sort(y, 'ascend');
    A = groupSorted(ordY, y(ordY), T);

    % --- set B: difference of oblique-line intercepts (QD) --------------
    k = 0.4 * ones(N,1);
    k(x >= 0) = -0.4;                       % k>0 left, k<0 right of centre
    q = y - k .* x;                         % y-intercept of each line
    [~, ordQ] = sort(q, 'ascend');
    B = groupSorted(ordQ, q(ordQ), T);

    % --- set C: fuse A and B (merge groups that share a grain) ----------
    label = fuseGroups(N, A, B);
    res.label = label;
    res.SPN   = numel(unique(label));
end

% ------------------------------------------------------------------------
function groups = groupSorted(order, vals, T)
%GROUPSORTED  Split the ordered indices wherever the value gap exceeds T.
    groups = {};
    cur = order(1);
    for i = 2:numel(order)
        if (vals(i) - vals(i-1)) < T
            cur(end+1) = order(i); %#ok<AGROW>  same spikelet
        else
            groups{end+1} = cur; %#ok<AGROW>
            cur = order(i);
        end
    end
    groups{end+1} = cur;
end

% ------------------------------------------------------------------------
function label = fuseGroups(N, A, B)
%FUSEGROUPS  Union-find fusion of two groupings into final spikelets.
%   Grains connected in group set A OR group set B end up in the same
%   spikelet; connected components give the final labels 1..SPN.
    parent = 1:N;
    for c = 1:numel(A)
        g = A{c};
        for m = 2:numel(g), parent = ufUnion(parent, g(1), g(m)); end
    end
    for c = 1:numel(B)
        g = B{c};
        for m = 2:numel(g), parent = ufUnion(parent, g(1), g(m)); end
    end

    roots = zeros(1, N);
    for i = 1:N, [parent, roots(i)] = ufFind(parent, i); end
    [~, ~, label] = unique(roots);         % relabel to 1..SPN
    label = label(:);
end

function [parent, r] = ufFind(parent, i)
    root = i;
    while parent(root) ~= root, root = parent(root); end
    while parent(i) ~= root                 % path compression
        next = parent(i); parent(i) = root; i = next;
    end
    r = root;
end

function parent = ufUnion(parent, i, j)
    [parent, ri] = ufFind(parent, i);
    [parent, rj] = ufFind(parent, j);
    if ri ~= rj, parent(ri) = rj; end
end
