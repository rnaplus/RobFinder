function varargout = RobFinder(varargin)
% ROBFINDER M-file for RobFinder.fig
%      Author: Robert N. Azad
%      Email: robert.azad@gmail.com
%      Date: 2014-05-23
%
%      ROBFINDER, by itself, creates a new ROBFINDER or raises the existing
%      singleton*.
%
%      H = ROBFINDER returns the handle to a new ROBFINDER or the handle to
%      the existing singleton*.
%
%      ROBFINDER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROBFINDER.M with the given input arguments.
%
%      ROBFINDER('Property','Value',...) creates a new ROBFINDER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CAFA_run_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RobFinder_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RobFinder

% Last Modified by GUIDE v2.5 12-May-2014 01:16:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @RobFinder_OpeningFcn, ...
    'gui_OutputFcn',  @RobFinder_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
function RobFinder_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;

% Remove the axes from the figure window on startup
set(gcf, 'CurrentAxes', handles.axes2); axis off;
set(gcf, 'CurrentAxes', handles.axes1); axis off;

% Initialize some global variables
dataPath = pwd;
if exist(dataPath, 'dir')
    handles.defaultDataDir = dataPath;
else
    handles.defaultDataDir = pwd;
end

% DNA size standards:
handles.ladderSizes = [ 20, 60, 70, 80, 90, 100, 120, 140, 160, 180,...
                        190, 200, 220, 240, 260, 280, 300, 320, 340, 360,...
                        380, 400, 420, 440, 460, 480, 500, 520, 540, 560,...
                        580, 600, 620, 640];

handles.sensitivities = [];
handles.dataLoaded = false;
set(handles.smoothBox, 'String', '5');

% Store figure sizes for the resize function
handles.figPosition = get(handles.figure1, 'Position');
linkaxes([handles.axes1, handles.axes2], 'x');

guidata(hObject, handles);
function varargout = RobFinder_OutputFcn(~, ~, handles)
varargout{1} = handles.output;
function figure1_ResizeFcn(hObject, ~, handles) %#ok
% Scales the figure window

% store the new window positions
figPos = get(hObject, 'Position');
ax1Pos = get(handles.axes1, 'Position');
ax2Pos = get(handles.axes2, 'Position');

% calculate the change in width and height of figure
deltaWidth = figPos(3) - handles.figPosition(3);
deltaHeight = figPos(4) - handles.figPosition(4);

% Scale axes1 (main figure axes)
ax1Pos(3) = ax1Pos(3) + deltaWidth;
ax1Pos(4) = ax1Pos(4) + deltaHeight;
set(handles.axes1, 'Position', ax1Pos);

% Scale axes 2 (residual plot axes)
ax2Pos(3) = ax2Pos(3) + deltaWidth;
set(handles.axes2, 'Position', ax2Pos);

% save positions for next time
handles.figPosition = figPos;
guidata(hObject, handles);

%% File Menu:
function FileMenu_Callback(~, ~, ~) %#ok
function importDataButton_Callback(hObject, ~, handles) 
% Ask user to select data files
[files, path] = uigetfile('*.txt', 'Open file(s)', handles.defaultDataDir, 'MultiSelect', 'on');
if ~isequal(files, 0)
    files = cellstr(files);
else
    return;
end
handles.defaultDataDir = path;

% Reset axes and global variables
set(handles.toggle_F1, 'Value', 1);
set(handles.toggle_F4, 'Value', 1);
cla(handles.axes1, 'reset');
cla(handles.axes2, 'reset');
set(handles.figure1, 'CurrentAxes', handles.axes1); axis off;
set(handles.figure1, 'CurrentAxes', handles.axes2); axis off;
guidata(hObject,handles);

% Load data
handles.myData = loadData(files, handles.progressBar, handles.defaultDataDir);
if isempty(handles.myData.filenames), return; end
nFiles = max(size(handles.myData.filenames));
handles.myData.bsl = zeros(1, nFiles);
handles.myData.ladderFit = cell(1, nFiles);
handles.dataLoaded = true;
guidata(hObject, handles);

set(handles.filesListbox, 'String', handles.myData.filenames, 'Value', 1);
set(handles.statusBar, 'String', ['Data directory: ', handles.defaultDataDir]);

% Update plot
set(handles.figure1, 'CurrentAxes', handles.axes1);
plotData(handles, 1);
function loadMatFile_Callback(hObject, ~, handles) %#ok
% Ask user to open a .mat file
[file, path] = uigetfile('*.mat', 'Open file(s)', handles.defaultDataDir);
if ~file, return; end
handles.defaultDataDir = path;

% Load handles from .mat file
handlesLoaded = load(fullfile(path, file));
handles.myData = handlesLoaded.handles.myData;
handles.dataLoaded = true;
guidata(hObject, handles);

% Update figure
set(handles.filesListbox, 'String', handles.myData.filenames, 'Value', 1);
set(handles.statusBar, 'String',['Data directory: ', handles.defaultDataDir]);
set(handles.toggle_F1, 'Value', 1);
set(handles.toggle_F4, 'Value', 1);
plotData(handles);
plotFit(handles);
function saveButton_Callback(~, ~, handles) %#ok
[filename, path] = uiputfile('handles.mat');
if ~filename, return; end
if ~isfield(handles, 'myData'), return; end
save([path, filename], 'handles');
function exportData_Callback(~, ~, handles) %#ok
% Get file and path to save exported data
if ~isfield(handles, 'myData'), return; end
[filename, pathname] = uiputfile('.txt', 'Save data...', 'exportedData');
if ~filename
    return;
else
    exportDataToFile(handles, [pathname, filename]);
end
function exportPeakAreas_Callback(~, ~, handles) %#ok
% Get file and path to save exported data
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');
if isempty(handles.myData.pkAreas{n}), return; end

[filename, pathname] = uiputfile('.txt', 'Save peak areas...', 'peakAreas');
if ~filename
    return;
else
    exportPeakAreasToFile(handles, [pathname, filename], n);
end

%% Plot Grid Menu:
function PlotGridMenu_Callback(~, ~, ~) %#ok
function PlotGridMenu_F1_Callback(~, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
plotGrid(handles, 'F1');
function PlotGridMenu_F4_Callback(~, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
plotGrid(handles, 'F4');
function PlotGridMenu_Current_Callback(~, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
plotGrid(handles, 'Current');

%% Plot Overlay Menu:
function PlotOverlayMenu_Callback(~, ~, ~) %#ok
function PlotOverlayMenu_F1_Callback(~, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
plotOverlay(handles, 'F1');
function PlotOverlayMenu_F4_Callback(~, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
plotOverlay(handles, 'F4');
function PlotOverlayMenu_Current_Callback(~, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
plotOverlay(handles, 'Current');

%% Plot Figures Menu:
function PlotFiguresMenu_Callback(~, ~, ~) %#ok
function PlotFigureMenu_Fit_Callback(~, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');

prompt = {  'Plot •OH data (F1)?',...
            'Plot ladder (F4)?',...
            'Plot individual •OH peaks?',...
            'Plot fitted sum of •OH peaks?',...
            'Plot peak numbers?',...
            'Plot blue dots at •OH peak max.?'};
title = 'Plot options';
def = {'1', '1', '0', '1', '1', '1'};
rsp = inputdlg(prompt, title, 1, def);
if isempty(rsp), return; end
rsp = str2double(rsp);
if isnan(rsp), return; end

plotFitFigure(handles, n, rsp(1), rsp(2), rsp(3), rsp(4), rsp(5), rsp(6));
function PlotFiguresMenu_PkAreas_Callback(~, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');
if isempty(handles.myData.pkAreas{n}), return; end
plotPeakAreas(handles, n);

%% Listbox
function filesListbox_Callback(hObject, eventdata, handles) %#ok
if ~handles.dataLoaded
    importDataButton_Callback(handles.importDataButton, eventdata, handles);
else
	n = get(handles.filesListbox, 'Value');
    plotData(handles, n);
    plotFit(handles, n);
end
function filesListbox_CreateFcn(hObject, ~, ~) %#ok
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Smoothing
function smoothButton_Callback(hObject, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');
spanSize = str2double(get(handles.smoothBox, 'String'));
if isnan(spanSize), return; end

% Perform smoothing
data = handles.myData.Dataset{n};
for j=1:4
    handles.myData.Dataset{n}{j} = smooth(data{j}, floor(spanSize), 'sgolay');
end
guidata(hObject, handles);

% Plot results
xrange = get(gca, 'XLim');
yrange = get(gca, 'YLim');
plotData(handles, n);
set(gca, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(gca, 'XLim', xrange, 'YLim', yrange);
function smoothBox_Callback(~, ~, ~) %#ok
function smoothBox_CreateFcn(hObject, ~, ~) %#ok
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% Ladder Buttons
function subBslFromRawData_button_Callback(hObj, ~, handles) %#ok
% Subtract minimum value from each dataset (simple baseline subtraction)
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');

% Perform subtraction on all datasets
iData = length(handles.myData.Dataset);
for i=1:iData
    data = handles.myData.Dataset{i};
    for j=1:4
        handles.myData.Dataset{i}{j} = data{j} - min(data{j});
    end
end
guidata(hObj, handles);

% Status update
msg = sprintf('Baselines (minimum values) subtracted from raw ladder and •OH signals.');
fprintf('%s\n\n', msg);
set(handles.statusBar, 'String', msg);

%% Update plot
xrange = get(handles.axes1, 'XLim');
yrange = get(handles.axes1, 'YLim');
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function bslSub_Callback(hObject, ~, handles) %#ok
% Subtract baseline from ladder data channel (F4)
if ~isfield(handles, 'myData'), return; end

% Ask user for input
windowSize = 600;   % in units of data points (=minutes*120)
smoothSize = 80;
prompt = {'Window size', 'Smooth size'};
def = {num2str(windowSize), num2str(smoothSize)};
rsp = inputdlg(prompt, ' ', 1, def);
if isempty(rsp), return; end
rsp = str2double(rsp);
if isnan(rsp), return; end
windowSize = floor(rsp(1));
smoothSize = floor(rsp(2));

% Status
msg = sprintf('Subtracting baselines from ladders...');
fprintf('%s\n', msg);
set(handles.statusBar, 'String', msg);

set(gcf,'CurrentAxes', handles.progressBar);
progressBar = patch([0 1 1 0], [0 0 1 1], 'white', 'EdgeColor', 'red');
drawnow;

% Loop through all datasets
tic
data = handles.myData.Dataset;
nFiles = length(data);
for n=1:nFiles
    % Status
    title(sprintf('Dataset #%1.0f of %1.0f', n, nFiles));
    set(progressBar,...
        'XData',[0 (n-1)/nFiles (n-1)/nFiles 0],...
        'YData',[0 0 1 1],...
        'FaceColor','red');
    drawnow;
    
    % Perform baseline subtraction
    handles.myData.Dataset{n}{4} = subtractBaseline(data{n}{4}', windowSize, smoothSize)';
end
guidata(hObject,handles);

% Status update
title(' ');
set(progressBar,...
    'XData', [0 1 1 0],...
    'YData', [0 0 1 1],...
    'FaceColor', get(0,'DefaultUIControlBackgroundColor'),...
    'EdgeColor', get(0,'DefaultUIControlBackgroundColor'));
drawnow;

msg2 = sprintf('Done in %1.0f s', toc);
fprintf(msg2);
fprintf('\n\n');
set(handles.statusBar, 'String', [msg, ' ', msg2]);

%% plot
xrange = get(handles.axes1, 'XLim');
yrange = get(handles.axes1, 'YLim');
plotData(handles, n);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function ladderAssignAuto_Callback(hObject, eventdata, handles) %#ok
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');

fprintf('Detecting ladder peaks in data channel F4... ');
[handles.myData.ladderPeaks, handles.sensitivities] = ladderAssignAuto(handles);
if isempty(handles.myData.ladderPeaks)
    fprintf('cancelled\n');
    return;
end

%% NEED TO PARFOR THIS
[handles.myData.ladderPeaks, handles.myData.x0, handles.myData.y0, handles.myData.w0] = ...
    getStartParamsAuto(handles);
nFiles = max(size(handles.myData.filenames));
handles.myData.pkAreas = cell(nFiles, 1);
guidata(hObject, handles);

% plot
set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim; yrange = ylim;
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function fitLadder_Callback(hObject, ~, handles, n) %#ok
% Fit ladder peaks
if ~isfield(handles, 'myData'), return; end
if nargin<4
    n = get(handles.filesListbox, 'Value');
end

[lFit, w0_regression] = fitLadderPeaks(handles, n);
if isempty(lFit) || isempty(w0_regression), return; end
handles.myData.ladderFit{n} = lFit;

% Plot peak resolution
pkRes(handles, n, 'L', true);

response = questdlg('Replace current peak widths with those from linear regression?',...
                    '', 'Yes', 'No', 'No');

if strcmp(response, 'Yes')
    % apply new widths to sample peaks
    w0_new = polyval(w0_regression, handles.myData.x0{n});
    handles.myData.w0{n} = w0_new;
end
guidata(hObject, handles);

% plot new peak fit
figure(handles.figure1);
set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim; yrange = ylim;
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);

%% OH peak fitting:
function baseline_Callback(hObject, ~, handles)%#ok
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');

% Get user input (on mouse click)
[~, y, button] = ginput(1);
if button==1
    handles.myData.bsl(n) = round(y); 
    guidata(hObject, handles);
end
function peakAdjust_Callback(hObject, eventdata, handles) %#ok
if ~isfield(handles, 'myData'), return; end

% Initialize
n = get(handles.filesListbox,'Value');
y = handles.myData.Dataset{n}{1};
x = 1:length(y);
x0_all = handles.myData.x0{n};
y0_all = handles.myData.y0{n};

% Get user input and find peak index
[xSelTime, ~, button] = ginput(1);
if button~=1, return; end
xSel = round(xSelTime .* 120);  % convert from time (min) to data points
tmp = abs(x0_all-xSel);
[~, pkIdx] = min(tmp);

% Replace the peak amplitude (y0) by the new (interpolated) value
x0_all(pkIdx) = xSel;
y0_all(pkIdx) = interp1(x, y, xSel, 'linear');

handles.myData.x0{n} = x0_all;
handles.myData.y0{n} = y0_all;
guidata(hObject, handles);

% plot
figure(handles.figure1);
xrange = get(handles.axes1, 'XLim');
yrange = get(handles.axes1, 'YLim');
plotData(handles, n);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function peakAdd_Callback(hObject, eventdata, handles) %#ok
% Add selected peak
if ~isfield(handles, 'myData'), return; end

% Initialize
n = get(handles.filesListbox,'Value');
y = handles.myData.Dataset{n}{1};
x0_all = handles.myData.x0{n};
y0_all = handles.myData.y0{n};
w0_all = handles.myData.w0{n};

% Get user input and find peak index
[xSelTime, ~, button] = ginput(1);
if button~=1, return; end
xSel = round(xSelTime .* 120);  % convert from time (min) to data points
tmp = abs(x0_all-xSel);
[~, pkIdx] = min(tmp);

% determine where to insert peak
if (x0_all(pkIdx)-xSel) > 0
    x0_all = [x0_all(1:pkIdx-1), xSel, x0_all(pkIdx:end)];
    y0_all = [y0_all(1:pkIdx-1), y(round(xSel)), y0_all(pkIdx:end)];
    w0_all = [w0_all(1:pkIdx-1), w0_all(pkIdx), w0_all(pkIdx:end)];
elseif (x0_all(pkIdx)-xSel) < 0
    x0_all = [x0_all(1:pkIdx), xSel, x0_all(pkIdx+1:end)];
    y0_all = [y0_all(1:pkIdx), y(round(xSel)), y0_all(pkIdx+1:end)];
    w0_all = [w0_all(1:pkIdx), w0_all(pkIdx), w0_all(pkIdx+1:end)];
end

% save
handles.myData.x0{n} = x0_all;
handles.myData.y0{n} = y0_all;
handles.myData.w0{n} = w0_all;
guidata(hObject, handles);

% plot
figure(handles.figure1);
xrange = get(handles.axes1, 'XLim');
yrange = get(handles.axes1, 'YLim');
plotData(handles, n); hold on;
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function peakRemove_Callback(hObject, eventdata, handles) %#ok
% Remove selected peak
if ~isfield(handles, 'myData'), return; end

n = get(handles.filesListbox, 'Value');
x0 = handles.myData.x0{n};
y0 = handles.myData.y0{n};
w0 = handles.myData.w0{n};

[xSelTime, ~, button] = ginput(1);
if button~=1, return; end
xSel = round(xSelTime .* 120);  % convert from time (min) to data points
tmp = abs(x0-xSel);
[~, pkIdx] = min(tmp);   %index of closest peak

% update and save
x0 = [x0(1:pkIdx-1), x0(pkIdx+1:end)];   %copy x0 except for selected peak
y0 = [y0(1:pkIdx-1), y0(pkIdx+1:end)];
w0 = [w0(1:pkIdx-1), w0(pkIdx+1:end)];
handles.myData.x0{n} = x0;
handles.myData.y0{n} = y0;
handles.myData.w0{n} = w0;
guidata(hObject, handles);

% plot
xrange = get(handles.axes1, 'XLim'); yrange = get(handles.axes1, 'YLim');
plotData(handles, n); hold on;
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function fit_xy_Callback(hObject, ~, handles) %#ok
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');

[handles, exitflag] = fit_XY(handles, n);
if exitflag > 0
    guidata(hObject, handles);
else
    return
end


% Plot results
figure(handles.figure1);
xrange = get(handles.axes1, 'XLim');
yrange = get(handles.axes1, 'YLim');
plotData(handles, n);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function fit_XYW_CI_Callback(hObject, ~, handles) %#ok
% fit all params using peak widths from conf. intervals
if ~isfield(handles, 'myData'), return; end
n = get(handles.filesListbox, 'Value');

[handles, exitflag] = fit_XYW_CI(handles, n);
if exitflag > 0
    guidata(hObject, handles);
else
    return
end

% Plot results
figure(handles.figure1);
xrange = get(handles.axes1, 'XLim');
yrange = get(handles.axes1, 'YLim');
plotData(handles, n);
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);

%% Plot toggles
function toggle_F1_Callback(~, ~, handles) %#ok
n = get(handles.filesListbox, 'Value');
set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim; yrange = ylim;
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function toggle_F4_Callback(~, ~, handles) %#ok
n = get(handles.filesListbox, 'Value');
set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim; yrange = ylim;
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function toggle_ladder_Callback(~, ~, handles)%#ok
n = get(handles.filesListbox, 'Value');
set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim; yrange = ylim;
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function toggleFitSum_Callback(hObject, ~, handles) %#ok
n = get(handles.filesListbox, 'Value');
set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim; yrange = ylim;
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function toggleFitPeaks_Callback(hObject, ~, handles) %#ok
n = get(handles.filesListbox, 'Value');
set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim; yrange = ylim;
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
function toggleFitMarkers_Callback(hObject, ~, handles) %#ok
n = get(handles.filesListbox, 'Value');
set(handles.figure1, 'CurrentAxes', handles.axes1);
xrange = xlim; yrange = ylim;
plotData(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);
plotFit(handles, n);
set(handles.axes1, 'XLim', xrange, 'YLim', yrange);

%% Exit
function figure1_CloseRequestFcn(hObject, ~, ~) %#ok
response = questdlg('Really exit?', '', 'Exit', 'Cancel', 'Cancel');
if isempty(response) || strcmp(response, 'Cancel')
    return;
elseif strcmp(response, 'Exit')
    delete(hObject);
end
