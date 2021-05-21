function segmentIntersection = lineSegmentIntersection(F1, F2, Xa)

% This function takes two fibers and uses their interpolations to return 
% intersection points.

% This function's big-O notation is O(n), where n represents the sum of the
% interpolation points of two fibers.

% The built-in function, polyxpoly, finds intersection points by testing
% through "every possible pairing of one segment from curve a and one
% segment from curve b" (quoted from the description of polyxpoly). The
% essential calculation should have the big-O notation of O(n^2), where n
% is the total segments of the two fibers. 

sizeF1 = size(F1.v);
sizeF2 = size(F2.v);

% creates arrays of 0s that are the same size as fiber interpolation points
% arrays
x1 = zeros(sizeF1(2),1);
y1 = zeros(sizeF1(2),1);
x2 = zeros(sizeF2(2),1);
y2 = zeros(sizeF2(2),1);

% copy both fibers interpolation points into two separated arrays each, one
% only has x coordinates, one only has y
for i = 1:sizeF1(2) 
    x1(i) = Xa(F1.v(i),1);
    y1(i) = Xa(F1.v(i),2);
end

for i = 1:sizeF2(2)
    x2(i) = Xa(F2.v(i),1);
    y2(i) = Xa(F2.v(i),2);
end

% run built-in function
[xi,yi] = polyxy(x1,y1,x2,y2); % originally calls polyxpoly

% put the resulting points into a matrix with x, y, and z coordinates
if xi ~= Inf
    sizeInt = size(xi);
    segmentIntersection = zeros(sizeInt(1),3);
    for i = 1:sizeInt
        segmentIntersection(i,1) = xi(i,1);
        segmentIntersection(i,2) = yi(i,1);
        segmentIntersection(i,3) = 1;
    end
else
    segmentIntersection = Inf;
end
end

function [xi, yi] = polyxy(x1,y1,x2,y2)
size1 = size(x1);
size2 = size(x2);
mark = 0;
xi = double.empty;
yi = double.empty;
for i = 1:(size1-1)
    for j = 1:(size2-1)
        [x, y] = crossIntersection(x1(i),y1(i),x1(i+1),y1(i+1),x2(j),y2(j),x2(j+1),y2(j+1));
        if x ~= Inf
            xi = [xi x];
            yi = [yi y];
            mark = mark + 1;
        end
    end
end
if mark == 0
    xi = Inf;
    yi = Inf;
end
end

function [x, y] = crossIntersection(x11, y11, x12, y12, x21, y21, x22, y22)

m1 = (y12-y11)/(x12-x11);
n1 = y11-x11*m1;
m2 = (y22-y21)/(x22-x21);
n2 = y21-x21*m2;

if m1 == m2
    x = Inf;
    y = Inf;
else
    x = (n2-n1)/(m1-m2);
    y = m1*x+n1;
    y_test = m2*x+n2;
    if y ~= y_test
        x = Inf;
        y = Inf;
    end
    if (x < x11 && x < x12) || (x > x11 && x > x12)
        x = Inf;
        y = Inf;
    end
    if (x < x21 && x < x22) || (x > x21 && x > x22)
        x = Inf;
        y = Inf;
    end
    if (y < y11 && y < y12) || (y > y11 && y > y12)
        x = Inf;
        y = Inf;
    end
    if (y < y21 && y < y22) || (y > y21 && y > y22)
        x = Inf;
        y = Inf;
    end
end

end


