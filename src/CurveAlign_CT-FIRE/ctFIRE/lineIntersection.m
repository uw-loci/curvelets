function intersectionPoint3 = lineIntersection(Xaip, im, Faip)

% This function runs through all the fibers and find the intersection
% points by using the built-in function.

% This function's big-O notation is O(n^2), where n represents the number
% of fibers in total.

sizeF = size(Faip);
IP = zeros(0,3);

% compare each fiber to all other fibers 
for i = 1:sizeF(2) 
    for j = 1:sizeF(2)
        % skip the pairs that has been compared or one fiber with itself
        if i >= j
            continue
        end
        intersectionTemp = lineSegmentIntersection(Faip(i), Faip(j), Xaip);
        if intersectionTemp ~= Inf
            IP = [IP; intersectionTemp];
        end
    end
end

% after calculate the segments, check the nucleation points, and if any of
% the nucleation points are used more than once, they are intersection
% points too. The segment function consider nucleation points as out of
% range.
intersectionPoints2 = intersection(Xaip, Faip);
IP = [IP; intersectionPoints2];

sizeIMG = size(im);
count = zeros(sizeIMG(3)+1,sizeIMG(2)+1,sizeIMG(1)+1);

% checks if there is any repeatation, and remove the extra points if there
% is any
intersectionLength = size(IP);
for i = 1:intersectionLength(1)
    IP(i,1) = round(IP(i,1));
    IP(i,2) = round(IP(i,2));
    IP(i,3) = round(IP(i,3));
    count(IP(i,1),IP(i,2),IP(i,3)) = count(IP(i,1),IP(i,2),IP(i,3)) + 1;
end
numberOfPoints = 0;
for i = 1:sizeIMG(3)
    for j = 1:sizeIMG(2)
        for k = 1:sizeIMG(1)
            if count(i,j,k) >= 1
                numberOfPoints = numberOfPoints + 1;
            end
        end
    end
end
IP = zeros(numberOfPoints,3);
indexOfPointList = 1;
for i = 1:sizeIMG(3)
    for j = 1:sizeIMG(2)
        for k = 1:sizeIMG(1)
            if count(i,j,k)>=1
                IP(indexOfPointList,1) = i;
                IP(indexOfPointList,2) = j;
                IP(indexOfPointList,3) = k;
                indexOfPointList = indexOfPointList + 1;
            end
        end
    end
end

% IP = combineRegions(IP, sizeIMG);

intersectionPoint3 = IP;

end

% function intersectionPoint = combineRegions(IP, sizeIMG)
% 
% length = size(IP);
% 
% for i = 1:length(1)
%     for j = 1:length(1)
%         if (IP(i,1)-IP(j,1))^2 + (IP(i,2)-IP(j,2))^2 < 25
%             IP(i,1) = round((IP(i,1)+IP(j,1))/2);
%             IP(i,2) = round((IP(i,2)+IP(j,2))/2);
%             IP(j,1) = IP(i,1);
%             IP(j,2) = IP(i,2);
%         end
%     end
% end
% 
% count = zeros(sizeIMG(3)+1,sizeIMG(2)+1,sizeIMG(1)+1);
% intersectionLength = size(IP);
% for i = 1:intersectionLength(1)
%     count(IP(i,1),IP(i,2),IP(i,3)) = count(IP(i,1),IP(i,2),IP(i,3)) + 1;
% end
% numberOfPoints = 0;
% for i = 1:sizeIMG(3)
%     for j = 1:sizeIMG(2)
%         for k = 1:sizeIMG(1)
%             if count(i,j,k) >= 1
%                 numberOfPoints = numberOfPoints + 1;
%             end
%         end
%     end
% end
% IP = zeros(numberOfPoints,3);
% indexOfPointList = 1;
% for i = 1:sizeIMG(3)
%     for j = 1:sizeIMG(2)
%         for k = 1:sizeIMG(1)
%             if count(i,j,k)>=1
%                 IP(indexOfPointList,1) = i;
%                 IP(indexOfPointList,2) = j;
%                 IP(indexOfPointList,3) = k;
%                 indexOfPointList = indexOfPointList + 1;
%             end
%         end
%     end
% end
% 
% intersectionPoint = IP;
% end
