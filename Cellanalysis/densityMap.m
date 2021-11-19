function densityMap(gridSize,densityThres)

load('labels.mat','labels')
sizeLabels = size(labels);

% points = cellCenter();
points = pixelPoints(labels);

% scatters density plot (not good)
% scatOut = scatplot(X,Y);

graphImgBuiltin(points, gridSize, densityThres, sizeLabels)
% rawCount(points, sizeLabels, 10, 10, densityThres);

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