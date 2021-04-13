function segmentIntersection = lineSegmentIntersection(F1, F2, Xa)

% This function takes two fibers and uses their interpolations to return 
% intersection points

sizeF1 = size(F1.v);
sizeF2 = size(F2.v);

x1 = zeros(sizeF1(2),1);
y1 = zeros(sizeF1(2),1);
x2 = zeros(sizeF2(2),1);
y2 = zeros(sizeF2(2),1);

for i = 1:sizeF1(2)
    x1(i) = Xa(F1.v(i),1);
    y1(i) = Xa(F1.v(i),2);
end

for i = 1:sizeF2(2)
    x2(i) = Xa(F2.v(i),1);
    y2(i) = Xa(F2.v(i),2);
end

[xi,yi] = polyxpoly(x1,y1,x2,y2);

sizeInt = size(xi);
segmentIntersection = zeros(sizeInt(1),3);
for i = 1:sizeInt
    segmentIntersection(i,1) = xi(i,1);
    segmentIntersection(i,2) = yi(i,1);
    segmentIntersection(i,3) = 1;
end
    
    
