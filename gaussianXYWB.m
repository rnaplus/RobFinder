function g = gaussianXYWB(pXYWB,x)
% gaussian peaks with variable baseline
% pXYWB(1:3:nParams-1)  = x peak locations
% pXYWB(2:3:nParams-1)  = y peak amplitudes
% pXYWB(3:3:nParams-1)  = peak widths
% pXYWB(end)            = bsl

g = zeros(size(x));
for i=1:3:length(pXYWB)-1
    g = g + (pXYWB(i+1).*exp(-0.5*((x-pXYWB(i))./pXYWB(i+2)).^2));
end
g = g + pXYWB(end);
end