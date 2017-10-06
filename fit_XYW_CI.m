function [handles, exitflag] = fit_XYW_CI(handles, n)
% Fit peak parameters x0 (center), y0 (amplitude), and w0 (width) using confidence interval as peak width constraints

%% Initialize
if nargin==1, n=1; end

y_all = handles.myData.Dataset{n}{1}';  %OH cleavage peaks
x_all = 1:length(y_all);
pXYW_all = [handles.myData.x0{n};
            handles.myData.y0{n};
            handles.myData.w0{n}];
% lower and upper bounds:
lb_all = [  pXYW_all(1,:) - 10;
            ones(1,length(pXYW_all(2,:))) * 0;
            ones(1,length(pXYW_all(3,:))) * 2];
ub_all = [  pXYW_all(1,:) + 10;
            ones(1,length(pXYW_all(2,:))) * inf;
            ones(1,length(pXYW_all(3,:))) * 12];

%% Default options
idx = get(handles.axes1, 'XLim') .* 120;
minStepSize = 0.01;
maxIter = 50;
tolX = 0.1;
tolFun = 0.05;
wSize = 600;
confidenceInterval = 99.9;
bsl = handles.myData.bsl(n);
degreePoly = 1;
pkShift = 5;
displayStatus1 = 'off'; % for lsqcurvefit - {'off', 'final', or 'iter'}
displayStatus2 = 'off';

% Get user input
prompt = {  'Min x to fit',...
            'Max x to fit',...
            'Max iterations',...
            'Min. step size',...
            'Tol. in x',...
            'Tol. in f(x)',...
            'Window size',...
            'Confidence Interval',...
            'Baseline',...
            'Degree of polynomial'};
titleMsg = 'Fit all';
def = { num2str(idx(1)./120),...
        num2str(idx(2)./120),...
        num2str(maxIter),...
        num2str(minStepSize),...
        num2str(tolX),...
        num2str(tolFun),...
        num2str(wSize),...
        num2str(confidenceInterval),...
        num2str(bsl),...
        num2str(degreePoly)};
response = inputdlg(prompt, titleMsg, 1, def);
if isempty(response), exitflag=0; return; end
response = str2double(response);
if isnan(response), exitflag=0; return; end

idx = [ceil(response(1).*120), floor(response(2).*120)];
maxIter = round(response(3));
minStepSize = response(4);
tolX = response(5);
tolFun = response(6);
%wSize = response(7);
confidenceInterval = response(8);
bsl = response(9);
degreePoly = response(10);
%wStepSize = round(wSize/2);

%% Calculate optimum window size
totalWindowLength = idx(2) - idx(1);
windowLengthsToTest = 400:650;
if totalWindowLength < windowLengthsToTest(1)
    errorMsg = sprintf('Aborted! Total window size must be > %1.2f min long', windowLengthsToTest(1)./120);
    disp(errorMsg);
    set(handles.statusBar, 'String', errorMsg);
    exitflag = 0;
    return
end

nWindowsTmp = floor(totalWindowLength ./ windowLengthsToTest);
[nWinMin, tmpIdx] = min(round(nWindowsTmp));
%[nWinMax, tmpIdx] = max(round(nWindowsTmp));

wSize = windowLengthsToTest(tmpIdx);
wStepSize = floor(wSize./2);
nWindows = ceil((idx(2)-idx(1)) ./ wSize);
nWindows = nWindows.*2 - 1;
%disp(['Window size = ', num2str(wSize)]);
%disp(['Window step size = ', num2str(wStepSize)]);
%disp(['No. of windows = ', num2str(nWindows)]);

% Find the first and last peak within the user-specified region
pkIdx = [   find(pXYW_all(1,:) > idx(1), 1, 'first'), ...
            find(pXYW_all(1,:) < idx(2), 1, 'last')];

%% Optimize parameters (pass 1)
msg = sprintf('Pass #1:  Optimizing all parameters between %1.2f to %1.2f min... ', idx(1)./120, idx(2)./120);
disp(msg);
set(handles.statusBar, 'String', msg);

% use exitflags to check status
exitflag = zeros(1, nWindows);

% Progress bar
set(gcf,'CurrentAxes', handles.progressBar);
pBar = patch([0 1 1 0], [0 0 1 1], 'white', 'EdgeColor', 'red');
drawnow;

% fit peaks in each window separately
tic
options = optimset('Display', displayStatus1, 'MaxIter', maxIter, 'DiffMinChange', minStepSize, 'TolX', tolX, 'TolFun', tolFun);
for w=1:nWindows
    % update progress bar
    title(sprintf('Window %1.0f of %1.0f', w, nWindows));
    set(pBar,...
        'XData', [0 (w-1)/nWindows (w-1)/nWindows 0],...
        'YData', [0 0 1 1],...
        'FaceColor', 'red');
    drawnow;

    % Window indices
    tmpIdx = idx(1) + (wStepSize.*(w-1));
    if w < nWindows
        idx_win = [tmpIdx, tmpIdx+wSize];
    else %last window
        idx_win = [tmpIdx, idx(2)];
    end
    
    % find indices of peaks within fit window
    pkIdx_win = [   find(pXYW_all(1,:) > idx_win(1)),...
                    find(pXYW_all(1,:) < idx_win(2))];
    pkIdx_win = [   pkIdx_win(1), pkIdx_win(end)];

    % slice based on peak indices to fit
    pXYW_win = pXYW_all(:,pkIdx_win(1):pkIdx_win(2));
    lb = lb_all(:,pkIdx_win(1):pkIdx_win(2));
    ub = ub_all(:,pkIdx_win(1):pkIdx_win(2));

	% fix the first and last peaks to within a percentage of its original value
    pct = 1/100;
    lb(:,1) = pXYW_win(:,1) - (pXYW_win(:,1) .* pct);
    lb(:,end) = pXYW_win(:,end) - (pXYW_win(:,end) .* pct);
    ub(:,1) = pXYW_win(:,1) + (pXYW_win(:,1) .* pct);
    ub(:,end) = pXYW_win(:,end) + (pXYW_win(:,end) .* pct);

    % optimize all three parameters (x0, y0, w0)
    [pXYW_opt, ~, ~, exitflag(w)] = ...
        lsqcurvefit(@(pXYW_win,x) gaussianXYWBsl(pXYW_win,bsl,x), pXYW_win, idx_win(1):idx_win(2), y_all(idx_win(1):idx_win(2)), lb, ub, options);

    % save parameters (omit first and last (pkShift) peaks due to fitting bias)
    pXYW_all(:,pkIdx_win(1)+pkShift:pkIdx_win(2)-pkShift) = pXYW_opt(:,1+pkShift:end-pkShift);
end

% Update status
title(' ');
set(pBar,...
    'XData',[0 1 1 0],...
    'YData',[0 0 1 1],...
    'FaceColor',get(0,'DefaultUIControlBackgroundColor'),...
    'EdgeColor',get(0,'DefaultUIControlBackgroundColor'));
drawnow;

% Check for errors during fit
if exitflag>0
    fprintf('Success\n');
elseif any(exitflag)==0
    fprintf('Max. no. of iterations reached. Or...?\n');
    set(handles.statusBar, 'String', 'Max. no. of iterations reached. Or...?');
elseif any(exitflag)<0
    fprintf('Error during fit.\n');
    set(handles.statusBar, 'String', 'Error during fit.');
end

% Update status
msg2 = sprintf('%s windows fit in %1.0f s.', num2str(w), toc);
set(handles.statusBar, 'String', [msg, ' ', msg2]);
disp(msg2);
fprintf('\n');

%% Linear regression and confidence interval
% only include peaks that were fit
x0 = pXYW_all(1, pkIdx(1)+pkShift:pkIdx(2)-pkShift);
w0 = pXYW_all(3, pkIdx(1)+pkShift:pkIdx(2)-pkShift);

% regression using data points on x-axis
alpha = 1 - (confidenceInterval/100);
[rw, S] = polyfit(x0, w0, degreePoly);
[pval, delta] = polyconf(rw, x0, S, 'alpha', alpha, 'predopt', 'curve');

% regression using time on x-axis
[rwTime, STime] = polyfit(x0./120, w0./120, degreePoly);
[pvalTime, deltaTime] = polyconf(rwTime, x0./120, STime, 'alpha', alpha, 'predopt', 'curve');

% calculate residual (R^2)
resid = w0./120 - pvalTime;
SSresid = sum(resid.^2);
SStotal = (length(w0)-1) * var(w0./120);
rsq = 1 - (SSresid/SStotal);

% Plot peak width regression
rgb1 = [0.9, 0.9, 0];   % yellow
%rgb1 = [0.9, 0.9, 0.9]; % gray
figure; hold on;
plot_variance = @(x,lower,upper,color) set(fill([x,x(end:-1:1)],[upper,lower(end:-1:1)],color),'EdgeColor',color);
plot_variance(x0./120, pvalTime-deltaTime, pvalTime+deltaTime, rgb1)
plot(x0./120, w0./120, 'ro', 'MarkerSize', 6, 'LineWidth', 1.0);
plot((x_all(1:idx(2)))./120, polyconf(rwTime, (x_all(1:idx(2)))./120), 'k-', 'LineWidth', 1.0); %plot full x and y range

% formatting and appearance
fs = 12;
set(gca, 'FontSize', fs);
xlabel('Peak center (min)', 'FontSize', fs);
ylabel('Peak width', 'FontSize', fs);
titleString = 'Hydroxyl radical peak width analysis';
title(titleString, 'FontSize', fs);
CI = sprintf('%1.1f%% confidence interval', confidenceInterval);
dataString = 'Exp. data';

% Format best-fit equation as a string:
if degreePoly == 1
    eqnString = sprintf('y = %1.2E*x + %1.3f\nR^2=%1.3f', rwTime(1), rwTime(2), rsq);
elseif degreePoly == 2
    eqnString = sprintf('y = %1.2E*x^2 + %1.2E*x + %1.2f\nR^2=%1.3f', rwTime(1), rwTime(2), rwTime(3), rsq);
elseif degreePoly == 3
    eqnString = sprintf('y = %1.2E*x^3 + %1.2E*x^2 + %1.2E*x + %1.2f\nR^2=%1.3f', rwTime(1), rwTime(2), rwTime(3), rw(4), rsq);
else
    eqnString = sprintf('Degree of polynomial = %1.0f\nR^2=%1.3f', degreePoly, rsq);
end
legend({CI, dataString, eqnString});
set(legend, 'Box', 'off', 'Location', 'NorthWest', 'FontSize', 11);

% Set axis limits:
xrange = get(gca, 'XLim');
yrange = [0, max(w0./120) + (max(w0./120).*0.1)];
xrange = [0, xrange(2)];
set(gca, 'XLim', xrange, 'YLim', yrange, 'FontSize', fs, 'Box', 'on');

%% Pass 2 (with confidence intervals as bounds)

% Set new widths for all peaks
pval_all = polyval(rw, handles.myData.x0{n});
pXYW_all(3,:) = pval_all;
w0 = pXYW_all(3, pkIdx(1)+pkShift:pkIdx(2)-pkShift);

%% Optimize parameters
% Status
msg = sprintf('Pass #2:  Optimizing all parameters between %1.2f to %1.2f min... ', idx(1)./120, idx(2)./120);
disp(msg);
set(handles.statusBar, 'String', msg);

% Progress bar
set(figure(handles.figure1), 'CurrentAxes', handles.progressBar);
pBar = patch([0 1 1 0], [0 0 1 1], 'white', 'EdgeColor', 'red');
drawnow;

% Bounds on all three peak parameters x0, y0, w0
lb_all(1,pkIdx(1)+pkShift:pkIdx(2)-pkShift) = x0-5;
lb_all(3,pkIdx(1)+pkShift:pkIdx(2)-pkShift) = w0-delta;
ub_all(1,pkIdx(1)+pkShift:pkIdx(2)-pkShift) = x0+5;
ub_all(3,pkIdx(1)+pkShift:pkIdx(2)-pkShift) = w0+delta;

% Optimize parameters within each sub-window
tic
exitflag = zeros(1, nWindows);
options = optimset('Display', displayStatus2, 'MaxIter', maxIter, 'DiffMinChange', minStepSize, 'TolX', tolX, 'TolFun', tolFun);
for w=1:nWindows
    % progress bar
    title(sprintf('Window %1.0f of %1.0f', w, nWindows));
    set(pBar,...
        'XData', [0 (w-1)/nWindows (w-1)/nWindows 0],...
        'YData', [0 0 1 1],...
        'FaceColor', 'red');
    drawnow;

    % Window indices
    tmpIdx = idx(1)+(wStepSize*(w-1));
    if w < nWindows
        idx_win = [tmpIdx, tmpIdx+wSize];
    else %last window
        idx_win = [tmpIdx, idx(2)];
    end
    
    % find indices of peaks within fit window
    pkIdx_win = [   find(pXYW_all(1,:)>idx_win(1)),...
                    find(pXYW_all(1,:)<idx_win(2))];
    pkIdx_win = [   pkIdx_win(1), pkIdx_win(end)];

    % slice based on peak indices to fit
    pXYW_win = pXYW_all(:,pkIdx_win(1):pkIdx_win(2));
    lb = lb_all(:,pkIdx_win(1):pkIdx_win(2));
    ub = ub_all(:,pkIdx_win(1):pkIdx_win(2));

	% fix the first and last peaks to within a percentage of its original value
    pct = 1/100;
    lb(:,1) = pXYW_win(:,1) - (pXYW_win(:,1) .* pct);
    lb(:,end) = pXYW_win(:,end) - (pXYW_win(:,end) .* pct);
    ub(:,1) = pXYW_win(:,1) + (pXYW_win(:,1) .* pct);
    ub(:,end) = pXYW_win(:,end) + (pXYW_win(:,end) .* pct);
    
    % minimize all three parameters (x0, y0, w0)
    [pXYW_opt, ~, ~, exitflag(w)] = ...
        lsqcurvefit(@(pXYW_win,x) gaussianXYWBsl(pXYW_win,bsl,x), pXYW_win, idx_win(1):idx_win(2), y_all(idx_win(1):idx_win(2)), lb, ub, options);

    % save parameters (omit first two and last two peaks due to fitting bias)
    pXYW_all(:,pkIdx_win(1)+pkShift:pkIdx_win(2)-pkShift) = pXYW_opt(:,1+pkShift:end-pkShift);
end

% Update status
title(' ');
set(pBar,...
    'XData',[0 1 1 0],...
    'YData',[0 0 1 1],...
    'FaceColor',get(0,'DefaultUIControlBackgroundColor'),...
    'EdgeColor',get(0,'DefaultUIControlBackgroundColor'));
drawnow;

% Check for errors during fit
if exitflag>0
    fprintf('Success\n');
elseif any(exitflag)==0
    fprintf('Max. no. of iterations reached. Or...?\n');
    set(handles.statusBar, 'String', 'Max. no. of iterations reached. Or...?');
elseif any(exitflag)<0
    fprintf('Error during fit.\n');
    set(handles.statusBar, 'String', 'Error during fit.');
end

% Update status
msg2 = sprintf('%s windows fit in %1.0f s.', num2str(w), toc);
set(handles.statusBar, 'String', [msg, ' ', msg2]);
disp(msg2);
fprintf('\n');

%% Linear regression and confidence interval
% only include peaks that were fit
x0 = pXYW_all(1, pkIdx(1)+pkShift:pkIdx(2)-pkShift);
w0 = pXYW_all(3, pkIdx(1)+pkShift:pkIdx(2)-pkShift);

% calculate residual (R^2)
resid = w0./120 - pvalTime;
SSresid = sum(resid.^2);
SStotal = (length(w0)-1) * var(w0./120);
rsq = 1 - (SSresid/SStotal);

% Plot
figure; hold on;
plot_variance(x0./120, pvalTime-deltaTime, pvalTime+deltaTime, rgb1);
plot(x0./120, w0./120, 'ro', 'MarkerSize', 6, 'LineWidth', 1.0);
plot((x_all(1:idx(2)))./120, polyconf(rwTime, (x_all(1:idx(2)))./120), 'k-', 'LineWidth', 1.0); %plot full x and y range

% Formatting and appearance
set(gca, 'FontSize', fs);
xlabel('Peak center (min)', 'FontSize', fs);
ylabel('Peak width', 'FontSize', fs);
title(titleString, 'FontSize', fs);

% Format equation as a string
%{
if degreePoly == 1
    eqnString = sprintf('y = %1.2E*x + %1.3f\nR^2=%1.3f', rwTime(1), rwTime(2), rsq);
elseif degreePoly == 2
    eqnString = sprintf('y = %1.2E*x^2 + %1.2E*x + %1.2f\nR^2=%1.3f', rwTime(1), rwTime(2), rwTime(3), rsq);
elseif degreePoly == 3
    eqnString = sprintf('y = %1.2E*x^3 + %1.2E*x^2 + %1.2E*x + %1.2f\nR^2=%1.3f', rwTime(1), rwTime(2), rwTime(3), rw(4), rsq);
else
    eqnString = sprintf('Degree of polynomial = %1.0f\nR^2=%1.3f', degreePoly, rsq);
end
%}
legend({CI, dataString, eqnString});
set(legend, 'Box', 'off', 'Location', 'NorthWest', 'FontSize', 11);

xrange = get(gca, 'XLim');
yrange = [0, max(w0./120) + (max(w0./120).*0.1)];
xrange = [0, xrange(2)];
set(gca, 'XLim', xrange, 'YLim', yrange, 'FontSize', fs, 'Box', 'on');

%% Integrate peaks
g = @(pXYW,bsl,x) gaussianXYWBsl(pXYW, bsl, x);
nPeaks = length(pXYW_all(1,:));
pkAreas = zeros(1, nPeaks);
for i=1:nPeaks
    pkAreas(i) = trapz(g(pXYW_all(:,i), bsl, x_all));
end

%% Save
handles.myData.x0{n} = pXYW_all(1,:);
handles.myData.y0{n} = pXYW_all(2,:);
handles.myData.w0{n} = pXYW_all(3,:);
handles.myData.bsl(n) = bsl;
handles.myData.pkAreas{n} = pkAreas;

set(handles.figure1, 'CurrentAxes', handles.axes1);
end