function [int_point,intersect,count] = findInt(mat,group_angle)

intersect = mat+group_angle;
[row,col] = find(mat);
boundary = [row';col'];
goto = size(boundary);
count = 1;
for ii = 1:goto(2)
    if (intersect(boundary(1,ii),boundary(2,ii))-max(max(group_angle)))>0
    int_point(count,:) = [boundary(1,ii),boundary(2,ii)];
    count = count + 1;
    else 
    continue
    end
end

if count == 1
    int_point = 0;
end
