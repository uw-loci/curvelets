function angle = findAngle(endpoints,group_angle)

for ii = 1:length(endpoints)
    strait = [1 1;1,512];
    x1 = endpoints{ii}(1,1);
    x2 = endpoints{ii}(2,1);
    x3 = strait(1,1);   
    x4 = strait(2,1);
    y1 = endpoints{ii}(1,2);
    y2 = endpoints{ii}(2,2);
    y3 = strait(1,2);
    y4 = strait(2,2);

    angle_tumor = atan2(abs((x2-x1)*(y4-y3)-(x4-x3)*(y2-y1)),(x2-x1)*(x4-x3)+(y2-y1)*(y4-y3))*180/pi;
    angle1 = abs(angle_tumor) + group_angle;
    
    if angle1 > 360
        angle1 = angle1-360;
    end
    
    if angle1 < 90 & angle1 >0
        angle = angle1;
    elseif angle1 > 90 & angle1 <= 180
        angle1 = 180-angle1;
    elseif angle1 > 180 & angle1 <= 270
        angle1 = angle1-180;
    elseif angle1 > 270 & angle1 <= 360
        angle1 = 360 - angle1;
    end
    angle(ii) = angle1;
end

findanglerunning = 1

