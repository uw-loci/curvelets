function tumorCards = BDcreationCell(num, imgName)

if ~exist('imgName', 'var')
    imgName = '';
end

cellsCancer = pickCellsThreshold(0.5, 1.2, 4, 20, 2000);

% load('details.mat','details');
% data = details.points;
% data = double(data);

rng(1); % For reproducibility
[idx,C] = kmeans(cellsCancer.center,num);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% klist=2:10;
% myfunc = @(X,K)(kmeans(cellsCancer.center, num));
% eva = evalclusters(net.IW{1},myfunc,'CalinskiHarabasz','klist',klist);
% [idx,C]=kmeans(net.IW{1},eva.OptimalK);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sizeAreas = zeros(1,num);

tumors = tumorBD.empty(num,0);

for i=1:length(idx)
    for j=1:num
        if idx(i) == j
            sizeAreas(j) = sizeAreas(j) + 1;
        end
    end
end

for i=1:num
    X = [];
    Y = [];
    for j=1:length(idx)
        if idx(j) == i
            sizePolygon = size(cellsCancer.coord);
            for k=1:sizePolygon(3)
%                 X = [X; details.coord(j,1,k)];
%                 Y = [Y; details.coord(j,2,k)];
                X = [X; cellsCancer.coord(j,1,k)];
                Y = [Y; cellsCancer.coord(j,2,k)];
            end
        end
    end
    X = ceil(X);
    Y = ceil(Y);
    k = boundary(X,Y);
    tumors(i) = tumorBD();
    tumors(i).BD_X = X(k);
    tumors(i).BD_Y = Y(k);
    tumors(i).sizeBD = sizeAreas(i);
end

tumorCards = Tumor.empty(num,0);

for i=1:num
    cells = [];
    for j=1:length(idx)
        if idx(j) == i
            cells = [cells j];
        end
    end
    tumorCards(i) = Tumor(imgName,tumors(i),cells);
end

imshow('2B_D9_ROI2 copy.tif');
hold on
for i=1:num
    plot(tumors(i).BD_Y,tumors(i).BD_X,'LineWidth',5)
end
load('details.mat','details');
plot(details.points(:,2), details.points(:,1),'.','color','r')
hold off

end

function cellsCancer=pickCellsThreshold(lower, upper, density, closest, pixelThres)

load('details.mat','details');
data = details.points;
data = double(data);

load('cells.mat','cells');

numCell = size(data);

index = [];

for i=1:numCell(1)
    if cells(i).circularity < upper && cells(i).circularity > lower ...
            && cells(i).density > density && (cells(i).closestDistance < closest ...
            || cells(i).pixelDensity > pixelThres)
        index = [index i];
    end
end

cellsCancer.center = [];
cellsCancer.coord = [];

j = 1;
for i=1:numCell(1)
    if i == index(j)
        if j < length(index)
            j = j + 1;
        end
        cellsCancer.center = [cellsCancer.center; data(i,:)];
        cellsCancer.coord = [cellsCancer.coord; details.coord(i,:,:)];
    end
end

end