function [ slope ] = FindOutlineSlope(boundaryMask, idx)
% FindOutlineSlope.m - Find the angle of the boundary edge
%
% Inputs
%   boundaryMask = list [row,col] of foreground pixels in the image
%   idx is the index to a point on one of the outlines [row col]
%
% Optional Inputs
%
% Outputs
%   slope = the absolute angle of the outline around pt (in radians, -pi to pi)
% 
% Notes
%   boundaryMask is a 2D image of outlines of a binary mask created in FIJI
%   there are never diagonally connected points in the outline
%   each on pixel should have exactly 2 neighbors
%
% By Jeremy Bredfeldt Laboratory for Optical and
% Computational Instrumentation 2013

slope = NaN;

%find the list of connected points on the outline that are
%surrounding pt
num = 7; %number of points to return
[con_pts] = FindConnectedPts(boundaryMask, idx, num);

if (isnan(con_pts(1,1)))
    return;
end

%TODO: fit a curve to these points, then compute floating point angle of tangent line

%compute absolute slope of the tangent
%rise
rise = con_pts(num,1) - con_pts(1,1);
run = con_pts(num,2) - con_pts(1,2);
theta = atan(rise/run); %range -pi/2 to pi/2
%scale to 0 to 180 degrees
slope = (theta*180/pi);
if slope<0
    slope = slope+180;
end


end

