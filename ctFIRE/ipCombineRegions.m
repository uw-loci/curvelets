function intersectionPoint = ipCombineRegions(IP, sizeIMG, distance)

% this method uses a distance, which is set by the user, to combine points
% that are closer to each other than the distance. The IP parameter is the
% array of points that are being combined, and the sizeIMG paramter is the
% size of the image.

length = size(IP);

% go through all the combination of points
for i = 1:length(1)
    for j = 1:length(1)
        % test the distnce
        if (IP(i,1)-IP(j,1))^2 + (IP(i,2)-IP(j,2))^2 < distance^2 
            IP(i,1) = round((IP(i,1)+IP(j,1))/2);
            IP(i,2) = round((IP(i,2)+IP(j,2))/2);
            IP(j,1) = IP(i,1);
            IP(j,2) = IP(i,2);
        end
    end
end

% checks if there is any repeatation, and remove the extra points if there
% is any
count = zeros(sizeIMG(3)+1,sizeIMG(2)+1);
intersectionLength = size(IP);
for i = 1:intersectionLength(1)
    count(IP(i,1),IP(i,2)) = count(IP(i,1),IP(i,2)) + 1;
end
numberOfPoints = 0;
for i = 1:sizeIMG(3)
    for j = 1:sizeIMG(2)
        if count(i,j) >= 1
            numberOfPoints = numberOfPoints + 1;
        end
    end
end
IP = zeros(numberOfPoints,2);
indexOfPointList = 1;
for i = 1:sizeIMG(3)
    for j = 1:sizeIMG(2)
        if count(i,j)>=1
            IP(indexOfPointList,1) = i;
            IP(indexOfPointList,2) = j;
            indexOfPointList = indexOfPointList + 1;
        end
    end
end

intersectionPoint = IP;
end
