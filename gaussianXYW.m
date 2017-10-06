function g = gaussianXYW(pXYW,x)
% gaussian peaks
% pXYW(1,:) = x peak locations
% pXYW(2,:) = y peak amplitudes
% pXYW(3,:) = peak widths

g = zeros(size(x));
for i=1:length(pXYW(1,:))
    g = g + (pXYW(2,i).*exp(-0.5*((x-pXYW(1,i))./pXYW(3,i)).^2));
end

end