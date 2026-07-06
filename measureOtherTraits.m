function other = measureOtherTraits(BA, BEOA, spk, asop)
%MEASUREOTHERTRAITS  The six additional traits of Section 2.5.4 / Table A3.
%
%   other = measureOtherTraits(BA, BEOA, spk, asop) computes:
%       AS   - awn area   = (awn pixel count) * ASOP^2            [mm^2]
%       ES   - ear area   = (ear-body pixel count) * ASOP^2       [mm^2]
%       SPGN - spikelet grain number = GN / SPN                   [grains]
%       GD   - grain distribution: mean Euclidean distance of a grain from
%              all other grains                                   [mm]
%       SPD  - spikelet distribution: mean difference between the ordinates
%              of the lowest grains of adjacent spikelets         [mm]
%       SPGD - spikelet grain distribution: mean Euclidean distance between
%              grains within a spikelet, averaged over spikelets  [mm]
%
%   spk is the struct returned by measureSpikeletNumber (upright grain
%   centres GC, per-grain spikelet label, GN, SPN).

    % --- area traits (pixel count * pixel area) -------------------------
    other.AS = nnz(BA)   * asop^2;
    other.ES = nnz(BEOA) * asop^2;

    GN = spk.GN;  SPN = spk.SPN;
    other.SPGN = safeDiv(GN, SPN);

    GC    = spk.GC;                 % upright grain centres [x y], pixels
    label = spk.label;

    % --- GD: mean pairwise grain distance -------------------------------
    if GN >= 2
        D = pdistFull(GC);
        other.GD = mean(D(triu(true(GN), 1))) * asop;
    else
        other.GD = 0;
    end

    % --- SPGD: mean within-spikelet grain distance ----------------------
    spgdVals = [];
    lowestY  = nan(SPN, 1);         % ordinate of the lowest grain / spikelet
    for s = 1:SPN
        idx = find(label == s);
        pts = GC(idx, :);
        if numel(idx) >= 2
            d = pdistFull(pts);
            spgdVals(end+1) = mean(d(triu(true(numel(idx)), 1))); %#ok<AGROW>
        end
        lowestY(s) = min(pts(:,2));        % y up -> min y is the lowest grain
    end
    if isempty(spgdVals)
        other.SPGD = 0;
    else
        other.SPGD = mean(spgdVals) * asop;
    end

    % --- SPD: mean ordinate gap between lowest grains of adjacent spikelets
    lowestY = sort(lowestY, 'ascend');
    if numel(lowestY) >= 2
        other.SPD = mean(diff(lowestY)) * asop;
    else
        other.SPD = 0;
    end
end

% ------------------------------------------------------------------------
function D = pdistFull(P)
%PDISTFULL  Full NxN Euclidean distance matrix (no toolbox dependency).
    n = size(P, 1);
    D = zeros(n);
    for i = 1:n
        d = sqrt(sum((P - P(i,:)).^2, 2));
        D(i, :) = d.';
    end
end

function v = safeDiv(a, b)
    if b == 0, v = 0; else, v = a / b; end
end
