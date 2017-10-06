function [ladderFit, rw] = fitLadderPeaks(handles, n)
% Fit ladder peaks with Gaussian functions and report peak widths vs peak
% location (including confidence intervals)
if nargin==1, n=1; end

%% Initialize
y_all = handles.myData.Dataset{n}{4}';
sizeStds_all = handles.myData.ladderPeaks{n}(:,1)';
x0_all = handles.myData.ladderPeaks{n}(:,2)';
y0_all = handles.myData.ladderPeaks{n}(:,3)';
defaultPeakWidth = 2;
w0_all = ones(1,length(x0_all)) * defaultPeakWidth;
idx = get(handles.axes1, 'XLim') .* 120;
tolX = 0.1;
confidenceInterval = 99.9;
degreePoly = 1;
bsl = 0;    % starting baseline value
lb_w0 = 1;  % lower bound on peak width (in units of data points)
ub_w0 = 20; % upper bound on peak width (in units of data points)

%% Get user input
prompt = {'Min X to fit',...
        'Max X to fit',...
        'TolX',...
        'Confidence Interval',...
        'Degree of polynomial'};
def = { num2str(idx(1)./120),...
        num2str(idx(2)./120),...
        num2str(tolX),...
        num2str(confidenceInterval),...
        num2str(degreePoly)};
response = inputdlg(prompt, '', 1, def);

% Check if user pressed 'Cancel'
if isempty(response)
    ladderFit=[];
    rw=[]; 
    return;
end
response = str2double(response);
if isnan(response), return; end

% Index refers to the x-axis in units of data points (minutes * 120)
idx = [ceil(response(1).*120), floor(response(2).*120)];
if idx(1) <= 0, idx(1)=1; end
if idx(2) >= length(y_all), idx(2)=length(y_all); end

tolX = response(3);
confidenceInterval = response(4);
degreePoly = response(5);

% Status
msg = sprintf('Fitting ladder peaks...');
disp(msg);
set(handles.statusBar, 'String', msg);
tic

%% Peak slicing/indexing
y = y_all(idx(1):idx(2));
x = idx(1):idx(2);
pkIdx = [find(x0_all(1,:)>idx(1), 1, 'first'),...
        find(x0_all(1,:)<idx(2), 1, 'last')];

sizeStds = sizeStds_all(pkIdx(1):pkIdx(2));
x0 = x0_all(pkIdx(1):pkIdx(2));
y0 = y0_all(pkIdx(1):pkIdx(2));
w0 = w0_all(pkIdx(1):pkIdx(2));

%% Starting peak parameters/bounds
nParams = length(x0)*3+1;
pXYWB = zeros(1, nParams);
pXYWB(1:3:nParams-1) = x0;
pXYWB(2:3:nParams-1) = y0;
pXYWB(3:3:nParams-1) = w0;
pXYWB(end) = bsl;

[lb, ub] = deal(zeros(1,length(pXYWB)));

% lower bounds
lb(1:3:nParams-1) = x0-10;
lb(2:3:nParams-1) = ones(1, length(y0)) .* 0;
lb(3:3:nParams-1) = ones(1, length(w0)) .* lb_w0;
lb(end) = 0;

% upper bounds
ub(1:3:nParams-1) = x0+10;
ub(2:3:nParams-1) = ones(1, length(y0)) .* inf;
ub(3:3:nParams-1) = ones(1, length(w0)) .* ub_w0;
ub(end) = inf;

%% Optimize and plot peak fits
options = optimset( 'Display', 'off', 'TolX', tolX);
[pXYWB_fit, ~, ~, exitflag] = lsqcurvefit(@(pXYWB,x) gaussianXYWB(pXYWB,x), pXYWB, x, y, lb, ub, options);
if exitflag > 0
    fprintf('Success\n');
elseif exitflag == 0
    errorMsg = sprintf('Aborted! Max. no. of iterations reached. Or something else...?\n');
    disp(errorMsg);
    set(handles.statusBar, 'String', errorMsg);
    return
end

% Status
msg2 = sprintf('Done in %1.0f s.\n', toc);
disp(msg2);
set(handles.statusBar, 'String', [msg, ' ', msg2]);

% Save
x0 = pXYWB_fit(1:3:nParams-1);
y0 = pXYWB_fit(2:3:nParams-1);
w0 = pXYWB_fit(3:3:nParams-1);
bsl = pXYWB_fit(end);

% Used specifically for peak-resolution calculations:
ladderFit{1} = x0;
ladderFit{2} = y0;
ladderFit{3} = w0;
ladderFit{4} = bsl;
ladderFit{5} = sizeStds;

% Plot peak fitting results (using minutes on x-axis)
fs = 12;
figure; hold on;
plot((1:length(y_all))./120, y_all, 'k');
plot(x./120, gaussianXYWB(pXYWB_fit,x), 'r');
set(gca, 'FontSize', fs, 'Box', 'on');
xlabel('Time (min)', 'FontSize', fs);
ylabel('Intensity (counts)', 'FontSize', fs);
titleString = 'DNA size marker';
title(titleString, 'FontSize', fs);

%% Regression and confidence intervals
% Regression using units of data points on x-axis
alpha = 1 - (confidenceInterval/100);
[rw, S] = polyfit(x0, w0, degreePoly);
%[pval, delta] = polyconf(rw, x0./120, S, 'alpha', alpha, 'predopt', 'curve');

% Regression using units of minutes on x-axis
[rwTime, STime] = polyfit(x0./120, w0./120, degreePoly);
[pvalTime, deltaTime] = polyconf(rwTime, x0./120, STime, 'alpha', alpha, 'predopt', 'curve');

% calculate residual (R^2)
resid = w0./120 - pvalTime;
SSresid = sum(resid.^2);
SStotal = (length(w0)-1) * var(w0./120);
rsq = 1 - (SSresid/SStotal);

% Plot
figure; hold on;
rgb1 = [0.9, 0.9, 0.9];
plot_variance = @(x,lower,upper,color) set(fill([x,x(end:-1:1)],[upper,lower(end:-1:1)],color),'EdgeColor',color);
plot_variance(x0./120, pvalTime-deltaTime, pvalTime+deltaTime, rgb1)
plot(x0./120, w0./120, 'ro', 'MarkerSize', 6, 'LineWidth', 1.0);
plot((0:x0_all(end))./120, polyconf(rwTime, (0:x0_all(end))./120), 'k-', 'LineWidth', 1.0); %plot full x and y range

% Formatting and appearance
xlabel('Peak center (min)', 'FontSize', fs);
ylabel('Peak width', 'FontSize', fs);
title(titleString, 'FontSize', fs);
CI = sprintf('%1.1f%% confidence interval', confidenceInterval);
dataString = 'Exp. data';

% Format best-fit equation as a string
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

% Set axis limits to display
xrange = get(gca, 'XLim');
yrange = [0, max(w0./120) + (max(w0./120).*0.1)];
xrange = [0, xrange(2)];
set(gca, 'XLim', xrange, 'YLim', yrange, 'FontSize', fs, 'Box', 'on');

end