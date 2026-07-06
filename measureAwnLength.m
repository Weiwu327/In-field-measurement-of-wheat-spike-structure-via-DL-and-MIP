function AL = measureAwnLength(BEWA, BEOA, BA, AN, asop)
%MEASUREAWNLENGTH  Awn length by three methods (DF / RA / ED).
%
%   AL = measureAwnLength(BEWA, BEOA, BA, AN, asop) implements Section
%   2.5.2(3) and Table A3 (AL). All outputs are in millimetres.
%
%     DF: difference in height between EWA and EOA (the awns sit above the
%         ear body, so this is how far the spike extends beyond the body).
%         DF = (H_EWA - H_EOA) * ASOP.                 [most accurate]
%     RA: ratio of the total awn-skeleton length to the awn number.
%         RA = (PSK / AN) * ASOP.
%     ED: Euclidean distance between the top point of the awns and the top
%         point of the ear body.
%
%   AN is the scalar awn number (use AN.TQ / AN.value from measureAwnNumber).

    % --- DF: vertical extent of spike vs ear body -----------------------
    rowsEWA = find(any(BEWA, 2));
    rowsEOA = find(any(BEOA, 2));
    H_EWA = rowsEWA(end) - rowsEWA(1) + 1;
    H_EOA = rowsEOA(end) - rowsEOA(1) + 1;
    AL.DF = (H_EWA - H_EOA) * asop;

    % --- RA: total skeleton length / awn number -------------------------
    SKBA = bwskel(logical(BA));
    PSK  = nnz(SKBA);                    % skeleton pixel count ~ total length
    if AN > 0
        AL.RA = (PSK / AN) * asop;
    else
        AL.RA = 0;
    end

    % --- ED: top-of-awns to top-of-ear-body Euclidean distance ----------
    topAwn  = topPoint(BEWA);            % highest spike pixel (awn tip)
    topBody = topPoint(BEOA);           % highest ear-body pixel
    AL.ED = hypot(topAwn(1) - topBody(1), topAwn(2) - topBody(2)) * asop;

    AL.value = AL.DF;                    % DF reported as primary method
end

function p = topPoint(bw)
%TOPPOINT  [x y] of the uppermost (smallest row) white pixel.
    [rows, cols] = find(bw);
    [ymin, idx]  = min(rows);
    xAtTop = mean(cols(rows == ymin));  % centre if several share the top row
    p = [xAtTop, ymin];
    if isempty(idx), p = [NaN NaN]; end
end
