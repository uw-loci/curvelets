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
        end
        
        function imgName=getImageName(obj)
            imgName = obj.imgName;
        end
        
        function index=getIndex(obj)
            index = obj.index;
        end
            
    end
    
end
