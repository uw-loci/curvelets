function [numCells, minDistance] = cellDensity(idx, radius) 

load('details.mat','details')
center = details.points;

distances = pdist2(center, center);

distIdx = distances(idx,:);

points = distIdx < radius;
numCells = sum(points);

minDistance = min(distIdx(distIdx>0));

end