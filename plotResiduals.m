function residuals = plotResiduals(handles, n)
% Plot fit residuals on main figure window (axes2)
tmp = handles.myData;
if ~isfield(tmp, 'x0')
    return;
else
    clear tmp;
end
if nargin<2, n=1; end

% Initialize
y_all = handles.myData.Dataset{n}{1}';
x_all = 1:length(y_all);
pXYW_all = [handles.myData.x0{n};
            handles.myData.y0{n};
            handles.myData.w0{n}];
bsl = handles.myData.bsl(n);

% Calculate residuals (expressed as a percentage)
g = gaussianXYWBsl(pXYW_all, bsl, x_all);
residuals = (y_all-g) ./ y_all .* 100;

% Plot residuals
xrange = get(handles.axes1, 'XLim');
yrange = get(handles.axes1, 'YLim');
set(handles.figure1, 'CurrentAxes', handles.axes2);

hold off;
plot(x_all./120, residuals, 'k-');
line([0, length(y_all)], [0, 0], 'color', 'r'); % horizontal line at y=0
set(gca, 'XLim', xrange, 'XTickLabel', {}, 'FontSize', 8);
ylabel('Residual (%)', 'FontSize', 8);
set(handles.axes1, 'YLim', yrange);

end