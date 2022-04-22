classdef imageCardTumor
    
    % Good parameter to try this:
    % imageCardTumor('2B_D9_ROI2 copy.tif','Radius',[50 50],30,50)
    % can change Radius to Thres or Rank
    % if using Rank , ('2B_D9_ROI2 copy.tif','Radius',[50 50],5,50)
    
    properties
        img
        tumorArray
    end
    
    methods
        function obj = imageCardTumor(img, method, gridSize, numAreas, radius)
            obj.img = img;
            if strcmp(method,'Rank') || strcmp(method,'Thres')
                mask = densityMap(img, gridSize, numAreas, method);
            elseif strcmp(method,'Radius')
                mask = densityMapRadius(img, gridSize, radius);
            end
            maskLabeled = bwlabel(mask,4);
            numTumor = max(max(maskLabeled));
            tumorArray = tumorCard.empty(numTumor,0);
            for i=1:numTumor
                area = sum(sum(maskLabeled==i));
                [x,y] = find(maskLabeled==i);
                k = boundary(x,y);
                tumorArray(i) = tumorCard([x(k),y(k)],area,[x,y]);
            end
            obj.tumorArray = tumorArray;
        end
    end
end

