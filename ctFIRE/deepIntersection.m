function DeepIntersectionPoints = deepIntersection(Xdp, im, X)


XdpLength = size(Xdp);
XLength = size(X);
for i = 1:XdpLength(1)
    inteX = floor(Xdp(i,1));
    fractX = Xdp(i,1) - inteX;
    if fractX >= 0.5
        indeX = inteX + 1;
    else
        indeX = inteX;
    end
    inteY = floor(Xdp(i,2));
    fractY = Xdp(i,2) - inteY;
    if fractY >= 0.5
        indeY = inteY + 1;
    else
        indeY = inteY;
    end
    inteZ = floor(Xdp(i,3));
    fractZ = Xdp(i,3) - inteZ;
    if fractZ >= 0.5
        indeZ = inteZ + 1;
    else
        indeZ = inteZ;
    end
    Xdp(i,1) = indeX;
    Xdp(i,2) = indeY;
    Xdp(i,3) = indeZ;
end

sizeIMG = size(im);
count = zeros(sizeIMG(2)+1,sizeIMG(3)+1,sizeIMG(1)+1);

for i = 1:XdpLength(1)
    count(Xdp(i,1),Xdp(i,2),Xdp(i,3)) = count(Xdp(i,1),Xdp(i,2),Xdp(i,3)) + 1;
end
%for i = 1:XLength(1)
    %count(X(i,1),X(i,2),X(i,3)) = count(X(i,1),X(i,2),X(i,3)) - 1;
%end

numberOfPoints = 0;
for i = 1:sizeIMG(2)
    for j = 1:sizeIMG(3)
        for k = 1:sizeIMG(1)
            if count(i,j,k) > 1
                numberOfPoints = numberOfPoints + 1;
            end
        end
    end
end
intersectionPoints = zeros(numberOfPoints,3);
indexOfPointList = 1;
for i = 1:sizeIMG(2)
    for j = 1:sizeIMG(3)
        for k = 1:sizeIMG(1)
            if count(i,j,k) > 1
                intersectionPoints(indexOfPointList,1) = i;
                intersectionPoints(indexOfPointList,2) = j;
                intersectionPoints(indexOfPointList,3) = k;
                indexOfPointList = indexOfPointList + 1;
            end
        end
    end
end
DeepIntersectionPoints = intersectionPoints;
