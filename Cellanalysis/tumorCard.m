classdef tumorCard
    %TUMORCARD Summary of this class goes here
    %   Detailed explanation goes here
    
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

