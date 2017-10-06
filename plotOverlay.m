function plotOverlay(handles, dataType)
% Plot an ovelay of selected data channels. dataType = {'F1'(default), 'F4' or 'Current')}

%% Check input arguments
if nargin==1
    dataType='F1';
end

%% Define which data type to plot
switch dataType
    case 'F1'
        j=1;
        yLabelString = 'Intensity';
    case 'F4'
        j=4;
        yLabelString = 'Intensity';        
    case 'Current'
        j=5;
        yLabelString = 'Current';        
end

%% Plot data
fs = 12;
figure; hold all;
nDatasets = length(handles.myData.Dataset);
for n=1:nDatasets
    x = 1:length(handles.myData.Dataset{n}{j});
    plot(x./120, handles.myData.Dataset{n}{j});
end
set(gca, 'FontSize', fs);
xlabel('Time (min)', 'FontSize', fs);
ylabel(yLabelString, 'FontSize', fs);

% Legend
legend(handles.myData.filenames);
legendLocation = 'NorthWest';
if strcmp(dataType, 'Current')
    legendLocation = 'SouthEast';
end
set(legend, 'Location', legendLocation, 'Box', 'off', 'FontSize', 9);

