classdef cellCardInd
        
    properties
        position
        boundray
        area
        circularity
        convexArea
        eccentricity
        extent
        majorAxisLength
        minorAxisLength
        orientation
        perimeter
    end
    
    properties (Access=private)
        imgName
        index
    end
    
    methods
        function obj=cellCardInd(imgName,index,position,boundray,area,circularity,...
                convexArea,eccentricity,extent,majorAxisLength,minorAxisLength,...
                orientation,perimeter)
            obj.imgName = imgName;
            obj.index = index;
            obj.position = position;
            obj.boundray = boundray;
            obj.area = area;
            obj.circularity = circularity;
            obj.convexArea = convexArea;
            obj.eccentricity = eccentricity;
            obj.extent = extent;
            obj.majorAxisLength = majorAxisLength;
            obj.minorAxisLength = minorAxisLength;
            obj.orientation = orientation;
            obj.perimeter = perimeter;
        end
        
        function imgName=getImageName(obj)
            imgName = obj.imgName;
        end
        
        function index=getIndex(obj)
            index = obj.index;
        end
        
        function X=getX(obj)
            X = obj.position(1,1);
        end
        
        function Y=getY(obj)
            Y = obj.position(1,2);
        end
            
    end
    
end