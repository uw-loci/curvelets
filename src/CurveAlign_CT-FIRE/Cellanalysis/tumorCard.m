classdef tumorCard
    % The object of tumor, stores the boundary of tumor, the size (area),
    % and all the pixels.
    
    properties
        boundary
        area
        points
    end
    
    methods
        function obj = tumorCard(boundary, area, points)
            obj.boundary = boundary;
            obj.area = area;
            obj.points = points;
        end
    end
end

