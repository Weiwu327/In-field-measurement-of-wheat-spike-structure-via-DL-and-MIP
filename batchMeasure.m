function results = batchMeasure(imgDir, labelDir, outCsv)
%BATCHMEASURE  Run measureSpikeTraits over a whole folder of images.
%
%   results = batchMeasure(imgDir, labelDir, outCsv) processes every image
%   in imgDir that has a matching <name>.txt YOLO label in labelDir, and
%   (optionally) writes the combined table to outCsv.
%
%   Example:
%     batchMeasure('test', 'labels', 'spike_traits.csv');

    if nargin < 3, outCsv = ''; end

    exts = {'*.jpg','*.jpeg','*.png','*.JPG'};
    files = [];
    for e = 1:numel(exts)
        files = [files; dir(fullfile(imgDir, exts{e}))]; %#ok<AGROW>
    end

    rows = {};
    for i = 1:numel(files)
        imgPath   = fullfile(files(i).folder, files(i).name);
        [~, base] = fileparts(files(i).name);
        labelPath = fullfile(labelDir, base + ".txt");
        if ~isfile(labelPath)
            warning('No label for %s, skipping.', files(i).name);
            continue;
        end
        try
            rows{end+1} = measureSpikeTraits(imgPath, labelPath); %#ok<AGROW>
            fprintf('[%3d/%3d] %s  ->  AN=%.0f  EL=%.1f  GN=%d  SPN=%d\n', ...
                i, numel(files), files(i).name, rows{end}.AN_TQ, ...
                rows{end}.EL_MBR, rows{end}.GN, rows{end}.SPN);
        catch ME
            warning('Failed on %s: %s', files(i).name, ME.message);
        end
    end

    if isempty(rows)
        results = table();
    else
        results = vertcat(rows{:});
    end

    if ~isempty(outCsv) && ~isempty(results)
        writetable(results, outCsv);
        fprintf('Wrote %d rows to %s\n', height(results), outCsv);
    end
end
