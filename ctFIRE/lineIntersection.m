function intersectionPoint3 = lineIntersection(Xaip, Faip)

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
        intersectionPoints = [intersectionPoints; intersectionTemp];
    end
end

intersectionPoint3 = intersectionPoints;



