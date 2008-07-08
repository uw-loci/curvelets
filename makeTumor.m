function [mat] = makeTumor(group_angle)

mat = zeros(512);
x = max(max(group_angle))*ones(300,1);
mat(100:399,100) = x;
mat(100,100:399) = x';
mat(100:399,399) = x;
mat(399,100:399) = x';