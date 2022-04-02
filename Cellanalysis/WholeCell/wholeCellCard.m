classdef wholeCellCard
    
    properties
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
        function obj = wholeCellCard(imgName,Area,Circularity,ConvexArea,...
                Eccentricity,Extent,MajorAxisLength,MinorAxisLength,Orientation,...
                Perimeter)
            obj.imgName = imgName;
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

