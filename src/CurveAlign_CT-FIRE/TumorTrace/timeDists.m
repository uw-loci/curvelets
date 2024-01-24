% timeDists.m
% find average distance to center for each timeseries region
% Inputs:
% border = binary cell border
% cent = center of cell
%
% Outputs:
% aveDists = vector of distance measures
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function aveDists = timeDists(border, cent)

aveDists = zeros(length(border),1);
% find average distance to center from each region through time
for aa = 1:length(border)
    [r c] = find(border{aa});
    tempDists = zeros(length(r),1);
    for bb = 1:length(r)
        tempr = (cent(2) - r(bb))^2;
        tempc = (cent(1) - c(bb))^2;
        tempDists(bb) = sqrt(tempr+tempc);
    end
    aveDists(aa) = mean(tempDists);
end

end