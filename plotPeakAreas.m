function plotPeakAreas(handles, n)
% Check inputs and for errors
tmp = handles.myData;
if ~isfield(tmp, 'pkAreas')
    return;
else
    clear tmp;
end
if nargin==1, n=1; end

% Initialize
pkAreas = handles.myData.pkAreas{n};

% plot peak areas
fs = 12;
ms = 4;
lw = 1.25;

figure;
plot(1:length(pkAreas), pkAreas, 'ko-',...
                                'LineWidth', lw,...
                                'MarkerFaceColor', 'k',...
                                'MarkerEdgeColor', 'k',...
                                'MarkerSize', ms);
%bar(pkAreas);
%set(gca, 'XLim', [1, length(pkAreas)], 'FontSize', fs);
xlabel('Peak Number', 'FontSize', fs);
ylabel('Peak Area', 'FontSize', fs);
title(handles.myData.filenames{n}, 'Interpreter', 'none', 'FontSize', fs);

%{
fs = 12;
figure;
bar(pkAreas);
set(gca, 'XLim', [1, length(pkAreas)], 'FontSize', fs);
xlabel('Peak Number', 'FontSize', fs);
ylabel('Peak Area', 'FontSize', fs);
title(handles.myData.filenames{n}, 'Interpreter', 'none', 'FontSize', fs);
%}
end