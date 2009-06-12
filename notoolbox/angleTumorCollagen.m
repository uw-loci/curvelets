% Find the angle between tumor and collagen

function angleTumorCollagen(img)

% this gets the user defined hull from the figure window.
hull = get(gcf,'userdata');

% take curvelet transform
C = fdct_wrapping(img,1,2);

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

% calculate angles
angle_tumor = cell(32,1);

h = waitbar(0,'Computing');

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

%output 
angle_vec2 = cat(2,angle_vec,(180 + angle_vec)); %for graphing purposes only - no calculations use this

%creates angle bins in radians and degrees, centers at n*90/16
 bins = [45:5:225];
 cCounts = hist(angle_vec,bins);

%mean angle of distribution
theta = mean(angle_vec); %must be positive
if theta < 0 
    theta = 180 + theta;
end

%mode and median of distribution
[C I] = max(cCounts);
modeAngle = bins(I);
medAngle = median(angle_vec);

%RMS distance from median angle, 1 = completely aligned in direction of median, 0 = completely random

%x and y components of each angle bin vector
cSinVec = sind(angle_vec);
cCosVec = cosd(angle_vec);
sinMed = sind(medAngle); %sine of median angle
cosMed = cosd(medAngle); %cosine of median angle

for aa = 1:length(angle_vec)
    distVec(aa) = sqrt((sinMed - cSinVec(aa))^2 + (cosMed - cCosVec(aa))^2);
    if angle_vec2(aa+length(angle_vec)) > 360
        angle_vec2(aa+length(angle_vec)) = angle_vec2(aa+length(angle_vec)) - 360;
    else
        angle_vec2(aa+length(angle_vec)) = angle_vec2(aa+length(angle_vec));
    end
end
diffMed = abs(1 - sum(distVec)/length(angle_vec));

%standard deviation (in degrees)
cStd = std(angle_vec);

%output display

binRads = [90/32:90/32:360]*pi/180;
cRadCounts = hist(angle_vec2*pi/180,binRads); 

scrsz = get(0,'ScreenSize');

figure ('Name','Results','Position',[scrsz(3)/8 scrsz(4)/8 scrsz(3)*3/4 scrsz(4)*3/4]);

subplot(4,4,[1:2 5:6])
bar(bins,cCounts);
axis([45 max(bins) 0 C])
xlabel('Angle Bins, degrees')
ylabel('Magnitude, arbitrary units')
title('Angle Histogram')

subplot(4,4,[3:4 7:8 11:12])
polar(binRads,cRadCounts)
title('Angles')

subplot(4,4,14:15)
set(gca,'Visible','off');
results1 = text(0,1,['Strength of Alignment: \bf',num2str(diffMed,'%6.4f')]);
set(results1,'FontName','FixedWidth','FontSize',16);
results2 = text(0,.75,['Mean Angle With Respect to Boundary: \bf',num2str(theta,'%6.2f'),'\circ']);
set(results2,'FontName','FixedWidth','FontSize',16);
results3 = text(0,.5,['Median Angle With Respect to Boundary: \bf',num2str(medAngle,'%6.2f'),'\circ']);
set(results3,'FontName','FixedWidth','FontSize',16);
results4 = text(0,.25,['Mode: \bf',num2str(modeAngle,'%6.2f'),'\circ']);
set(results4,'FontName','FixedWidth','FontSize',16);
results5 = text(0,0,['Standard Deviation:\bf ',num2str(cStd,'%6.2f'),'\circ']);
set(results5,'FontName','FixedWidth','FontSize',16);


%export angles to text file
fid = fopen('angles.txt', 'wt');
fprintf(fid, '%6.2f\n', angle_vec);
fclose(fid);

