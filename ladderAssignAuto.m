function [ladderPeaks, sensitivities] = ladderAssignAuto(handles)
% Assign size standards to peaks in F4/ladder data

%% Initialize and ask user for number of peaks to find
nFiles = max(size(handles.myData.filenames));
ladderPeaks = cell(nFiles, 1);
sensitivities = zeros(nFiles, 1);

def = {'23 (400bp) or 34 (600bp)?'};    % refers to no. of size-std. peaks to look for
prompt = 'How many peaks to find (max=34)?';
response = inputdlg(prompt, ' ', 1, def);
if isempty(response)
    ladderPeaks = [];
    return;
elseif isnan(str2double(response))
    ladderPeaks = [];
    return;
elseif (str2double(response)<1) || (str2double(response)>34)
    ladderPeaks = [];
    return
end

nPeaksToFind = round(str2double(response));
start_sensitivity = 0.2;
nIter =             0;
maxIter =           1000;
stepSize =          0.05;

%% Find peaks
set(gcf,'CurrentAxes',handles.progressBar);
progressBar = patch([0 1 1 0], [0 0 1 1], 'white', 'EdgeColor', 'red');
drawnow;

fprintf('\n\n');
fprintf('%8s\t%8s\t%8s\t%s\n', '#', 'nFound', 'nIters', 'Name');
fprintf('%48s\n', '------------------------------------------------------------------------------');
for n = 1:nFiles
    title(['Dataset ', num2str(n), ' of ', num2str(nFiles), '...']);
    set(progressBar,...
        'XData',[0 (n-1)/nFiles (n-1)/nFiles 0],...
        'YData',[0 0 1 1],...
        'FaceColor','red');
    drawnow;

    y = handles.myData.Dataset{n}{4};   % ladder data F4
    s = start_sensitivity;
    nFound = 1000;  % large no. of peaks just to enter the while loop
    while (nFound > nPeaksToFind) && (nIter < maxIter)
        nIter=nIter+1;
        s = s + stepSize;
        delta = mean(y .* s);
        tmp = peakdet(y, delta);
        nFound = length(tmp(:,1));
        if nFound == nPeaksToFind
            break;
        end
    end
    % Status is printed to the console window
    fprintf('%8s\t%8s\t%8s\t%s\n', num2str(n), num2str(nFound), num2str(nIter), handles.myData.filenames{n});

    % peaks found, now save data
    sensitivities(n,1) = s;
    yPeakMax = tmp(:,2);
    [xPeakMax, i_lad] = sort(tmp(:,1), 'ascend');
    yPeakMax = yPeakMax(i_lad);
    
    nMin = min(nFound, length(handles.ladderSizes));
    if nMin ~= 0
        for i = 1:nMin
            ladderPeaks{n}(i,1) = handles.ladderSizes(i);
            ladderPeaks{n}(i,2) = xPeakMax(i);
            ladderPeaks{n}(i,3) = yPeakMax(i);
        end
    else
        ladderPeaks{n}(:,1) = [];
        ladderPeaks{n}(:,2) = [];
        ladderPeaks{n}(:,3) = [];
    end
end
fprintf('\n');

% Status
title('');
set(progressBar,...
    'XData', [0 1 1 0],...
    'YData', [0 0 1 1],...
    'FaceColor', get(0,'DefaultUIControlBackgroundColor'),...
    'EdgeColor', get(0,'DefaultUIControlBackgroundColor'));
drawnow;