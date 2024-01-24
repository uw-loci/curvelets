% timeInt.m
% find average intensity for a given region through timepoints
% Inputs:
% region = time series region
% img = image for intensity measurement
%
% Outputs:
% aveInt = vector of intensity values
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function aveInt = timeInt(region,img)

aveInt = zeros(length(region),1);
for aa = 1:length(region)
    locs = region{aa} > 0;
    aveInt(aa) = mean2(img(locs));
end

end
    