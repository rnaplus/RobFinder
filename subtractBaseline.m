function ySub = subtractBaseline(y, window, smoothSize)
% Subtract a baseline based on a rolling median
yToSub = zeros(1, length(y));
for i=1:length(y)
    if i <= window
        yToSub(i) = median(y(1:window));
    elseif i > window && i <= (length(y)-window)
        ind1 = i-window;
        ind2 = i+window;
        yToSub(i) = median(y(ind1:ind2));
    elseif i > length(y)-window
        yToSub(i) = median(y(length(y)-window:end));
    end
end
yToSub = smooth(yToSub, smoothSize)';
ySub = y - yToSub;
ySub = ySub - min(ySub);    % this makes sure there are no negative values
