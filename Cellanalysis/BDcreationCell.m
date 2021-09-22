function BDcreationCell(num)

load('details.mat','details');
data = details.points;
data = double(data);

rng(1); % For reproducibility
[idx,C] = kmeans(data,num);

sizeAreas = zeros(1,num);

tumors = tumorBD.empty(num,0);

for i=1:length(idx)
    for j=1:num
        if idx(i) == j
            sizeAreas(j) = sizeAreas(j) + 1;
        end
    end
end

for i=1:num
    X = [];
    Y = [];
    for j=1:length(idx)
        if idx(j) == i
            sizePolygon = size(details.coord);
            for k=1:sizePolygon(3)
                X = [X; details.coord(j,1,k)];
                Y = [Y; details.coord(j,2,k)];
            end
        end
    end
    X = ceil(X);
    Y = ceil(Y);
    k = boundary(X,Y);
    tumors(i) = tumorBD();
    tumors(i).BD_X = X(k);
    tumors(i).BD_Y = Y(k);
    tumors(i).sizeBD = sizeAreas(i);
end

imshow('2B_D9_ROI1 copy.tif');
hold on
for i=1:num
    plot(tumors(i).BD_Y,tumors(i).BD_X,'LineWidth',5)
end
hold off

end