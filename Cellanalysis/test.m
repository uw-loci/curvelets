function test(index)

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
extent = 317 / boundingBoxArea;

disp(extent)

end