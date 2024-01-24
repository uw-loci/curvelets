function [ outpt ] = GetFirstNeighbor( mask, idx, visitedList,direction )
% GetFirstNeighbor.m - Find the first contiguous neighbor in the mask file
%
% Inputs
%   mask = list [row,col] of foreground pixels in the binary mask created in FIJI
%   idx = index of the point around which we will search for a contiguous white pixel
%   visitedList = list of pixels we've already checked
%
% Optional Inputs
%
% Outputs
%   outpt = first neighbor pixel (row,col)
%
% By Jeremy Bredfeldt Laboratory for Optical and
% Computational Instrumentation 2013


pt = mask(idx,:);
%search points

%YL: fill list in two directions 
if direction == 1
    npt = [pt(1) pt(2)+1;...   %E
        pt(1)-1 pt(2)+1;... %NE
        pt(1)-1 pt(2);...   %N
        pt(1)-1 pt(2)-1;... %NW
        pt(1) pt(2)-1;...   %W
        pt(1)+1 pt(2)-1;... %SW
        pt(1)+1 pt(2);...   %S
        pt(1)+1 pt(2)+1];   %SE
elseif direction == 2
    npt = [pt(1) pt(2)-1;...   %W
        pt(1)+1 pt(2)-1;... %SW
        pt(1)+1 pt(2);...   %S
        pt(1)+1 pt(2)+1;...   %SE
        pt(1) pt(2)+1;...   %E
        pt(1)-1 pt(2)+1;... %NE
        pt(1)-1 pt(2);...   %N
        pt(1)-1 pt(2)-1]; %NW
    
    
end
outpt = idx;
rows = mask(:,1);
cols = mask(:,2);

%check east, northeast, north, northwest, west, southwest, south, then southeast
for i = 1:length(npt)
    %find a position in the list that is next to the current one, that we haven't found yet
    chkIdx = find(rows == npt(i,1) & cols == npt(i,2),1,'first');
    if (~isempty(chkIdx) && visitedList(chkIdx)==0)
        outpt = chkIdx;
        return;
    end
end

end

