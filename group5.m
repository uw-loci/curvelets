function angs = group5(angles,inc,varargin)

% group5.m
% This function minimizes the standard deviation of a group of angles by shifting some of them by 180 degrees. This makes more accurate statistical
% measurements possible.
% 
% Inputs:
% 
% angles - vector of angle values obtained from the output of the newCurv
% function
% 
% inc - desired bin width
% 
% Outputs:
% 
% angs - vector of adjusted angle values
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, July 2010

if nargin < 2
    inc = 2.5;
end

bins = min(angles):inc:max(angles);
temp = angles;
angs = angles;
stdev = zeros(1,length(bins)-1);

for aa = 1:length(bins)-1

    idx = temp >= bins(end-aa);
    
    temp(idx) = temp(idx) - 180;
    
    stdev(aa) = std(temp);
    
end

stdev = horzcat(std(angles),stdev);
    
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


end


