classdef imageCard
    
    properties (Access=private)
        imageName
        imagePath
    end
    
    properties
        cellArray
    end
    
    methods
        function obj=imageCard(imageName,imagePath)
            if ~exist('imagePath','var')
                imagePath = "";
            end
            obj.imageName = imageName;
            obj.imagePath = imagePath;
            if imagePath ~= ""
                image = imagePath + imageName;
            else
                image = imageName;
            end
            addpath 'vampire'
            sampling(image)
            stardistLink('sample.tif',0)
            currentDir = pwd;
            ID = 1;
            csvData = ["set ID" "condition" "set location" "tag" "note";...
                ID "--" currentDir "mask.tif" "--"];
            writematrix(csvData, 'image.csv')
            VampireCaller('image.csv')
            % obj.cellArray = cellCreation(imageName);
            obj.cellArray = cellCreation2(imageName);
        end
        
        function imgName=getImageName(obj)
            imgName = obj.imageName;
        end
        
        function path=getPath(obj)
            path = obj.imagePath;
        end
    end
end

function cells=cellCreation2(imageName)

img = imread('mask.tif');
stats = regionprops(img,'Area','Circularity','ConvexArea','Eccentricity',...
    'Extent','MajorAxisLength','MinorAxisLength','Orientation','Perimeter');

load('details.mat','details');

numCells = size(stats);
cells = cellCardInd.empty(numCells(1),0);

T = readtable('VAMPIRE datasheet mask.tif.csv','NumHeaderLines',1);
sizeTable = size(T);
idxVampire = 1;
T3 = T.(3);
T12 = T.(12);

[numCellsArray, minDistanceArray, numPixelsArray] = cellDensity(20,stats); % radius

for i=1:numCells(1)
    
    if T3(idxVampire) == i
        vampireShapeMode = T12(idxVampire);
        if idxVampire < sizeTable(1)
            idxVampire = idxVampire + 1;
        end
    else
        vampireShapeMode = 0;
    end
    
    cell = cellCardInd(imageName,i,details.points(i,:),details.coord(i,:,:),...
        stats(i).Area,stats(i).Circularity,stats(i).ConvexArea,stats(i).Eccentricity,...
        stats(i).Extent,stats(i).MajorAxisLength,stats(i).MinorAxisLength,...
        stats(i).Orientation,stats(i).Perimeter, vampireShapeMode,numCellsArray(i),...
        minDistanceArray(i),numPixelsArray(i));
    cells(i) = cell;
end

save('cells.mat','cells');

end

function cells=cellCreation(imageName)

T = readtable('VAMPIRE datasheet mask.tif.csv','NumHeaderLines',1);
sizeTable = size(T);
cells = cellCard.empty(sizeTable(1),0);

load('details.mat','details')

T3 = T.(3);
T4 = T.(4);
T5 = T.(5);
T6 = T.(6);
T7 = T.(7);
T8 = T.(8);
T9 = T.(9);
T10 = T.(10);
T11 = T.(11);
T12 = T.(12);

for i=1:sizeTable(1)
    cell = cellCard(imageName,T3(i),[T4(i) T5(i)],details.coord(i,:,:),...
        T6(i),T7(i),T8(i),T9(i),T10(i),T11(i),T12(i));
    cells(i) = cell;
end

end