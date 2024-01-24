function fiberArray = deduceStraightPoints(Fa, Xa, intersection)

% This function deduce nucleation points that are in a straight line in one
% fiber, so that when running intersection analysis, there will be fewer
% intersection points in overlapping areas

if intersection ~= Inf
    sizePoints = size(intersection);
    countByOne = 1:1:sizePoints(1);
    i = 1;
    while i < sizePoints(1) - 2
        C = testFollowingPoints(countByOne, i, 3, intersection);
        if C > 3
            for k = 1:(C-3)
                countByOne(i+k) = countByOne(i+k)/0;
            end
        end
        i = i + C - 2;
    end
    count = 0;
    for i = 1:sizePoints(1)
        if countByOne(i) ~= Inf
            count = count + 1;
        end
    end
    fiberArray = zeros(count,3);
    count = 1;
    for i = 1:sizePoints(1)
        if countByOne(i) ~= Inf
            fiberArray(count,1) = intersection(countByOne(i), 1);
            fiberArray(count,2) = intersection(countByOne(i), 2);
            fiberArray(count,3) = intersection(countByOne(i), 3);
            count = count + 1;
        end
    end
else
    sizeF = size(Fa);
    for i = 1:sizeF(2)
        sizeFiber = size(Fa(i).v);
        j = 1;
        while j < sizeFiber(2) - 2
            C = testFollowingPoints(Fa(i).v, j, 3, Xa);
            if C > 3
                for k = 1:(C-3)
                    Fa(i).v(j+k) = Fa(i).v(j+k)/0;
                end
            end
            j = j + C - 2;
        end
    end
    
    for i = 1:sizeF(2)
        sizeFiber = size(Fa(i).v);
        count = 0;
        for j = 1:sizeFiber(2)
            if Fa(i).v(j) ~= Inf
                count = count + 1;
            end
        end
        fiberArray(i).v = zeros(1,count);
        count = 1;
        for j = 1:sizeFiber(2)
            if Fa(i).v(j) ~= Inf
                fiberArray(i).v(count) = Fa(i).v(j);
                count = count + 1;
            end
        end
    end
end

end

function C = testFollowingPoints(fiber, i, C, Xa)

a1 = Xa(fiber(i),1:3);
a2 = Xa(fiber(i+1),1:3);
a3 = Xa(fiber(i+C-1),1:3);
if testCollinear(a1, a2, a3)
    C = C + 1;
    if size(fiber) >= (i+C-1)
        testFollowingPoints(fiber, i, C, Xa)
    end
end
end

function boo = testCollinear(a1, a2, a3)
if abs((a2(2)-a1(2))/(a2(1)-a1(1)) - (a3(2)-a1(2))/(a3(1)-a1(1))) < 1
    boo = 1;
elseif a1(1) == a2(1) && a2(1) == a3(1)
    boo = 1;
else 
    boo = 0;
end

end

