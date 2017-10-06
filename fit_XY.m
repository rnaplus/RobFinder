function [handles, exitflag] = fit_XY(handles, n)
% fit peak parameters x0 (center) and y0 (amplitude) at fixed w0 (width)
if nargin==1, n=1; end

%% Initialize
y = handles.myData.Dataset{n}{1}';  % OH cleavage signal
pXY_all = [handles.myData.x0{n};
           handles.myData.y0{n}];
w0_all = handles.myData.w0{n};

lb_all = [pXY_all(1,:)-10;
        ones(1,length(pXY_all(2,:)))*0];
ub_all = [  pXY_all(1,:)+10;
        ones(1,length(pXY_all(2,:)))*inf];

%% Default options
idx = get(handles.axes1, 'XLim') .* 120;
minStepSize = 0.01;
maxIter = 50;
tolX = 0.1;
tolFun = 0.01;
wSize = 600;
bsl = handles.myData.bsl(n);
pkShift = 5;
displayStatus = 'off'; % {'off', 'final', or 'iter'}

%% Get user input
prompt = {  'Min x to fit',...
            'Max x to fit',...
            'Max iterations',...
            'Min. step size',...
            'Tol. in x',...
            'Tol. in f(x)',...
            'Window size',...
            'Baseline'};
titleMsg = 'Fit XY';
def = { num2str(idx(1)./120),...
        num2str(idx(2)./120),...
        num2str(maxIter),...
        num2str(minStepSize),...
        num2str(tolX),...
        num2str(tolFun),...
        num2str(wSize),...
        num2str(bsl)};
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
bsl = response(8);
%wStepSize = round(wSize/2);

%% Calculate optimum window size
totalWindowLength = idx(2) - idx(1);
windowLengthsToTest = 400:650;
if totalWindowLength < windowLengthsToTest(1)
    errorMsg = sprintf('Aborted! Total window size must be > %1.2f min long', windowLengthsToTest(1)./120);
    disp(errorMsg);
    set(handles.statusBar, 'String', errorMsg);
    exitflag=0;
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

%% Optimize parameters
% Status
msg = sprintf('Optimizing x0 and y0 parameters between %1.2f to %1.2f min... ', idx(1)./120, idx(2)./120);
disp(msg);
set(handles.statusBar, 'String', msg);

% Progress bar
set(gcf,'CurrentAxes', handles.progressBar);
pBar = patch([0 1 1 0], [0 0 1 1], 'white', 'EdgeColor', 'red');
drawnow;

[resnorm, exitflag] = deal(zeros(1, nWindows));

%% Optimize X and Y
tic
options = optimset('Display', displayStatus, 'MaxIter', maxIter, 'DiffMinChange', minStepSize, 'TolX', tolX, 'TolFun', tolFun);
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
    
    % find indices of peaks within fit region
    pkIdx = [   find(pXY_all(1,:)>idx_win(1)),...
                find(pXY_all(1,:)<idx_win(2))];
    pkIdx = [pkIdx(1), pkIdx(end)];
    if pXY_all(1, pkIdx(1)) < idx_win(1)
        exitflag=0;
        return
    end
    
    % slice based on peak indices to fit
    pXY = pXY_all(:,pkIdx(1):pkIdx(2));
    w0 = w0_all(:,pkIdx(1):pkIdx(2));
    lb = lb_all(:,pkIdx(1):pkIdx(2));
    ub = ub_all(:,pkIdx(1):pkIdx(2));
    
    % fix the first and last peaks to within a percentage of its original value
    pct = 1/100;
    lb(:,1) = pXY(:,1) - (pXY(:,1) .* pct);
    lb(:,end) = pXY(:,end) - (pXY(:,end) .* pct);
    ub(:,1) = pXY(:,1) + (pXY(:,1) .* pct);
    ub(:,end) = pXY(:,end) + (pXY(:,end) .* pct);
    
    % fix the first and last several peaks to within a percentage of its original value
    pct = 1/100;
    lb(:,1:pkShift) = pXY(:,1:pkShift) - (pXY(:,1:pkShift) .* pct);
    lb(:,end-pkShift+1:end) = pXY(:,end-pkShift+1:end) - (pXY(:,end-pkShift+1:end) .* pct);
    ub(:,1:pkShift) = pXY(:,1:pkShift) + (pXY(:,1:pkShift) .* pct);
    ub(:,end-pkShift+1:end) = pXY(:,end-pkShift+1:end) + (pXY(:,end-pkShift+1:end) .* pct);
    
    % minimize all three parameters (x0, y0, w0)
    g = @(pXY,x) gaussianXYBsl(pXY,x,w0,bsl);
    [pXY_opt, resnorm(w), ~, exitflag(w)] = ...
        lsqcurvefit(g, pXY, idx_win(1):idx_win(2), y(idx_win(1):idx_win(2)), lb, ub, options);

    % save parameters (omit first two and last two peaks due to fitting bias)
    pXY_all(:,pkIdx(1)+pkShift:pkIdx(2)-pkShift) = pXY_opt(:,1+pkShift:end-pkShift);
end

%% Update status
title(' ');
set(pBar,...
    'XData',[0 1 1 0],...
    'YData',[0 0 1 1],...
    'FaceColor',get(0,'DefaultUIControlBackgroundColor'),...
    'EdgeColor',get(0,'DefaultUIControlBackgroundColor'));
drawnow;

msg2 = sprintf('%s windows fit in %1.0f s.', num2str(w), toc);
set(handles.statusBar, 'String', [msg, msg2]);
disp(msg2);

% Check for errors during fit
if exitflag>0
    disp('Success.');
elseif any(exitflag)==0
    disp('Max. no. of iterations reached. Or...?');
    set(handles.statusBar, 'String', 'Max. no. of iterations reached. Or...?');
elseif any(exitflag)<0
    disp('Error during fit.');
    set(handles.statusBar, 'String', 'Error during fit.');
end
fprintf('\n');

%% Integrate peaks
g = @(pXYW,bsl,x) gaussianXYWBsl(pXYW, bsl, x);
nPeaks = length(pXY_all(1,:));
pkAreas = zeros(1, nPeaks);
for i=1:nPeaks
    pkAreas(i) = trapz(g([pXY_all(1,i); pXY_all(2,i); w0_all(i)], bsl, 1:length(y)));
end

%% Save
handles.myData.x0{n} = pXY_all(1,:);
handles.myData.y0{n} = pXY_all(2,:);
%handles.myData.w0 = pXYW_all(3,:);
handles.myData.bsl(n) = bsl;
handles.myData.pkAreas{n} = pkAreas;

set(handles.figure1, 'CurrentAxes', handles.axes1);
end