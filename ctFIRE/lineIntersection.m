function intersectionPoint3 = lineIntersection(Xaip, im, Faip)

% This function runs through all the fibers and find the intersection
% points by using the built-in function.

% This function's big-O notation is O(n^2), where n represents the number
% of fibers in total.

sizeF = size(Faip);
intersectionPoints = zeros(0,3);

% compare each fiber to all other fibers 
for i = 1:sizeF(2) 
    for j = 1:sizeF(2)
        % skip the pairs that has been compared or one fiber with itself
        if i >= j
            continue
        end
        intersectionTemp = lineSegmentIntersection(Faip(i), Faip(j), Xaip);
        if intersectionTemp ~= Inf
            intersectionPoints = [intersectionPoints; intersectionTemp];
        end
    end
end

intersectionPoints2 = intersection(Xaip, Faip);
intersectionPoints = [intersectionPoints; intersectionPoints2];

sizeIMG = size(im);
count = zeros(sizeIMG(2)+1,sizeIMG(3)+1,sizeIMG(1)+1);

intersectionLength = size(intersectionPoints);
for i = 1:intersectionLength(1)
    intersectionPoints(i,1) = round(intersectionPoints(i,1));
    intersectionPoints(i,2) = round(intersectionPoints(i,2));
    intersectionPoints(i,3) = round(intersectionPoints(i,3));
    count(intersectionPoints(i,1),intersectionPoints(i,2),intersectionPoints(i,3)) = count(intersectionPoints(i,1),intersectionPoints(i,2),intersectionPoints(i,3)) + 1;
end

numberOfPoints = 0;
for i = 1:sizeIMG(2)
    for j = 1:sizeIMG(3)
        for k = 1:sizeIMG(1)
            if count(i,j,k) >= 1
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
            if count(i,j,k) >= 1
                intersectionPoints(indexOfPointList,1) = i;
                intersectionPoints(indexOfPointList,2) = j;
                intersectionPoints(indexOfPointList,3) = k;
                indexOfPointList = indexOfPointList + 1;
            end
        end
    end
end

intersectionPoint3 = intersectionPoints;



