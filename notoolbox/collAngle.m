% Find the number of angles 
function group_angle = collAngle(img_cell)

% This loop finds the longest length of any of the cells
for ii = 1:length(img_cell)
    len(ii) = length(img_cell{ii});
end

% finds the maximum length and where that lies
[maxLen,ind] = max(len);

% Find what the angles of collagen are
for ii = 2:length(img_cell)-1
    for jj = 1:length(img_cell{ii})
    if length(img_cell{ii})~=1;
        angle_vec(jj) = 45 - ((jj-1)*360/length(img_cell{ii})); % the curvlet always starts at 45 deg. 
        if angle_vec(jj)>0
            angle_vec(jj) = angle_vec(jj);
        else
            angle_vec(jj) = angle_vec(jj) + 360;
        end
    else
        angle_vec(jj) = 0;
    end
    end
    angles{ii} = angle_vec;
    angle_vec = 0;
end

% only want the first half.  The rest are redundant
for ii = 1:length(angles)
    angles_temp{ii} = angles{ii}(1:end/2);
end

% Initialize Cell
group_angle = cell(maxLen/2,1);

% Fill in the angles
for ii = 1:length(group_angle)
    group_angle{ii} = angles_temp{ind}(ii);
end