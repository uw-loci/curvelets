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
            stardistLink(image,0)
            currentDir = pwd;
            ID = 1;
            csvData = ["set ID" "condition" "set location" "tag" "note";...
                ID "--" currentDir "mask.tif" "--"];
            writematrix(csvData, 'image.csv')
            VampireCaller('image.csv')
            obj.cellArray = cellCreation(imageName);
        end
        
        function imgName=getImageName(obj)
            imgName = obj.imageName;
        end
        
        function path=getPath(obj)
            path = obj.imagePath;
        end
    end
end

function cells=cellCreation(imageName)

T = readtable('VAMPIRE datasheet mask.tif.csv','NumHeaderLines',1);
sizeTable = size(T);
cells = cellCard.empty(sizeTable(1),0);

load('details.mat','details')

for i=1:sizeTable(1)
    cell = cellCard(imageName,T(i,3),[T(i,4) T(i,5)],details.coord(i,:,:),...
        T(i,6),T(i,7),T(i,8),T(i,9),T(i,10),T(i,11),T(i,12));
    cells(i) = cell;
end

end