function g = gaussianXYBsl(pXY,x,w0,bsl)
%% gaussian peaks with fixed width
% pXY(1,:) = x peak locations
% pXY(2,:) = y peak amplitudes
% w0       = fixed width values
% bsl      = fixed baseline value (scalar)

g = zeros(size(x));
for i=1:length(w0)
    g = g + (pXY(2,i).*exp(-0.5*((x-pXY(1,i))/w0(i)).^2));
end
g = g + bsl;
end