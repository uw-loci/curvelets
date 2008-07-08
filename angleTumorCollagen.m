% Find the angle between tumor and collagen

function angleTumorCollagen(img)


hull = get(gcf,'userdata');

%smooth out the hull data

% hull(:,1) = movAve(hull(:,1));
% hull(:,2) = movAve(hull(:,2));

% take curvelet transform

C = fdct_wrapping(img,1);

C{1}{1} = zeros(size(C{1}{1}));

% make edges zero

C_indent = pixel_indent(C,2);

% get center position of each curvelet

center_pos = findPos(C_indent);

% get the angles for curvelets

angles = collAngle(C_indent);

% group the centers together

centers = groupCenter(center_pos);

% calculate angles
angle_tumor = cell(32,1);

h = waitbar(0,'Computing');
for ii = 1:length(centers)
    goto = size(centers{ii});
    if goto(2) ==0;
        continue
    else
        for jj = 1:goto(2);
        center = [centers{ii}(1,jj),centers{ii}(2,jj)];
        angle = angles{ii};
       % hull = [100 100;100 399;399 399;399 100]; % this is user defined
        angle_tumor{ii}(jj) = angleLine(center, angle, hull);
        end
    end
    waitbar(ii/length(centers),h);
end
close(h)
angle_vec = 0;
% make into vector
for ii = 1:length(angle_tumor)
        temp = angle_tumor{ii}; 
        angle_vec = [angle_vec temp];
        temp = 0;
end

angle_vec = angle_vec(2:end);
figure;
hist(angle_vec,9)


