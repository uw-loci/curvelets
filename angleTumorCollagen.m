% Find the angle between tumor and collagen

function angleTumorCollagen(img)

% this gets the user defined hull from the figure window.
hull = get(gcf,'userdata');
%hull = [0,1000;100,0];

% take curvelet transform
C = fdct_wrapping(img,1,2,7,32);

%set the low pass filter coefficients to zero
C{1}{1} = zeros(size(C{1}{1}));

% make edges zero
C_indent = pixel_indent(C,2);

% get center position of each curvelet
center_pos = findPos(C_indent);

% get the angles for curvelets
angles = collAngle(C_indent);

% group the centers together
centers = groupCenter(center_pos);

% make the centers into vectors
[x,y] = centerPlot(centers);

% disreguard the curvelets "too" far away from the center
hh = findobj(gcf,'Tag','dist');

dist_micron = str2num(get(hh,'String'));

HH = findobj(gcf,'Tag','micron');

microns = str2num(get(HH,'String'));

% checks to see if dist_max is empty
if isempty(dist_micron)
    dist_flag = 1;
else
    dist_flag = 0;
end

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
                temp_angle = angleLine2(center, angle, hull);
                if strcmp(temp_angle,'none')
                    angle_tumor{ii}(jj) = -100;
                else
                    angle_tumor{ii}(jj) = temp_angle;
                end
                
            end
        end
    waitbar(ii/length(centers),h);
    end
else
    % convert distance into pixel amount
    img_sz = size(img);
    wid = img_sz(2);
    dist_max = wid/microns * dist_micron;
    centers_x = dropFar(centers,hull,dist_max);
    [xx,yy] = centerPlot(centers_x);   
    figure(1);plot(yy,xx,'yd');   
    for ii = 1:length(centers_x)
        goto = size(centers_x{ii});
        if goto(2) ==0;
            continue
        else
            for jj = 1:goto(2);
                center = [centers_x{ii}(1,jj),centers_x{ii}(2,jj)];
                angle = angles{ii};
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
angle_vec = angle_vec(find(angle_vec>=0));
length(angle_vec)
%export angle_vec to text file
%dlmwrite('angles',angle_vec);


%export angle_vec to text file
%dlmwrite('angles',angle_vec);


figure;
hist(angle_vec,9);

mean_angle = mean(angle_vec)
std_angle = std(angle_vec)

mean_angle_no_zero = mean(angle_vec(find(angle_vec~=0)))
std_angle_no_zero = std(angle_vec(find(angle_vec~=0)))


