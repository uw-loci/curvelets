classdef cellCardInd
        
    properties
        position
        boundray
        area
        circularity
        convexArea
        eccentricity
        extent
        majorAxis
        minorAxis
        orientation
        perimeter
        vampireShapeMode
        density
        closestDistance
        pixelDensity
    end
    
    properties (Access=private)
        imgName
        index
    end
    
    methods
        function obj=cellCardInd(imgName,index,position,boundray,area,circularity,...
                convexArea,eccentricity,extent,majorAxisLength,minorAxisLength,...
                orientation,perimeter,vampireShapeMode,density,closestDistance,...
                pixelDensity)
            obj.imgName = imgName;
            obj.index = double(index);
            obj.position = double(position);
            obj.boundray = boundray;
            obj.area = double(area);
            obj.circularity = circularity;
            obj.convexArea = double(convexArea);
            obj.eccentricity = eccentricity;
            obj.extent = extent;
            obj.majorAxis = majorAxisLength;
            obj.minorAxis = minorAxisLength;
            obj.orientation = double(orientation);
            obj.perimeter = double(perimeter);
            obj.vampireShapeMode = double(vampireShapeMode);
            obj.density = density;
            obj.closestDistance = closestDistance;
            obj.pixelDensity = pixelDensity;
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