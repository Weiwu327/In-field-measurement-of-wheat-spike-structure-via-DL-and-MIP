function [EL, EW, mbr] = measureEarSize(eoaBox, BEOA, asop)
%MEASUREEARSIZE  Ear length and width by DL-box and MBR methods.
%
%   [EL, EW, mbr] = measureEarSize(eoaBox, BEOA, asop) implements Section
%   2.5.3(1) and Table 1 / Table A3 (EL, EW). Results in millimetres.
%
%     DL : straight from the deep-learning EOA detection box.
%          EL.DL = box height * ASOP,  EW.DL = box width * ASOP.
%     MBR: from the minimum bounding rectangle of the ear-body mask, which
%          corrects for tilted / curved ears (recommended, esp. for EW in
%          awned varieties where the DL box also captures spreading awns).
%
%   eoaBox = [x1 y1 x2 y2] pixel box of EOA. BEOA = ear-body binary mask
%   (in the EOA crop frame). mbr holds the MBR geometry for reuse by the
%   spikelet-number rotation step.

    % --- DL method: detection box dimensions ----------------------------
    boxW = eoaBox(3) - eoaBox(1);
    boxH = eoaBox(4) - eoaBox(2);
    EL.DL = boxH * asop;
    EW.DL = boxW * asop;

    % --- MBR method: rotated minimum bounding rectangle -----------------
    [corners, Lpx, Wpx, angleDeg] = minBoundingBox(BEOA);
    EL.MBR = Lpx * asop;      % length  = longer MBR side
    EW.MBR = Wpx * asop;      % width   = shorter MBR side

    EL.value = EL.MBR;        % MBR recommended in the paper
    EW.value = EW.MBR;

    mbr = struct('corners', corners, 'L', Lpx, 'W', Wpx, 'angleDeg', angleDeg);
end
