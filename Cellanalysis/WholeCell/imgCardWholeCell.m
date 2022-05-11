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
                image = fullfile(imagePath,imageName);
            else
                image = imageName;
            end
%             wholeCellLink(image,model)
            load('mask.mat','mask');
            obj.cellArray = wholeCellCreation(imageName,mask);
        end
    end
end

function cells = wholeCellCreation(imgName,mask)

mask = squeeze(mask);
n = max(max(mask));
disp(n)
cells = wholeCellCard.empty(n,0);

stats = regionprops(mask,'Centroid','BoundingBox','Area','Circularity','ConvexArea','Eccentricity',...
    'Extent','MajorAxisLength','MinorAxisLength','Orientation','Perimeter');
% add boundary
boundaryFromMask = repmat({},n,1);
for i =1:n
    [maskIndexY,maskIndexX] = find(mask == i); 
    boundaryIndex = boundary(maskIndexX,maskIndexY);
    boundaryFromMask{i} = [maskIndexX(boundaryIndex) maskIndexY(boundaryIndex)];
    fig1 = figure('pos',[100 200 512 512]);
    imagesc(mask);
    hold on
    plot(boundaryFromMask{i}(:,1),boundaryFromMask{i}(:,2),'r-')
    plot(stats(i).Centroid(1,1), stats(i).Centroid(1,2),'m.')
    hold off   
    pause    
end
close(fig1)

for i=1:n
    cell = wholeCellCard(imgName,stats(i).Centroid, boundaryFromMask{i},stats(i).Area,stats(i).Circularity,stats(i).ConvexArea,...
        stats(i).Eccentricity,stats(i).Extent,stats(i).MajorAxisLength,stats(i).MinorAxisLength,...
        stats(i).Orientation,stats(i).Perimeter);
    cells(i) = cell;
end


end

