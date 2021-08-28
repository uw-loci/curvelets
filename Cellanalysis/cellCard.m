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
            obj.eccentricity = sqrt(majorAxis^2-minorAxis^2) / majorAxis;
            
            
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

solidity = area / convexHullArea;

end

function extent = calculateExtent(index, area)

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

load('rect.mat','rect');

py.findAxisPoints.findRectPoints(X, Y);

X1 = rect(1,1);
X2 = rect(2,1);
X3 = rect(3,1);
Y1 = rect(1,2);
Y2 = rect(2,2);
Y3 = rect(3,2);

sideX = sqrt((X2 - X1)^2 + (Y2 - Y1)^2);
sideY = sqrt((X3 - X2)^2 + (Y3 - Y2)^2);


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


py.findAxisPoints.findRectPoints(Y, X);

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
