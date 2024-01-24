function intersection = readJson(sizeIMG, jsonFile)

fid = fopen(jsonFile); 
rawData = fread(fid,inf); 
stringData = char(rawData'); 
fclose(fid); 
synfibersData = jsondecode(stringData);
fiberNumber = size(synfibersData.fibers,1);

for i = 1 : fiberNumber
    pointsFiber = size(synfibersData.fibers(i).points,1);
    % intialize x y vector for each fiber 
    F(i).xV = nan(pointsFiber,1);
    F(i).yV = nan(pointsFiber,1);
    for j = 1:pointsFiber
       F(i).xV(j) = synfibersData.fibers(i).points(j).x;
       F(i).yV(j) = synfibersData.fibers(i).points(j).y;
    end
end
intersection = synFiberIntersection(F, sizeIMG);

end


function intersectionGenerated = synFiberIntersection(F, sizeIMG)

sizeF = size(F);
intersectionPoints = zeros(0,3);

for i = 1:sizeF(2) 
    for j = 1:sizeF(2)
        % skip the pairs that has been compared or one fiber with itself
        if i >= j
            continue
        end
        [X, Y] = polyxpoly(F(i).xV, F(i).yV, F(j).xV, F(j).yV);
        sizeInt = size(X);
        segmentIntersection = zeros(sizeInt(1),3);
        for k = 1:sizeInt
            segmentIntersection(k,1) = X(k,1);
            segmentIntersection(k,2) = Y(k,1);
            segmentIntersection(k,3) = 1;
        end
        intersectionPoints = [intersectionPoints; segmentIntersection];
    end
end

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

intersectionGenerated = intersectionPoints;
end