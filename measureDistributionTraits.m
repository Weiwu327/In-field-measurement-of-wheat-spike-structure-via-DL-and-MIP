function d = measureDistributionTraits(spk, asop)
%MEASUREDISTRIBUTIONTRAITS  Grain/spikelet distribution traits (Table A3).
%
%   d = measureDistributionTraits(spk, asop) computes the spatial-arrangement
%   traits from the spikelet-classification result `spk` (from
%   measureSpikeletNumber) and the pixel scale `asop`:
%
%       SPGN - spikelet grain number = GN / SPN                    [grains]
%       GD   - grain distribution: mean Euclidean distance of a grain from
%              all other grains                                    [mm]
%       SPD  - spikelet distribution: mean difference between the ordinates
%              of the lowest grains of adjacent spikelets          [mm]
%       SPGD - spikelet grain distribution: mean Euclidean distance between
%              grains within a spikelet, averaged over spikelets   [mm]

    GN = spk.GN;  SPN = spk.SPN;
    d.SPGN = safeDiv(GN, SPN);

    GC    = spk.GC;                 % upright grain centres [x y], pixels
    label = spk.label;

    % --- GD: mean pairwise grain distance -------------------------------
    if GN >= 2
        D = pdistFull(GC);
        d.GD = mean(D(triu(true(GN), 1))) * asop;
    else
        d.GD = 0;
    end

    % --- SPGD + lowest grain of each spikelet ---------------------------
    spgdVals = [];
    lowestY  = nan(SPN, 1);
    for s = 1:SPN
        idx = find(label == s);
        pts = GC(idx, :);
        if numel(idx) >= 2
            dd = pdistFull(pts);
            spgdVals(end+1) = mean(dd(triu(true(numel(idx)), 1))); %#ok<AGROW>
        end
        lowestY(s) = min(pts(:,2));        % y up -> min y = lowest grain
    end
    if isempty(spgdVals), d.SPGD = 0; else, d.SPGD = mean(spgdVals) * asop; end

    % --- SPD: ordinate gap between lowest grains of adjacent spikelets ---
    lowestY = sort(lowestY, 'ascend');
    if numel(lowestY) >= 2
        d.SPD = mean(diff(lowestY)) * asop;
    else
        d.SPD = 0;
    end
end

% ------------------------------------------------------------------------
function D = pdistFull(P)
    n = size(P, 1);
    D = zeros(n);
    for i = 1:n
        D(i, :) = sqrt(sum((P - P(i,:)).^2, 2)).';
    end
end

function v = safeDiv(a, b)
    if b == 0, v = 0; else, v = a / b; end
end
