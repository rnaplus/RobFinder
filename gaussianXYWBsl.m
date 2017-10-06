function g = gaussianXYWBsl(pXYW,bsl,x)
% gaussian peaks with fixed baseline
% pXYW(1,:) = x peak locations
% pXYW(2,:) = y peak amplitudes
% pXYW(3,:) = peak widths
% bsl       = baseline value (scalar)

g = zeros(size(x));
for i=1:length(pXYW(1,:))
    g = g + (pXYW(2,i).*exp(-0.5*((x-pXYW(1,i))./pXYW(3,i)).^2));
end
g = g + bsl;
end