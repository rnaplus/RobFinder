function plotData(handles, n)
% Plot experimental data on main figure axes
if ~handles.dataLoaded, return; end
if nargin<2
    n = get(handles.filesListbox, 'Value');
end

set(handles.figure1, 'CurrentAxes', handles.axes1);
set(handles.axes1, 'box', 'on');
hold off;

if ~get(handles.toggle_F1, 'Value') && ~get(handles.toggle_F4, 'Value')
    cla(gca, 'reset');
    return;
end

% Convert x to time (min)
tmpX = 1:length(handles.myData.Dataset{n}{1});
x = tmpX ./ 120;

if get(handles.toggle_F1, 'Value')
    plot(x, handles.myData.Dataset{n}{1}, 'k'); hold on;
end

if get(handles.toggle_F4, 'Value')
    plot(x, handles.myData.Dataset{n}{4}, 'b'); hold on;
end
xlabel('Time (min)');
ylabel('Intensity');
title(handles.myData.filenames{n}, 'Interpreter', 'none');

% plot ladder labels at peak maxima
tmp = handles.myData;
if isfield(tmp, 'ladderPeaks')
    clear tmp;
    if ~isempty(handles.myData.ladderPeaks{n}) && get(handles.toggle_ladder, 'Value')
        lPks = handles.myData.ladderPeaks{n};
        text(lPks(:,2)./120, lPks(:,3), num2str(lPks(:,1)), 'HorizontalAlignment', 'right');

        % plot vertical lines
        for i=1:length(lPks(:,2))
            line([lPks(i,2)./120, lPks(i,2)./120], ...
                [lPks(i,3), max(handles.myData.Dataset{n}{1})], ...
                'LineStyle', ':', ...
                'Color', [0.4, 0.4, 0.4]);
        end
    end
end

end