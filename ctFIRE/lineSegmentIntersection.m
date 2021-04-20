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
[xi,yi] = polyxpoly(x1,y1,x2,y2);

% put the resulting points into a matrix with x, y, and z coordinates
sizeInt = size(xi);
segmentIntersection = zeros(sizeInt(1),3);
for i = 1:sizeInt
    segmentIntersection(i,1) = xi(i,1);
    segmentIntersection(i,2) = yi(i,1);
    segmentIntersection(i,3) = 1;
end
    
    
