classdef imageCardTumor
    
    properties
        tumorArray
    end
    
    methods
        function obj = imageCardTumor(img, method, gridSize, numAreas, radius)
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

