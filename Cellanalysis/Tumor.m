classdef Tumor
    
    properties
        imgName
        boundary
        cells
    end
    
    methods
        function obj = Tumor(imgName,boundary, cells)
            obj.imgName = imgName;
            obj.boundary = boundary;
            obj.cells = cells;
        end
    end
end

