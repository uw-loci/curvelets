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
        formFactor
        eccentricity
        solidity
        extent
        orientation
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
            obj.formFactor = 4*pi*area / (perimeter.^2);
            obj.eccentricity = minorAxis / majorAxis;
            
            
            obj.solidity = calculateSolidity(index, area);
            obj.extent = calculateExtent(index, area);
            obj.orientation = calculateOrientation(index);
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

function solidity = calculateSolidity(index, area)

load('details.mat','details');

coord = details.coord(index,:,:);
sizePolygon = size(coord);

for i=1:sizePolygon(3)
    X(i) = coord(1,1,i);
    Y(i) = coord(1,2,i);
end

convexHullArea = polyarea(X,Y);

solidity = convexHullArea / area;

end

function extent = calculateExtent(index, area)

load('details.mat','details');

coord = details.coord(index,:,:);
sizePolygon = size(coord);

minX = coord(1,1,1);
minY = coord(1,2,1);
maxX = 0;
maxY = 0;

for i=1:sizePolygon(3)
    X = coord(1,1,i);
    Y = coord(1,2,i);
    if X < minX
        minX = X;
    end
    if X > maxX
        maxX = X;
    end
    if Y < minY
        minY = Y;
    end
    if Y > maxY
        maxY = Y;
    end
end

sideX = maxX - minX;
sideY = maxY - minY;

boundingBoxArea = sideX * sideY;
extent = area / boundingBoxArea;

end

function orientation = calculateOrientation(index)


load('details.mat','details');

coord = details.coord(index,:,:);
sizePolygon = size(coord);

for i=1:sizePolygon(3)
    X(i) = coord(1,1,i);
    Y(i) = coord(1,2,i);
end

pe = pyenv;

pathToRect = fileparts(which('findAxisPoints.py'));
if count(py.sys.path,pathToRect) == 0
    insert(py.sys.path,int32(0),pathToRect);
end


py.findAxisPoints.findRectPoints(X, Y);

load('rect.mat','rect');

if ((rect(2,1)-rect(1,1))^2 + (rect(2,2)-rect(1,2))^2) > ((rect(3,1)-rect(2,1))^2 + (rect(3,2)-rect(2,2))^2)
    P1 = [rect(1,1) rect(1,2)];
    P2 = [rect(2,1) rect(2,2)];
else
    P1 = [rect(2,1) rect(2,2)];
    P2 = [rect(3,1) rect(3,2)];
end


orientation = atan((P2(2)-P1(2))/(P2(1)-P1(1))) * 180/pi;

end
