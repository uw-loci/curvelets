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