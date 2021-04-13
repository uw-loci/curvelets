function intersectionPoint3 = lineIntersection(Xaip, Faip)

% this function runs through all the fibers and find the intersection
% points by using the built-in function

sizeF = size(Faip);
intersectionPoints = zeros(0,3);

for i = 1:sizeF(2)
    for j = 1:sizeF(2)
        if i == j
            continue
        end
        intersectionTemp = lineSegmentIntersection(Faip(i), Faip(j), Xaip);
        intersectionPoints = [intersectionPoints; intersectionTemp];
    end
end

intersectionPoint3 = intersectionPoints;



