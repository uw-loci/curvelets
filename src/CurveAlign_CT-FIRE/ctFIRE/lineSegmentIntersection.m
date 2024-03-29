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

% The function is no longer using the built-in function polyxpoly, but the
% new function polyxy essentially perform the same task.

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
    segmentIntersection = zeros(sizeInt(2),3);
    for i = 1:sizeInt(2)
        segmentIntersection(i,1) = xi(1,i);
        segmentIntersection(i,2) = yi(1,i);
        segmentIntersection(i,3) = 1;
    end
else
    segmentIntersection = Inf;
end
end

function [xi, yi] = polyxy(x1,y1,x2,y2)

% This function breaks two fibers into segments, and pass every combination
% of the segment pairs (one segment from each fiber) to crossIntersection
% function by passing the peak points of segments

size1 = size(x1);
size2 = size(x2);
mark = 0;
xi = double.empty;
yi = double.empty;
for i = 1:(size1-1)
    for j = 1:(size2-1)
        [xs, ys] = crossIntersection(x1(i),y1(i),x1(i+1),y1(i+1),x2(j),y2(j),x2(j+1),y2(j+1));
        if xs ~= Inf
            xi = [xi xs];
            yi = [yi ys];
            mark = mark + 1;
        end
%         if x1(i) == x2(j) && y1(i) == y2(j)
%             xi = [xi x1(i)];
%             yi = [yi y1(i)];
%             mark = mark + 1;
%         end
%         if x1(i) == x2(j+1) && y1(i) == y2(j+1)
%             xi = [xi x1(i)];
%             yi = [yi y1(i)];
%             mark = mark + 1;
%         end
%         if x1(i+1) == x2(j) && y1(i+1) == y2(j)
%             xi = [xi x1(i+1)];
%             yi = [yi y1(i+1)];
%             mark = mark + 1;
%         end
%         if x1(i+1) == x2(j+1) && y1(i+1) == y2(j+1)
%             xi = [xi x1(i+1)];
%             yi = [yi y1(i+1)];
%             mark = mark + 1;
%         end
    end
end
% [xo, yo] = overlappingIntersection(x1,y1,x2,y2);
% xi = [xi xo];
% yi = [yi yo];
if mark == 0 %& size(xo) == 0
    xi = Inf;
    yi = Inf;
end
end

function [x, y] = crossIntersection(x11, y11, x12, y12, x21, y21, x22, y22)

% This function calculate the intersection point of two straight segments.
% If the two segments do not intersect, it will return a coordinate of 
% infinity.

% first calculate the line function of each segments
if x12 == x11
    m1 = Inf;
else
    m1 = (y12-y11)/(x12-x11);
end
n1 = y11-x11*m1;
if x22 == x21
    m2 = Inf;
else
    m2 = (y22-y21)/(x22-x21);
end
n2 = y21-x21*m2;

% calculate the intersection of the two line functions
if m1 == m2
    x = Inf;
    y = Inf;
else
    if m1 == Inf
        x = x11;
        y = m2*x+n2;
    elseif m2 == Inf
        x = x21;
        y = m1*x+n1;
    else
        x = (n2-n1)/(m1-m2);
        y = m1*x+n1;
        y_test = m2*x+n2;
        if isnan(x) || isnan(y)
            x = Inf;
            y = Inf;
        elseif abs(y - y_test) > 0.000001
            x = Inf;
            y = Inf;
        end
    end
    % check if the calculated points are out of range of the segments
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


% function [xo, yo] = overlappingIntersection(x1,y1,x2,y2)
% 
% size1 = size(x1);
% size2 = size(x2);
% 
% xo = double.empty;
% yo = double.empty;
% 
% i = 1;
% while i <= size1(2)-1
%     mark = 0;
%     for j = 1:size2(2)
%         if j == size2(2)
%             if mark == 1
%                 if (x2(j) > x1(i) && x2(j) < x1(i+1)) || (x2(j) < x1(i) && x2(j) > x1(i+1))
%                     xo = [xo x2(j)];
%                     yo = [yo y2(j)];
%                 elseif (x1(i) > x2(j-1) && x1(i) < x2(j)) || (x1(i) < x2(j-1) && x1(i) > x2(j))
%                     xo = [xo x1(i)];
%                     yo = [yo y1(i)];
%                 end
%                 if i + 1 < size1(2)
%                     i = i + 1;
%                 end
%                 disp(i)
%             end
%             break
%         end
%         if overlap(x1(i),y1(i),x1(i+1),y1(i+1),x2(j),y2(j),x2(j+1),y2(j+1)) == 1
%             if mark == 0
%                 if (x1(i) > x2(j) && x1(i) < x2(j+1)) || (x1(i) < x2(j+1) && x1(i) > x2(j))
%                     xo = [xo x1(i)];
%                     yo = [yo y1(i)];
%                     disp(i)
%                     mark = 1;
%                 elseif (x2(j) > x1(i) && x2(j) < x1(i+1)) || (x2(j) < x1(i+1) && x2(j) > x1(i))
%                     xo = [xo x2(j)];
%                     yo = [yo y2(j)];
%                     mark = 1;
%                 end  
%             end
%             if mark == 1
%                 if i + 1 < size1(2)
%                     i = i + 1;
%                 else
%                     if (x1(i) > x2(j) && x1(i) < x2(j+1)) || (x1(i) < x2(j+1) && x1(i) > x2(j))
%                         xo = [xo x1(i)];
%                         yo = [yo y1(i)];
%                         mark = 0;
%                     elseif (x2(j) > x1(i) && x2(j) < x1(i+1)) || (x2(j) < x1(i+1) && x2(j) > x1(j))
%                         xo = [xo x2(j)];
%                         yo = [yo y2(j)];
%                         mark = 0;
%                     end
%                 end
%             end
%         else
%             if mark == 1
%                 if overlap(x1(i-1),y1(i-1),x1(i),y1(i),x2(j-1),y2(j-1),x2(j),y2(j)) == 1
%                     if (x1(i) > x2(j+1) && x1(i) < x2(j)) || (x1(i) < x2(j+1) && x1(i) > x2(j))
%                         xo = [xo x1(i)];
%                         yo = [yo y1(i)];
%                     elseif (x2(j) > x1(i+1) && x2(j) < x1(i)) || (x2(j) < x1(i+1) && x2(j) > x1(i))
%                         xo = [xo x2(j)];
%                         yo = [yo y2(j)];
%                     end
%                     mark = 0;
%                 end
%             end
%         end
%     end
%     i = i + 1;
% end
% 
% end
% 
% function bool = overlap(x11, y11, x12, y12, x21, y21, x22, y22)
% 
% m1 = (y12-y11)/(x12-x11);
% n1 = y11-x11*m1;
% m2 = (y22-y21)/(x22-x21);
% n2 = y21-x21*m2;
% 
% if m1 == m2 && n1 == n2
%     bool = 1;
% else
%     bool = 0;
% end
% end
