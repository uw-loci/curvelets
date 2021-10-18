function [numCellsArray, minDistanceArray, numPixelsArray] = cellDensity(radius) 

load('details.mat','details')
center = details.points;
numCellsTotal = length(center);

distances = pdist2(center, center);

numCellsArray = zeros(numCellsTotal,1);
minDistanceArray = zeros(numCellsTotal,1);
numPixelsArray = zeros(numCellsTotal,1);

for i = 1:numCellsTotal
    [numCells, minDistance] = individualCellDensity(distances, i, radius);
    numCellsArray(i) = numCells;
    minDistanceArray(i) = minDistance;
    numPixelsArray(i) = pixelDensity(center(i,1), center(i,2), radius);
end

% figure
% hold on
% plot(details.points(:,1), details.points(:,2),'.')
% center = [details.points(1,1), details.points(1,2)];
% viscircles(center, 100,'Color','b')
% hold off

end

function [numCells, minDistance] = individualCellDensity(distanceChart, idx, radius)

distIdx = distanceChart(idx,:);

points = distIdx < radius;
numCells = sum(points);

minDistance = min(distIdx(distIdx>0));

end

function numPixels = pixelDensity(X, Y, radius)

load('labels.mat','labels');
sizeImg = size(labels);

numPixels = 0;

% for i=1:sizeImg(1)
%     for j=1:sizeImg(2)
%         if (j - Y)^2 + (i - X)^2 <= radius^2 && labels(i,j) > 0
%             numPixels = numPixels + 1;
%         end    
%     end
% end
if X-radius > 0
    X1 = X-radius;
else
    X1 = 1;
end

if X+radius < sizeImg(1)
    X2 = X+radius;
else
    X2 = sizeImg(1);
end

if Y-radius > 0
    Y1 = Y-radius;
else
    Y1 = 1;
end

if Y+radius < sizeImg(1)
    Y2 = Y+radius;
else
    Y2 = sizeImg(1);
end

for i=X1:X2
    for j=Y1:Y2
        if labels(i,j) > 0
            numPixels = numPixels + 1;
        end
    end
end


end