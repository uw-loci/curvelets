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
%   slope = the absolute angle of the outline around pt (in degrees, 0 to 180)
% 
% Notes
%   boundaryMask is a 2D image of outlines of a binary mask.
%     must be created with a 4-connected neighborhood type algorithm
%     see bwboundaries for more info
%
% By Jeremy Bredfeldt Laboratory for Optical and
% Computational Instrumentation 2013

slope = NaN;

%find the list of connected points on the outline that are
%surrounding pt
num = 21; %number of points to return
[con_pts] = FindConnectedPts([boundaryMask(:,2) boundaryMask(:,1)], idx, num);

if (isnan(con_pts(1,1)))
    return;
end

%figure(500);
% plot(con_pts(:,1),con_pts(:,2),'yo');

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
warning off all;

%fit a curve to these points, then compute floating point angle of tangent line
if slope < 45 || slope > 135
    %more unique points in vert dir
    y_f = linspace(con_pts(1,2),con_pts(end,2),50);
    x_p = polyfit(con_pts(:,2),con_pts(:,1),2);
    x_f = polyval(x_p,y_f);
    %figure(500);
%     plot(x_f,y_f,'r*','markersize',2);
else
    %more unique points in horiz dir
    x_f = linspace(con_pts(1,1),con_pts(end,1),50);
    y_p = polyfit(con_pts(:,1),con_pts(:,2),2);
    y_f = polyval(y_p,x_f);
    %figure(500);
%     plot(x_f,y_f,'r*','markersize',2);
end

warning on all;
rise2 = x_f(26)-x_f(24);
run2 = y_f(26)-y_f(24);
theta2 = atan(rise2/run2);
slope2 = (theta2*180/pi);
if slope2<0
    slope2 = slope2+180;
end
dif = slope2-slope;
slope = slope2;

end

