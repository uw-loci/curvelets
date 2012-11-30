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

%create an array from min to max angles
bins = min(angles):inc:max(angles);
%copy of angle array
temp = angles;
%another copy of angle array
angs = angles;
%array of zeros of length one less than bins array
stdev = zeros(1,length(bins)-1);

%loop through bins array
for aa = 1:length(bins)-1

    %get the positions of the angles that are greater than some value
    idx = temp >= bins(end-aa);
    
    %subtract 180 from each of the remaining angles
    temp(idx) = temp(idx) - 180;
    
    %compute the standard deviation of the remaining angles
    % this is the standard deviation of groupings of the angles
    stdev(aa) = std(temp);
    
end

%add on the std of all the angles
stdev = horzcat(std(angles),stdev);
    
%find the group with the minimum standard deviation
[C I] = min(stdev);


%C is the standard deviation
%I is the position of the min standard deviation
if (C < std(angs) && I < length(bins))
    %get the index of angles that have values greater than the min value in
    %the grouping with the minimum standard deviaiton
    idx = angs >= bins(end-I);
    %subtract 180 degrees from the selection of angles that are in the
    %group with the low standard deviation
    angs(idx) = angs(idx) - 180;

    %however, if the index of the grouping with the min standard deviation
    %is greater than half the length of the bin array, then add 
    if I > .5*length(bins)
        angs = angs + 180;
    end
end

if any(angs < 0)
    %if any of the angles are less than 0, then add 180 deg to all angles
    angs = angs + 180;
end

end


