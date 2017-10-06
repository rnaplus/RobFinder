function Rsb = pkRes(handles, n, dataType, PLOTDATA)
% Calculate and plot base resolution of fitted peaks
% dataType = 'OH' or 'L'
% PLOTDATA = true or false (create plot if true)
%
% NOTE: handles.myData.ladderFit comes from fitting ladder peaks and
% not from the original ladder peak assignments

%% Initialize
if nargin==1
    n = 1;
    dataType = 'OH';
    PLOTDATA = true;
end
if nargin==2
    dataType = 'OH';
    PLOTDATA = true;
end

if strcmp('OH', dataType)
    % OH radical
    x0 = handles.myData.x0{n};
    w0 = handles.myData.w0{n};
    xToPlot = 2:length(x0);
    markerColor = 'k';
    markerEdgeColor = markerColor;
    titleString = {handles.myData.filenames{n}, 'OH Radical Peaks'};
elseif strcmp('L', dataType)
    % Ladder
    x0 = handles.myData.ladderFit{n}{1};
    w0 = handles.myData.ladderFit{n}{3};
    sizeStds = handles.myData.ladderFit{n}{5};
    xToPlot = sizeStds(2:end);  % size standards fitted (except first one)
    markerColor = 'b';
    markerEdgeColor = 'k';
    titleString = {handles.myData.filenames{n}, 'Ladder Peaks'};
else
    Rsb=[];
    return
end


%% Peak resolution using full width at half max
% Rs = peak resolution
% Rsb = base resolution
FWHM = 2 * sqrt(2*log(2)) .* w0;    % convert w0 to full-width at half-maximum
[Rs, Rsb] = deal(zeros(1, length(w0)-1));
for i = 1:length(w0)-1
    Rs(i) = (2*log(2))^0.5 * (x0(i+1)-x0(i))./(FWHM(i+1)+FWHM(i));
    if strcmp('OH', dataType)
        Rsb(i) = ((i+1)-i) ./ Rs(i);
    elseif strcmp('L', dataType)
        Rsb(i) = (sizeStds(i+1)-sizeStds(i)) / Rs(i);
    end
end


%% Plot
if PLOTDATA
    fs = 12;
    f=figure;
    fPos = get(f, 'Position');
    newPos = [fPos(1)+fPos(3), fPos(2), fPos(3), fPos(4)];
    set(f, 'Position', newPos);
    plot(xToPlot, Rsb, 'o',...
                      'Color', markerColor,...
                      'MarkerFaceColor', markerColor,...
                      'MarkerEdgeColor', markerEdgeColor);
	xlabel('Fragment Length (bp)', 'FontSize', fs);
	ylabel('Base Resolution', 'FontSize', fs);
    title(titleString, 'FontSize', fs);
    set(gca, 'FontSize', fs, 'Box', 'on');
end

end