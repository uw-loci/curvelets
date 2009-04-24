function rCalcs(hVector,vVector)
global reference

%checks if reference line is being used, if not measure from horizontal
if reference
api = iptgetapi(reference);
refAngle = api.getAngleFromHorizontal();
else
    refAngle = 0;
end

%sorts angle by quadrant and adjusts accordingly
for gg = 1:1:length(vVector)
                
    if vVector(gg) < 90 && hVector(gg) > 90 
        
        cVector(gg) = 180 - hVector(gg);
        
    elseif vVector(gg) < 90 && hVector(gg) < 90  && hVector(gg) > vVector(gg)
        
        cVector(gg) = 180 - hVector(gg);
        
    elseif vVector(gg) < 90 && hVector(gg) < 90 && vVector(gg)~= 0
        
        cVector(gg) = 90 + vVector(gg);
        
    elseif vVector(gg) > 90 && hVector(gg) < 90 
        
        cVector(gg) = vVector(gg) + 90;
        
    elseif vVector(gg) == 90 && hVector(gg) == 0 
        
        cVector(gg) = 180;
        
    elseif vVector(gg) == 0 && hVector(gg) == 90
        
        cVector(gg) = 0;
        
    elseif vVector(gg) == hVector(gg) && hVector(gg) ~= 0
        
        cVector(gg) = hVector(gg) + 90;
        
    else
        
        cVector(gg) = -1000;
        
    end
    
end

cVector = cVector(find(cVector>=0)) - refAngle;
if refAngle ~= 0
    for bb = 1:length(cVector)
        if cVector(bb) < 45
            cVector(bb) = cVector(bb) + 180;
        end
    end
end
cVector2 = cat(2,cVector,(180 + cVector)); %for graphing purposes only - no calculations use this

%creates angle bins in radians and degrees, centers at n*90/16
 bins = [45:90/32:227.8125];
 cCounts = hist(cVector,bins);

%mean angle of distribution
theta = mean(cVector); %must be positive
if theta < 0 
    theta = 180 + theta;
end

%mode and median of distribution
[C I] = max(cCounts);
modeAngle = bins(I);
medAngle = median(cVector);

%accounts for reference line
% theta = abs(theta - refAngle);
% modeAngle = abs(modeAngle - refAngle);
% medAngle = abs(medAngle - refAngle);


%RMS distance from median angle, 1 = completely aligned in direction of median, 0 = completely random

%x and y components of each angle bin vector
cSinVec = sind(cVector);
cCosVec = cosd(cVector);
sinMed = sind(medAngle); %sine of median angle
cosMed = cosd(medAngle); %cosine of median angle

for aa = 1:length(cVector)
    distVec(aa) = sqrt((sinMed - cSinVec(aa))^2 + (cosMed - cCosVec(aa))^2);
    if cVector2(aa+length(cVector)) > 360
        cVector2(aa+length(cVector)) = cVector2(aa+length(cVector)) - 360;
    else
        cVector2(aa+length(cVector)) = cVector2(aa+length(cVector));
    end
end
diffMed = 1 - sum(distVec)/length(cVector);

%standard deviation (in degrees)
cStd = std(cVector);

%output display
binRads = deg2rad([90/32:90/32:360]);
cRadCounts = hist(deg2rad(cVector2),binRads); 

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
results2 = text(0,.75,['Mean Angle With Respect to Reference: \bf',num2str(theta,'%6.2f'),'\circ']);
set(results2,'FontName','FixedWidth','FontSize',16);
results5 = text(0,.5,['Median Angle With Respect to Reference: \bf',num2str(medAngle,'%6.2f'),'\circ']);
set(results5,'FontName','FixedWidth','FontSize',16);
results3 = text(0,.25,['Mode: \bf',num2str(modeAngle,'%6.2f'),'\circ']);
set(results3,'FontName','FixedWidth','FontSize',16);
results4 = text(0,0,['Standard Deviation:\bf ',num2str(cStd,'%6.2f'),'\circ']);
set(results4,'FontName','FixedWidth','FontSize',16);


%export angles to text file
% fid = fopen('angles.txt', 'wt');
% fprintf(fid, '%6.2f\n', cVector);
% fclose(fid);
% % 
% fid = fopen('hVector.txt', 'wt');
% fprintf(fid, '%6.2f\n', hVector);
% fclose(fid);
% 
% fid = fopen('vVector.txt', 'wt');
% fprintf(fid, '%6.2f\n', vVector);
% fclose(fid);

