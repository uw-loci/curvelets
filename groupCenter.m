% Group centers together according to angle
function group_angle = groupCenter(img_cell)

for ii = 1:length(img_cell)
    len(ii) = length(img_cell{ii});
end
[maxLen,ind] = max(len);

group_angle = cell(maxLen/2,1);

for ii = 1:length(img_cell)   
    skip = maxLen/length(img_cell{ii});
    for jj = 1:skip:maxLen/2        
        angle_add = [img_cell{ii}{ceil(jj/skip)} , img_cell{ii}{ceil(jj/skip)+length(img_cell{ii})/2}];        
        if isempty(group_angle{jj})==1
            group_angle{jj} = angle_add;
        else
            group_angle{jj} = [group_angle{jj} , angle_add];
        end
    angle_add = 0;
    end
end