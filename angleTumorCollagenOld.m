%% Find the angle between tumor and collagen
%close all;clear all;load img_add;

%function angleTumorCollagen(C,img_add)
%this will take in grouped angles as inputs and output histogram of angles
%relative to tumor

% Make the edges zero in all images to avoid wrapping

img_add = pixel_indent(img_add,20); %about 6 seconds

% Group all the same angles together reguardless of scale

group_angle = splitAngle(img_add);

% simulate tumor

for ii = 1:length(group_angle)
  
    tumor = makeTumor(group_angle{ii}{1});
  
    % figure out the intersection points.
  
    int_point = findInt(tumor,group_angle{ii}{1}); %two seconds each time
  
    % figure out the endpoints
    
    endpoints = extractEndpoints(int_point);
    if endpoints{1} ==0;
        continue
    end
   
    % figure out the angle between curvelets and tumor
   
    angle{ii} = findAngle(endpoints,group_angle{ii}{2});
  
end


count = 1;
% Remove empty_cells
for ii = 1:length(angle)
    if ~isempty(angle{ii})
        angle_cell{count} =angle{ii};
        count = count + 1;
    else 
        continue
    end
end

angle_vec = 0;
% make into vector
for ii = 1:length(angle_cell)
    temp =  angle_cell{ii};
    angle_vec = [angle_vec temp];
    temp = 0;
end

angle_vec = angle_vec(2:end);
hist(angle_vec,18)



