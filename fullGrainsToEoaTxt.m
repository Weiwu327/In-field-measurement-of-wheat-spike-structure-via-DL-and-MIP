function grainTxt = fullGrainsToEoaTxt(detTxt, eoaBox, imgW, imgH, grainTxt)
%FULLGRAINSTOEOATXT  Build an EOA-crop grain label from full-image grains.
%
%   grainTxt = fullGrainsToEoaTxt(detTxt, eoaBox, imgW, imgH, grainTxt)
%   takes the class-2 (grain) boxes from a FULL-IMAGE detection txt and
%   re-expresses them, normalised to the EOA crop, so Stage 4 can be
%   validated without running a separate grain detector.
%
%   This is a VALIDATION CONVENIENCE only. In production, Stage 3 detects
%   grains directly on the EOA subimage (higher accuracy - see the paper's
%   two-stage grain detection). Use this when you only have the full-image
%   4-class label and want to exercise Stages 2-4 end to end.
%
%   detTxt : full-image YOLO txt (must contain class-2 grain boxes)
%   eoaBox : [x1 y1 x2 y2] EOA box in full-image pixels (from Stage 2)
%   imgW/H : original image size used to un-normalise detTxt

    det = readYoloLabels(detTxt, imgW, imgH);   % grains in full-image pixels
    g   = det.grains;

    x1 = eoaBox(1); y1 = eoaBox(2);
    Weoa = eoaBox(3) - eoaBox(1);
    Heoa = eoaBox(4) - eoaBox(2);

    boxes = zeros(0,5);
    for i = 1:size(g,1)
        % shift into EOA-crop frame, keep grains whose centre is inside
        cx = (g(i,1)+g(i,3))/2 - x1;
        cy = (g(i,2)+g(i,4))/2 - y1;
        if cx < 0 || cy < 0 || cx > Weoa || cy > Heoa, continue; end
        w = g(i,3)-g(i,1);  h = g(i,4)-g(i,2);
        boxes(end+1,:) = [2, cx/Weoa, cy/Heoa, w/Weoa, h/Heoa]; %#ok<AGROW>
    end

    fid = fopen(grainTxt, 'w');
    assert(fid > 0, 'Cannot open %s', grainTxt);
    c = onCleanup(@() fclose(fid));
    for i = 1:size(boxes,1)
        fprintf(fid, '%d %.6f %.6f %.6f %.6f\n', 2, boxes(i,2:5));
    end
    fprintf('[helper] %d grains -> %s (EOA-crop frame)\n', size(boxes,1), grainTxt);
end
