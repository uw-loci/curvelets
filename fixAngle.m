function a = fixAngle(x,inc)

% fixAngle.m
% This function minimizes the standard deviation between the angles of grouped curvelets, making a more accurate mean angle
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, July 2010


bins = min(x):inc:max(x);
temp = x;
angs = x;
stdev = zeros(1,length(bins)-1);

for aa = 1:length(bins)-1

    idx = temp >= bins(end-aa);
    
    temp(idx) = temp(idx) - 180;
    
    stdev(aa) = std(temp);
    
end

stdev = horzcat(std(x),stdev);
    
[C I] = min(stdev);

if (C < std(angs) && I < length(bins))
idx = angs >= bins(end-I);
angs(idx) = angs(idx) - 180;

if I > .5*length(bins)
    angs = angs + 180;
end
end

if any(angs < 0)
    angs = angs + 180;
end

a = mean(angs);

%test starts here
% fprintf('fix angle of each group = %4.3f \n', mod(a,180))
% fprintf('cir angle of each group = %4.3f \n \n',mod(circ_mean(x*pi/180*2)/2*180/pi,180))
% if abs( mod(a,180)-mod(circ_mean(x*pi/180*2)/2*180/pi,180))> 10
%    pause 
% end
% pause
%test ends here

    