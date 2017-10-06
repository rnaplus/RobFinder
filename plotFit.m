function plotFit(handles,n)
% update fit plots on main figure
if ~isfield(handles, 'myData'), return; end
tmp = handles.myData;
if ~isfield(tmp, 'x0')
    return;
else
    clear tmp;
end
if nargin<2
    n = get(handles.filesListbox, 'Value');
end

set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim;
yrange = ylim;

if  (~isfield(handles, 'myData'))
    plotData(handles);
    set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
end

%% Initialize
y = handles.myData.Dataset{n}{1};
x = 1:length(y);
x0 = handles.myData.x0{n};
y0 = handles.myData.y0{n};
w0 = handles.myData.w0{n};
pXYW = [x0; y0; w0];
bsl = handles.myData.bsl(n);

% Plot single peaks
if get(handles.toggleFitPeaks, 'Value') == 1
    nPeaks = length(x0);
    hold on;
    for p=1:nPeaks
        plot(x./120, gaussianXYWBsl(pXYW(:,p),bsl,x), 'g-', 'LineWidth', 0.75);
    end
end

%% Plot

% OH radical sum of fitted peaks
if get(handles.toggleFitSum, 'Value') == 1
    plot(x./120, gaussianXYWBsl(pXYW,bsl,x), 'r');
end

% Ladder data
if get(handles.toggle_F1, 'Value') == 1
    plot(x./120, y, 'k');
end

% Blue markers near peak maxima
if get(handles.toggleFitMarkers, 'Value') == 1
    plot(x0'./120, interp1(x,y,x0,'linear'), 'bo', 'MarkerSize', 3, 'MarkerFaceColor', 'b');
end

set(handles.axes1, 'XLim', xrange, 'YLim', yrange);

% Residuals
set(handles.figure1, 'CurrentAxes', handles.axes2);
plotResiduals(handles, n);