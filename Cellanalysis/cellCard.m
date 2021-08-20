classdef cellCard
        
    properties
        position
        boundray
        area
        perimeter
        majorAxis
        minorAxis
        circularity
        aspectRatio
        vampireShapeMode
        compactness
        eccentricity
    end
    
    properties (Access=private)
        imgName
        index
    end
    
    methods
        function obj=cellCard(imgName,index,position,boundray,area,perimeter,...
                majorAxis,minorAxis,circularity,aspectRatio,vampireShapeMode)
            obj.imgName = imgName;
            obj.index = index;
            obj.position = position;
            obj.boundray = boundray;
            obj.area = area;
            obj.perimeter = perimeter;
            obj.majorAxis = majorAxis;
            obj.minorAxis = minorAxis;
            obj.circularity = circularity;
            obj.aspectRatio = aspectRatio;
            obj.vampireShapeMode = vampireShapeMode;
            obj.compactness = 4*pi / (perimeter.^2);
            obj.eccentricity = minorAxis / majorAxis;
            
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
        
        function boundray=getBoundray(obj)
            boundray = obj.boundray;
        end
        
        function area=getArea(obj)
            area = obj.area;
        end
        
        function perimeter=getPerimeter(obj)
            perimeter = obj.perimeter;
        end
        
        function majorAxis=getMajorAxis(obj)
            majorAxis = obj.majorAxis;
        end
        
        function minorAxis=getMinorAxis(obj)
            minorAxis = obj.minorAxis;
        end
        
        function circularity=getCircularity(obj)
            circularity = obj.circularity;
        end
        
        function aspectRatio=getAspectRatio(obj)
            aspectRatio = obj.aspectRatio;
        end
        
        function vampireShapeMode=getVampireShapeMode(obj)
            vampireShapeMode = obj.vampireShapeMode;
        end
            
    end
    
end
