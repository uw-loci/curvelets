% timeOline.m
% find intensity at outline for all timeseries regions
% Inputs:
% img = image for intensity measurement
% outline = outline for each region through time
%
% Outputs:
% aveLine = vector of intensity measurements
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function aveLine = timeOline(img,outline)

aveLine = zeros(length(outline),1);    
for aa = 1:length(outline)
    [r c] = find(outline{aa});
    aveLine(aa) = mean(cellIntense(img,r,c));
end

end