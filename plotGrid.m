function plotGrid(handles, dataType)
%% check arguments
if nargin==1
    dataType='F1';
end

%% define data to plot
switch dataType
    case 'F1'
        j=1;
        yLabel = 'Intensity (counts)';
        rgb = [0,0,0];
    case 'F4'
        j=4;
        yLabel = 'Intensity (counts)';
        rgb = [0,0,1];
    case 'Current'
        j=5;
        yLabel = 'Current';
        rgb = [1,0,0];
end
yData = handles.myData.Dataset;

%% setup plot grid based on number of runs (max=8)
nToPlot = length(yData);
if nToPlot>8, nToPlot=8; end

iy=1; ix=1;
if nToPlot==1
    iy=1; ix=1;
elseif nToPlot==2
    iy=1; ix=2;
elseif nToPlot==3
    iy=3; ix=1;
elseif nToPlot==4
    iy=2; ix=2;
elseif nToPlot==5 || nToPlot==6
    iy=3; ix=2;
elseif nToPlot>6 && nToPlot<=8
    iy=4; ix=2;
end

%% plot data
fs=10;
axH = zeros(1, nToPlot);
figure;
for n=1:nToPlot
    axH(1,n) = subplot(iy,ix,n);
    x = 1:length(handles.myData.Dataset{n}{j});
    plot(x./120, yData{n}{1,j}, 'Color', rgb);
    legend(['No. ', num2str(n)]);
    set(legend, 'FontSize', 10, 'Box', 'off', 'Location', 'NorthWest');
    title(handles.myData.filenames{n}, 'Interpreter', 'None', 'FontSize', fs, 'FontWeight', 'bold');
    xlabel('Time (min)', 'FontSize', fs);
    ylabel(yLabel, 'FontSize', fs);
end
linkaxes(axH, 'xy');

%% Set y-axis limits
yrange = get(gca, 'YLim');
ymin = yrange(1);

% Find the absolute max value in all of the data
tmp = 0;
for n = 1:length(yData)
    newTmp = max(yData{n}{1,j}(:,1));
    if newTmp > tmp
        tmp = newTmp;
    end
end

% Scale y-axis by a fixed amount (percentage)
pct = 5 / 100;
ymax = tmp + (tmp.*pct);
set(gca, 'YLim', [ymin, ymax]);
