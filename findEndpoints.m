% get endpoints of a line using angle, center and length

% start with length 5,45 deg centered at (2,1)
angle = 45*pi/180;
leng = 5;
pos = [2 1];

x_coord = leng/2*cos(angle);
y_coord = leng/2*sin(angle);

end1(1) = pos(1)+x_coord;
end1(2) = pos(2)+y_coord;

end2(1) = pos(1)-x_coord;
end2(2) = pos(2)-y_coord;
