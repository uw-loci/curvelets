function test(index)

load('details.mat','details');

coord = details.coord(index,:,:);
sizePolygon = size(coord);

for i=1:sizePolygon(3)
    X(i) = coord(1,1,i);
    Y(i) = coord(1,2,i);
end

pe = pyenv;

% Recognize the path to the python code file
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


angle = atan((P2(2)-P1(2))/(P2(1)-P1(1))) * 180/pi;

end