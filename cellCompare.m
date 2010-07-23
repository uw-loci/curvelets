function c = cellCompare(x,y)

% cellCompare.m
% This function finds curvelet clusters with common members
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, July 2010


c = intersect(x,y);
if any(c)
c = min(c);
else
    c = 0;
end
