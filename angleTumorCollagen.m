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

% make the centers into plottable vectors

[x,y] = centerPlot(centers);

% disreguard the curvelets "too" far away from the center

hh = findobj(gcf,'Tag','dist');

dist_micron = str2num(get(hh,'String'));

% checks to see if dist_max is empty

if isempty(dist_micron)
    dist_flag = 1;
else
    dist_flag = 0;
end

% convert distance into pixel amount

img_sz = size(img);

wid = img_sz(2);

HH = findobj(gcf,'Tag','micron');

microns = str2num(get(HH,'String'));

dist_max = wid/microns * dist_micron;

centers_x = dropFar(centers,hull,dist_max);

[xx,yy] = centerPlot(centers_x);

% calculate angles
angle_tumor = cell(32,1);

h = waitbar(0,'Computing');
if dist_flag == 1;
    figure(1);plot(y,x,'yd');
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
else
    figure(1);plot(yy,xx,'yd');
for ii = 1:length(centers_x)
    goto = size(centers_x{ii});
    if goto(2) ==0;
        continue
    else
        for jj = 1:goto(2);
        center = [centers_x{ii}(1,jj),centers_x{ii}(2,jj)];
        angle = angles{ii};
       % hull = [100 100;100 399;399 399;399 100]; % this is user defined
        angle_tumor{ii}(jj) = angleLine(center, angle, hull);
        end
    end
    waitbar(ii/length(centers_x),h);
end
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
hist(angle_vec,9);

mean_angle = mean(angle_vec)
std_angle = std(angle_vec)

mean_angle_no_zero = mean(angle_vec(find(angle_vec~=0)))
std_angle_no_zero = std(angle_vec(find(angle_vec~=0)))


