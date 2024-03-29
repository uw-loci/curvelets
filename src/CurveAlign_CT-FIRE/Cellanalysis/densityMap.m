function mask = densityMap(img, gridSize, numAreas, method)

load('labels_sd.mat','labels')
sizeLabels = size(labels);

% scatters density plot (not good)
% scatOut = scatplot(X,Y);

% graphImgBuiltin(points, gridSize, densityThres, sizeLabels)
% rawCount(points, sizeLabels, 10, 10, densityThres);

mask = graphAreaEliminate(img, labels, sizeLabels, gridSize, numAreas, method);

end

function points = cellCenter()

% use cell centers (not ideal) as object to measure density
load('cells.mat','cells')
sizeCells = size(cells);
for i=1:sizeCells(2)
    X(i) = cells(i).position(1);
    Y(i) = cells(i).position(2);
end
points = [transpose(X) transpose(Y)];

end

function points = pixelPoints(labels)

% points using mask

sizeLabels = size(labels);

points = [];
for i=1:sizeLabels(1)
    for j=1:sizeLabels(2)
        if labels(i,j) > 0
            points = [points; i j];
        end
    end
end

end

function graphImgBuiltin(points, gridSize, densityThres, sizeLabels)

densityMask = hist3(points,'Nbins',[gridSize gridSize],'CdataMode','auto');
% colorbar
% view(2)

imshow('2B_D9_ROI1 copy.tif');
hold on
for i=1:gridSize
    for j=1:gridSize
        if densityMask(i,j) > densityThres
            y = [i*sizeLabels(1)/gridSize;(i+1)*sizeLabels(1)/gridSize;...
                (i+1)*sizeLabels(1)/gridSize;i*sizeLabels(1)/gridSize;...
                i*sizeLabels(1)/gridSize];
            x = [j*sizeLabels(1)/gridSize;j*sizeLabels(1)/gridSize;...
                (j+1)*sizeLabels(1)/gridSize;(j+1)*sizeLabels(1)/gridSize;...
                j*sizeLabels(1)/gridSize];
            fill(x,y,'r','edgecolor','none')
        end
    end
end
hold off

end

function rawCount(points, sizeLabels, pixelDiv, radius, thres)

selected = [];

points = points / pixelDiv;

for i=1:round(sizeLabels(1)/pixelDiv)
    for j=1:round(sizeLabels(2)/pixelDiv)
        count = 0;
        for k=1:length(points)
            if points(k,1) > (i-radius/pixelDiv) && points(k,2) > (j-radius/pixelDiv)...
                && points(k,1) < (i+radius/pixelDiv) && points(k,2) < (j+radius/pixelDiv)
                count = count + 1;
            end
        end
        if thres < count
            selected = [selected; i j];
        end
    end
end

imshow('2B_D9_ROI1 copy.tif');
hold on
for i=1:length(selected)
    rectangle('Position',[selected(i)*(pixelDiv-1)+1 selected(i)*(pixelDiv-1)+1 ...
        sizeLabels(1)/pixelDiv sizeLabels(2)/pixelDiv], 'FaceColor', 'red')
end
hold off

end

function mask = areaEliminate(densityMatrix, areaThres)

% This function takes off the small regions on the density map that have
% area smaller than the areaThres

mask = bwlabel(densityMatrix,4); % returns a matrix with regions labeled by the same number
stats = regionprops(mask,'Area');

for i=1:length(stats)
    if stats(i).Area < areaThres
        mask(mask==i) = 0;
    end
end

end

function mask = areaRankEliminate(densityMatrix, num)

% This function takes off the small regions on the density map and leaves
% the top n largest regions (n = num)

mask = bwlabel(densityMatrix,4); % returns a matrix with regions labeled by the same number
stats = regionprops(mask,'Area');

areasRegion = zeros(length(stats),1);
for i=1:length(stats)
    areasRegion(i) = stats(i).Area;
end

[~,p] = sort(areasRegion,'descend');
rank = 1:length(areasRegion);
rank(p) = rank;

for i=1:length(areasRegion)
    if rank(i) > num
        mask(mask==i) = 0;
    end
end

end

function mask = graphAreaEliminate(img, labels, sizeLabels, gridSize, Thres, method)

% This function graphs the results from area elimination methods

points = pixelPoints(labels);
densityMatrix = hist3(points,'Nbins',gridSize,'CdataMode','auto');

if strcmp(method,'Rank')
    densityMask = areaRankEliminate(densityMatrix, Thres);
elseif strcmp(method,'Thres')
    densityMask = areaEliminate(densityMatrix, Thres);
end

mask = imresize(densityMask, sizeLabels, "nearest");

end

function graphics(img, gridSize, densityMask, sizeLabels)

%imshow('2B_D9_ROI2 copy.tif');
imshow(img);
hold on
for i=1:gridSize(1)
    for j=1:gridSize(2)
        if densityMask(i,j) > 0
            y = [i*sizeLabels(1)/gridSize(1);(i+1)*sizeLabels(1)/gridSize(1);...
                (i+1)*sizeLabels(1)/gridSize(1);i*sizeLabels(1)/gridSize(1);...
                i*sizeLabels(1)/gridSize(1)];
            x = [j*sizeLabels(2)/gridSize(2);j*sizeLabels(2)/gridSize(2);...
                (j+1)*sizeLabels(2)/gridSize(2);(j+1)*sizeLabels(2)/gridSize(2);...
                j*sizeLabels(2)/gridSize(2)];
            fill(x,y,'r','edgecolor','none')
        end
    end
end
hold off

end