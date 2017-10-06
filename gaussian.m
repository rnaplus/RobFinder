function g = gaussian(x, x0, y0, w0)
% Generate gaussian peaks

g = zeros(size(x));
for i=1:length(x0)
    g = g + (y0(i).*exp(-0.5*((x-x0(i))/w0(i)).^2));
end

end