function showAll(img)
% This function draws boundaries of nuclei on the original H&E image
% img - the original H&E image

load('details_sd.mat','details');
szCells = size(details.coord);

imshow(img);
hold on
for i=1:szCells(1)
    plot(details.points(i,2),details.points(i,1),'r.','MarkerSize', 5);
    X = [];
    Y = [];
    for j=1:szCells(3)
        X = [X details.coord(i,1,j)];
        Y = [Y details.coord(i,2,j)];
    end
    pgon = polyshape(Y,X);
    plot(pgon,'FaceColor','none','EdgeColor','red');
end
hold off


end