function [ outpt ] = GetFirstNeighbor( mask, idx, visitedList )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

%mask is a 2D image of outlines of a binary mask created in FIJI
%pt is the point around we will search for a contiguous white pixel
pt = mask(idx,:);
npt = [pt(1) pt(2)+1; pt(1)-1 pt(2); pt(1) pt(2)-1; pt(1)+1 pt(2)]; %search points
outpt = idx;
rows = mask(:,1);
cols = mask(:,2);

%check east, north, west, then south
for i = 1:length(npt)
    %find a position in the list that is next to the current one, that we haven't found yet
    chkIdx = find(rows == npt(i,1) & cols == npt(i,2),1,'first');
    if (~isempty(chkIdx) && visitedList(chkIdx)==0)
        outpt = chkIdx;
        return;
    end
end

end

