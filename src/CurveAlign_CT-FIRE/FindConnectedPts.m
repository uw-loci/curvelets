function [ con_pts ] = FindConnectedPts(boundaryMask, idx, num )
% FindConnectedPts.m - Find list of connected points around pt, list will be num long
%   if num forces us to look outside the image, then the function
%       returns with all zeros in the list
%   if the first point is not on the mask, then return with all zeros
%
% Inputs
%   boundaryMask = list [row,col] of foreground pixels in the image
%   idx is the index to a point on one of the outlines [row col]
%   num = number of points to return (should be odd)
%
% Optional Inputs
%
% Outputs
%   con_pts = list of connected points (row,col)
% 
% Notes
%   boundaryMask is a 2D image of outlines of a binary mask created in FIJI
%   there are never diagonally connected points in the outline
%   each on pixel should have exactly 2 neighbors
%
% By Jeremy Bredfeldt Laboratory for Optical and
% Computational Instrumentation 2013

con_pts = nan(num,2);

%place pt in the middle of output list (odd length)
hnum = (num-1)/2;
mid = hnum + 1;
con_pts(mid,:) = boundaryMask(idx,:);
%now fill list to begining
sidx = idx; %starting index
visitedList = zeros(1,length(boundaryMask));%keep track of which pixels we've checked
for (i = hnum:-1:1)
    visitedList(idx) = 1;
    idx = GetFirstNeighbor(boundaryMask,idx,visitedList,1);
    con_pts(i,:) = boundaryMask(idx,:);
end

%now fill list in other direction
idx = sidx;
prevIdx = 0;
for (i = mid+1:num)
    visitedList(idx) = 1;
    idx = GetFirstNeighbor(boundaryMask,idx,visitedList,2);
    con_pts(i,:) = boundaryMask(idx,:);
end


end

