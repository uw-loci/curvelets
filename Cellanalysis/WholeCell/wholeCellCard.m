classdef wholeCellCard
    
    properties
        Boundary
        Area
        Circularity
        ConvexArea
        Eccentricity
        Extent
        MajorAxisLength
        MinorAxisLength
        Orientation
        Perimeter
    end
    
    properties (Access=private)
        imgName
    end
    
    methods
        function obj = wholeCellCard(imgName,boundary,Area,Circularity,ConvexArea,...
                Eccentricity,Extent,MajorAxisLength,MinorAxisLength,Orientation,...
                Perimeter)
            obj.imgName = imgName;
            obj.Boundary = boundary;
            obj.Area = Area;
            obj.Circularity = Circularity;
            obj.ConvexArea = ConvexArea;
            obj.Eccentricity = Eccentricity;
            obj.Extent = Extent;
            obj.MajorAxisLength = MajorAxisLength;
            obj.MinorAxisLength = MinorAxisLength;
            obj.Orientation = Orientation;
            obj.Perimeter = Perimeter;
        end
    end
end

