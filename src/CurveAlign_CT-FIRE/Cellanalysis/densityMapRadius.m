function mask = densityMapRadius(img, numGrid, radius, Thres)

% This method attempts to replicate the density map in QuPath, which breaks
% the image into grids like normal density maps but each grid has the
% number of objects that is within a radius

load('labels_sd.mat','labels')
sizeLabels = size(labels);
load('details_sd.mat','details')
% sizeCells = size(details.points);

densityMap = zeros(numGrid(1), numGrid(2));

for i=1:numGrid(1)
    for j=1:numGrid(2)
        center = [sizeLabels(1)/numGrid(1)*(i-1)+sizeLabels(1)/(2*numGrid(1)) ...
            sizeLabels(2)/numGrid(2)*(j-1)+sizeLabels(2)/(2*numGrid(2))];
        Idx = rangesearch(details.points,center,radius);
        densityMap(i,j) = length(Idx{1,1});
    end
end

densityMap(densityMap < Thres) = 0;
mask = imresize(densityMap, sizeLabels, "nearest");
graph(img, numGrid, densityMap, sizeLabels, Thres)

end

function graph(img, gridSize, densityMask, sizeLabels, densityThres)

% imshow('2B_D9_ROI2 copy.tif');
imshow(img)
hold on
for i=1:gridSize(1)
    for j=1:gridSize(2)
        if densityMask(i,j) > densityThres
            y = [i*sizeLabels(1)/gridSize(1);(i+1)*sizeLabels(1)/gridSize(1);...
                (i+1)*sizeLabels(1)/gridSize(1);i*sizeLabels(1)/gridSize(1);...
                i*sizeLabels(1)/gridSize(1)];
            x = [j*sizeLabels(1)/gridSize(2);j*sizeLabels(1)/gridSize(2);...
                (j+1)*sizeLabels(1)/gridSize(2);(j+1)*sizeLabels(1)/gridSize(2);...
                j*sizeLabels(1)/gridSize(2)];
            fill(x,y,'r','edgecolor','none')
        end
    end
end
hold off

end