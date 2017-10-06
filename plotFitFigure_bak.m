function plotFitFigure(handles, n, OH, LADDER, PEAKS, FITSUM, PKNUMS, PKMAX, idx, seq)
% Plot experimental and fit data with options. "idx" specifies range in which to display peak numbers
if nargin < 8
    n = 1;
    OH      = true;
    LADDER  = true;
    FITSUM  = true;
    PKNUMS  = true;
    PKMAX   = true;
    PEAKS   = true;
    seq     = '';
end

tmp = handles.myData;
if ~isfield(tmp, 'x0')
    return;
end
clear tmp;

%% Initialize
yOH = handles.myData.Dataset{n}{1};
yL = handles.myData.Dataset{n}{4};
x = 1:length(yOH);
x0 = handles.myData.x0{n};
y0 = handles.myData.y0{n};
w0 = handles.myData.w0{n};
pXYW = [x0; y0; w0];
bsl = handles.myData.bsl(n);
yInterp = interp1(x, yOH, x0, 'linear');
if nargin<9, idx = [1, length(x0)]; end

% find indices of peaks within fit region
pkIdx = [find(x0>idx(1)), find(x0<idx(2))];
pkIdx = [pkIdx(1), pkIdx(end)];


%% Plot fit data
figure; hold on;

% Plot single peaks
if PEAKS
    nPeaks = length(x0);
    hold on;
    for p=1:nPeaks
        plot(x, gaussianXYWBsl(pXYW(:,p),bsl,x), 'g-', 'LineWidth', 0.75);
    end
end

% Plot fit sum
if FITSUM, plot(x, gaussianXYWBsl([x0;y0;w0],bsl,x), 'r'); end

% Plot experimental data
if OH, plot(x, yOH, 'k'); end

% Plot blue dots
if PKMAX, plot(x0, yInterp, 'bo', 'MarkerSize', 4, 'MarkerFaceColor', 'b'); end

% Plot residue numbers/labels
if PKNUMS
    for i=pkIdx(1):1:pkIdx(2)
        if exist('seq','var') && ~isempty(seq)
            text(x0(i), yInterp(i)+800, [seq(i), num2str(i)], 'FontSize', 8, 'HorizontalAlignment', 'center');
        else
            text(x0(i), yInterp(i)+800, num2str(i), 'FontSize', 8, 'HorizontalAlignment', 'center');
        end
    end
end

% Plot ladder
if LADDER
    plot(x, yL, 'b'); 
end


end