classdef wholeCellCard
    
    properties
<<<<<<< HEAD
=======
        Position
>>>>>>> 0d2c501c7373e2abce7ba9698c599f5f276dd975
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
<<<<<<< HEAD
        function obj = wholeCellCard(imgName,boundary,Area,Circularity,ConvexArea,...
                Eccentricity,Extent,MajorAxisLength,MinorAxisLength,Orientation,...
                Perimeter)
            obj.imgName = imgName;
            obj.Boundary = boundary;
=======
        function obj = wholeCellCard(imgName,Position, Boundary, Area,Circularity,ConvexArea,...
                Eccentricity,Extent,MajorAxisLength,MinorAxisLength,Orientation,...
                Perimeter)
            obj.imgName = imgName;
            obj.Position = Position;
            obj.Boundary = Boundary;
>>>>>>> 0d2c501c7373e2abce7ba9698c599f5f276dd975
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

