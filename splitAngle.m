%% Scale different angles in the image different colors

function [group_angle] = splitAngle(img_cell)
% Divide up the coefficients into seperate angles

% Find the number of angles 
for ii = 1:length(img_cell)
    len(ii) = length(img_cell{ii});
end
[maxLen,ind] = max(len);

% Find what the angles of collagen are
for ii = 1:length(img_cell)
    for jj = 1:length(img_cell{ii})
    if length(img_cell{ii})~=1;
        angle_vec(jj) = 45 - ((jj-1)*360/length(img_cell{ii}));
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

% only want the first half
for ii = 1:length(angles)
    angles_temp{ii} = angles{ii}(1:end/2)
end

% Initialize Cell
group_angle = cell(maxLen/2,1);

% Fill in the angles
for ii = 1:length(group_angle)
    group_angle{ii}{2} = angles_temp{ind}(ii);
end

% Assign which coarseness to start with (maybe a good idea to start with 3)
start = 2;

% Group angles together

for ii = start:length(img_cell)-1    
    skip = maxLen/length(img_cell{ii});
    for jj = 1:skip:maxLen/2        
        angle_add = img_cell{ii}{ceil(jj/skip)} + img_cell{ii}{ceil(jj/skip)+length(img_cell{ii})/2};        
        if isempty(group_angle{jj}{1})==1
            group_angle{jj}{1} = angle_add;
        else
            group_angle{jj}{1} = group_angle{jj}{1} + angle_add;
        end
    angle_add = 0;
    end
end

% Threshold
for ii = 1:length(group_angle)
    val(ii) = max(max(group_angle{ii}{1}));
end

maxVal = max(val);

for ii = 1:length(group_angle)
    group_angle{ii}{1} = group_angle{ii}{1}.*(group_angle{ii}{1} > .25*maxVal);
end







