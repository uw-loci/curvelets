classdef imgCardWholeCell
    
    % This class takes an cytoplasm image and segment it using a model of
    % choosing. It returns a cellArray which is an array of nuclei objects.
    % The object name of them is wholeCellCard.
    
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
            wholeCellLink(image,model)
            load('mask.mat','mask');
            obj.cellArray = wholeCellCreation(imageName,mask,obj);
        end
    end
end

function cells = wholeCellCreation(imgName,mask,obj)

mask = squeeze(mask);
n = max(max(mask));
fprintf('%d cells are segmented. \n', n);
cells = wholeCellCard.empty(n,0);
stats = regionprops(mask,'Centroid','BoundingBox','Area','Circularity','ConvexArea','Eccentricity',...
    'Extent','MajorAxisLength','MinorAxisLength','Orientation','Perimeter');
% add boundary 
boundaryFromMask = repmat({},n,1);
boundaryMethods = {'boundary','bwboundaries'};
bw_methodSelected = boundaryMethods{2};
fig1 = figure('pos',[100 200 512 512]);
% imagesc(imread(fullfile(obj.imagePath,obj.imageName)));
imagesc(mask); axis image equal;
for i =1:n   
    if strcmp(bw_methodSelected, 'boundary')
        [maskIndexY,maskIndexX] = find(mask == i); 
        boundaryIndex = boundary(maskIndexX,maskIndexY);
        boundaryFromMask{i} = [maskIndexX(boundaryIndex) maskIndexY(boundaryIndex)];
    elseif strcmp(bw_methodSelected, 'bwboundaries')
        maskIndividual = mask == i;   
        BW = bwboundaries(maskIndividual);       %[Y X]
        boundaryFromMask{i} = fliplr(BW{1,1});   %[X,Y]
    else
        boundaryFromMask{i} = '';
    end
    % display the individual masks
    figure(fig1)
    hold on
    plot(boundaryFromMask{i}(:,1),boundaryFromMask{i}(:,2),'r-')
    plot(stats(i).Centroid(1,1), stats(i).Centroid(1,2),'m.')
    text(stats(i).Centroid(1,1), stats(i).Centroid(1,2),sprintf('%d',i),'color','w','fontsize',10.5);
    hold off   
end
title(sprintf('cell mask for %s', obj.imageName)); 
% \close(fig1)

for i=1:n

%     [x,y] = find(mask==i);
%     k = boundary(x,y);
%     cell = wholeCellCard(imgName,[x(k),y(k)],stats(i).Area,stats(i).Circularity,stats(i).ConvexArea,...

    cell = wholeCellCard(imgName,stats(i).Centroid, boundaryFromMask{i},stats(i).Area,stats(i).Circularity,stats(i).ConvexArea,...
        stats(i).Eccentricity,stats(i).Extent,stats(i).MajorAxisLength,stats(i).MinorAxisLength,...
        stats(i).Orientation,stats(i).Perimeter);
    cells(i) = cell;
end


end

