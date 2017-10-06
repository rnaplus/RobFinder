function [lPks, x0_all, y0_all, w0_all] = getStartParamsAuto(handles)
% get starting parameters (x0, y0, w0) based on ladder peak positions

nFiles = max(size(handles.myData.filenames));
[x0_all, y0_all, w0_all] = deal(cell(nFiles, 1));
lPks = handles.myData.ladderPeaks;

% Loop through each dataset
for n=1:nFiles
    sizeStds = lPks{n}(:,1)';
    x0_new = lPks{n}(:,2)';
    yData = handles.myData.Dataset{n}{1}';

    % find max value within +/- nPts of each ladder peak region
    nPts = 5;
    for i=1:length(x0_new)
        tmpXRange = x0_new(i)-nPts:x0_new(i)+nPts;
        [~, ind] = max(yData(tmpXRange));
        x0_new(i) = tmpXRange(ind);
    end
    % save
    lPks{n}(:,2) = x0_new;
    
    % interpolate x0 in bins
    nBins = min(length(sizeStds), length(x0_new)) - 1;
    x0 = [];
    for i=1:nBins
        xi = sizeStds(i):sizeStds(i+1)-1;
        yi = interp1(sizeStds, x0_new, xi, 'linear');
        x0 = [x0, yi];
    end

    % find max within nPts of each starting peak position
    x0_new = zeros(1,length(x0));
    nPts=3;
    for i=1:length(x0)
        tmp = round(x0(i))-nPts:round(x0(i))+nPts;
        [~, ind] = max(yData(tmp));
        x0_new(i) = tmp(ind);
    end
    x0 = x0_new;

    % get starting y values
    x = 1:length(yData);
    y0 = (interp1(x, yData, x0, 'linear'));

    % peak widths
    pkW = 2;
    w0 = ones(1,length(x0)) * pkW;
    
    % Save
    x0_all{n} = x0;
    y0_all{n} = y0;
    w0_all{n} = w0;
end

end