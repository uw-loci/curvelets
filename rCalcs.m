function rCalcs(hVector,vVector)%(hVector1,hVector2,hVector3,vVector1,vVector2,vVector3)
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
                
    if vVector(gg) < 90 && hVector(gg) >= 90 
        
        cVector(gg) = 180 - hVector(gg);
        
    elseif vVector(gg) <= 90 && hVector(gg) <= 90  && hVector(gg) > vVector(gg)
        
        cVector(gg) = 180 - hVector(gg);
        
    elseif vVector(gg) >= 90 && hVector(gg) < 90 
        
        cVector(gg) = vVector(gg) - 90;
        
    elseif vVector(gg) <= 90 && hVector(gg) <= 90 && hVector(gg) < vVector(gg)
        
        cVector(gg) = vVector(gg) + 90;
        
    elseif vVector(gg) == hVector(gg) && hVector(gg) ~= 0
        
        cVector(gg) = 180 - hVector(gg);
        
    else
        
        cVector(gg) = -1000;
        
    end
    
end

cVector = cVector(find(cVector>=0));

%creates angle bins in radians and degrees, centers at n*90/16
  bins = [0:90/32:180];
  binRads = deg2rad(bins);
   
  cCounts = hist(cVector,bins);
  cRadCounts = hist(deg2rad(cVector),binRads);

%mean angle, circular standard deviation, resultant vector (r-value) and
%Rayleigh's p-value

%x and y components of each angle bin
cSinVec = sind(bins).*cCounts;
cCosVec = cosd(bins).*cCounts;



%x and y components of resultant
cSin = sum(cSinVec);
cCos = sum(cCosVec);

%mean angle of distribution
theta = atand(cSin/cCos);

if theta < 0 
    theta = 180 + theta;
end

theta = abs(theta - refAngle);

%mode angle of distribution
modeAngle = mode(cVector);

%Resultant, normalized and scaled for range limited to 0-180 degrees, 1 =
%completely aligned in direction of mean, 0 = completely random
Resultant = abs(.3631 - sqrt(cSin^2+cCos^2)/sum(cCounts))/.6369;

%standard deviation (in degrees)
cStd = rad2deg(sqrt(2*(1-Resultant)));

%Rayleigh's test p-value
% pValue = circ_rtest(Resultant, cRadCounts);

%feather plot
% figure;
% feather(cCosVec,cSinVec);
%angle histogram
figure;
bar(bins,cCounts);
%output display
figure ('Name','Results');

subplot(4,2,1:6);
rose(deg2rad(cVector),64);
title('Angles');

subplot(4,2,7:8)
set(gca,'Visible','off');
results1 = text(0,1,['Strength of Alignment: \bf',num2str(Resultant,'%6.4f')]);
set(results1,'FontName','FixedWidth','FontSize',16);
results2 = text(0,.75,['Mean Angle With Respect to Reference: \bf',num2str(theta,'%6.2f'),'\circ']);
set(results2,'FontName','FixedWidth','FontSize',16);
results3 = text(0,.5,['Mode: \bf',num2str(modeAngle,'%6.2f'),'\circ']);
set(results3,'FontName','FixedWidth','FontSize',16);
results4 = text(0,.25,['Standard Deviation:\bf ',num2str(cStd,'%6.2f'),'\circ']);
set(results4,'FontName','FixedWidth','FontSize',16);
% results5 = text(0,0,['Rayleigh\primes p-value: \bf',num2str(pValue,'%6.4f')]);
% set(results5,'FontName','FixedWidth','FontSize',16);


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

