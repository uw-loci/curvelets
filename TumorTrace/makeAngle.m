% makeAngle.m
% find relative angle between measured curvelets and cell border
%
% Inputs:
% centers = curvelet centers
% angles = angles of curvelets
% r = row locations of outline
% c = column locations of outline
% kSize = size of ROI
%
% Outputs:
% angs = vector of angles
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function angs = makeAngle(centers,angles,r,c,kSize)
% find distance between curvelet centers and cell outline
cDists = zeros([length(r),size(centers,1)]);
for aa = 1:length(r)
    for bb = 1:size(centers,1)
        cDists(aa,bb) = sqrt((centers(bb,1) - r(aa))^2 + (centers(bb,2) - c(aa))^2);
    end
end

ang = struct('values',[],'mean',[]);
% keep only curvelets within kSize/2 distance from each outline pixel
for cc = 1:length(r)
    ind = find(cDists(cc,:) <= kSize/2);
    ang(cc).values = fixAngle(angles(ind),5);
    ang(cc).mean = mean(ang(cc).values);
end
% find slope of 10 pixel line segments representing cell border
slope = zeros(size(r));
for dd = 11:10:length(r)
    temp = (r(dd) - r(dd-10))/(c(dd) - c(dd-10));
    
    if isinf(temp)
        slope((dd-10):dd) = 90;
    else
        slope((dd-10):dd) = atand(-temp);
        if slope(dd) < 0
            slope((dd-10):dd) = slope((dd-10):dd) + 180;
        end
        
        if slope(dd) > 180
            slope((dd-10):dd) = slope((dd-10):dd) - 180;
        elseif slope(dd) > 90
            slope((dd-10):dd) = 180 - slope((dd-10):dd);
        end
    end
    
end
% find difference between curvelet angles and slopes
for ee = 1:length(slope)
    aTemp = max(ang(ee).mean,slope(ee)) - min(ang(ee).mean,slope(ee));
    if isnan(ang(ee).mean)
        aTemp = NaN;
    end
    if aTemp < 0
        aTemp = 360 + aTemp;
    end
    if aTemp > 180
        angs(ee) = aTemp - 180;
    elseif aTemp > 90
        angs(ee) = 180 - aTemp;
    else
        angs(ee) = aTemp;
    end
    
end

angs = angs';

    