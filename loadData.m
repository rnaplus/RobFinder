function DataStruct = loadData(file_names, progressBarHandle, data_dir)
% Read CEQ raw data and load into structure variable

%% Initialize
nFiles = max(size(file_names));
DataStruct = struct();
DataStruct.filenames = {};
F = cell(1,5);  % 5 possible signals (fluorescence 1-4 and current)

% Progress bar
set(gcf, 'CurrentAxes', progressBarHandle);
progressBar = patch([0 1 1 0], [0 0 1 1], 'white', 'EdgeColor', 'red');
drawnow;

%% Loop through each raw data file
n=0;
for i=1:nFiles
	% Status
    title(['Loading file ', num2str(i), ' of ', num2str(nFiles), '...']);
    set(progressBar,...
        'XData',[0 (i-1)/nFiles (i-1)/nFiles 0],...
        'YData',[0 0 1 1],...
        'FaceColor','red');
    drawnow;

    [tmp1, tmp2, tmp3, tmp4, tmpC] = readCEQ([data_dir, '/', file_names{i}]);
    if ~isempty(tmp1)
        n=n+1;
        DataStruct.filenames{n} = file_names{i};
        F{1} = tmp1;
        F{2} = tmp2;
        F{3} = tmp3;
        F{4} = tmp4;
        F{5} = tmpC;
        DataStruct.Dataset{n} = F;
    end
end
% Status update
title('');
set(progressBar,...
    'XData',[0 1 1 0],...
    'YData',[0 0 1 1],...
    'FaceColor',get(0,'DefaultUIControlBackgroundColor'),...
    'EdgeColor',get(0,'DefaultUIControlBackgroundColor'));
drawnow;
end


function [f1, f2, f3, f4, current] = readCEQ(filename)
fid = fopen(filename,'r');

nHeaderlines = 0;
indexFound = false;
sepFound = false;

% Determine the number of lines to skip
% by looking for the keywords 'Separation' and 'INDEX'
% contained in every CEQ data file
while ~indexFound && ~feof(fid)
    tline = fgets(fid);
    if ~isempty(strfind(tline, 'Separation'))
        sepFound = true;
    end
    if sepFound && ~isempty(strfind(tline, 'INDEX'))
        indexFound = true;
    end
    nHeaderlines = nHeaderlines + 1;
end
fclose(fid);

% Store each signal in an array
if indexFound
    I = importdata(filename, '\t', nHeaderlines);
    f1 = I.data(:,1);
    f2 = I.data(:,2);
    f3 = I.data(:,3);
    f4 = I.data(:,4);
    current = I.data(:,5);
else
    f1 = [];
    f2 = [];
    f3 = [];
    f4 = [];
    current = [];
end

end
