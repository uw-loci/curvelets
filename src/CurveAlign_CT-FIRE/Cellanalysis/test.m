function test()

load('cells.mat','cells')
T = readtable('VAMPIRE datasheet mask.tif.csv','NumHeaderLines',1);
sizeTable = size(T);
sizeCells = size(cells);

T3 = T.(3);
T = T.(8); % change this to test other things (from VAMPIRE)

x = 1:1:sizeCells(2);

countT3 = 1;
for i=1:sizeCells(2)
    y1(i) = cells(i).majorAxis; % change this to test other things (from MatLab)
    if T3(countT3)==i
       y2(i) = T(countT3);
       countT3 = countT3 + 1;
    else
       y2(i) = 0;
    end
end

sz = 10;
figure
hold on
plot(x,y1,'r',x,y2,'g')
scatter(x,y1,sz,'r')
scatter(x,y2,sz,'g')
hold off

end