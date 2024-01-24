% timeAngs.m
% find average angle per region through all timepoints
% Inputs:
% angs = list of curvelet angles
% region = timeseries regions
% 
% Outputs:
% aveAngs = vector of angles
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function aveAngs = timeAngs(angs, region)

for aa = 1:length(region)
    [r c] = find(region{aa});
    for bb = 1:length(r) - 1
        temp = (r(bb+1) - r(bb))/(c(bb+1) - c(bb));
            if isinf(temp)
                slope(bb) = 90;
            else
                slope(bb) = atand(-temp);
                if slope(bb) < 0
                    slope(bb) = slope(bb) + 180;
                end

                if slope(bb) > 180
                    slope(bb) = slope(bb) - 180;
                elseif slope(bb) > 90
                    slope(bb) = 180 - slope(bb);
                end
            end
            
          aTemp = max(angs{aa},slope(bb)) - min(angs{aa},slope(bb));   
               if aTemp < 0
                   aTemp = 360 + aTemp;
               end
               
               if aTemp > 180
                   tempAngs(bb) = aTemp - 180;
               elseif aTemp > 90
                   tempAngs(bb) = 180 - aTemp;
               else
                   tempAngs(bb) = aTemp;
               end
               
    end
    aveAngs(aa) = mean(tempAngs);
end


end
