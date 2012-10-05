function [ seg_pts abs_ang ] = GetSegPixels( pt1, pt2 )
%GetSegPixels - Get all the pixels between two points on a cartesian grid
%   Step pixel by pixel and collect each point
%   pt1 and pt2 are [row, col]

seg_pts = NaN;
abs_ang = NaN;

%get slope
rise = pt2(1) - pt1(1);
run = pt2(2) - pt1(2);

%check if points are same
maxrr = max(abs(rise),abs(run));
if (maxrr == 0)
    return;
end

%return slope
abs_ang = atan(rise/run); %range -pi to pi

%walk this distance each iteration (sub pixel!)
frac_rise = 0.25*rise/maxrr;
frac_run = 0.25*run/maxrr;

spt = pt1;
y = spt(1);
x = spt(2);
i = 2; %index into output array

%initialize output (this will grow in memory, but seg should be short)
seg_pts = spt;

while (1)
    if (spt(1) == pt2(1) && spt(2) == pt2(2))
        break;
    end
    %fractional accumulators
    y = y + frac_rise;
    x = x + frac_run;
    
    %round to pixel values
    ry = round(y);
    rx = round(x);
    if (ry ~= spt(1) || rx ~= spt(2))
        spt = [ry rx];
        seg_pts(i,:) = spt;
        i = i+1;
    end
end

end

