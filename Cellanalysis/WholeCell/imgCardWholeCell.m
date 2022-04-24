classdef imgCardWholeCell
    
    properties (Access=private)
        imageName
        imagePath
    end
    
    properties
        cellArray
    end
    
    methods
        function obj = imgCardWholeCell(model,imageName,imagePath)
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
            wholeCellLink(image,model)
            load('mask.mat','mask');
            obj.cellArray = wholeCellCreation(imageName,mask);
        end
    end
end

function cells = wholeCellCreation(imgName,mask)

mask = squeeze(mask);
n = max(max(mask));
cells = wholeCellCard.empty(n,0);

stats = regionprops(mask,'Area','Circularity','ConvexArea','Eccentricity',...
    'Extent','MajorAxisLength','MinorAxisLength','Orientation','Perimeter');

for i=1:n
    [x,y] = find(mask==i);
    k = boundary(x,y);
    cell = wholeCellCard(imgName,[x(k),y(k)],stats(i).Area,stats(i).Circularity,stats(i).ConvexArea,...
        stats(i).Eccentricity,stats(i).Extent,stats(i).MajorAxisLength,stats(i).MinorAxisLength,...
        stats(i).Orientation,stats(i).Perimeter);
    cells(i) = cell;
end


end

