classdef imageCardTumor
    
    % Good parameter to try this:
    % imageCardTumor('2B_D9_ROI2 copy.tif','Radius',[50 50],30,50)
    % can change Radius to Thres or Rank
    % if using Rank , ('2B_D9_ROI2 copy.tif','Radius',[50 50],5,50)
    
    % This class requires the nuclei segmentation to be completed
    % beforehand. It annotate tumor regions and store the regions into
    % tumorCard objects. 
    % Parameters
    % img - The name of image, not used in any calculation steps.
    % method - Three methods are available: Rank, Thres, and Radius. Enter
    %   the string of any of the methods to activate. 
    % gridSize - It should be an array of two elements. For example, it can
    %   be [50 50]. It means to divide the length into 50 and width into
    %   50. The density will be calculated within these grids.
    % numAreas - If the method is 'Rank', numArea is the number of tumor
    %   regions that the image is expected to have; if the method is
    %   'Thres', numArea is the area threshold (if tumor regions are
    %   smaller than numArea, the tumor will be omitted. 
    % radius - If the method is 'Radius', the Qupath density map will
    %   activate and the density will be calculated not within each grid,
    %   but with each radius of the center of the grid. 
    
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

