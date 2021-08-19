function saveTif()

load('labels.mat','labels');
% sizeMask = size(labels);

% for i=1:sizeMask(1)
%     for j=1:sizeMask(2)
%         if labels(i,j) > 0
%             labels(i,j) = 1;
%         end
%     end
% end

labels = double(labels);

imwrite(labels,'mask.tif');

end

function graph() 

load('details.mat','details');
sizeCoord = size(details.coord);

figure
imshow('mask.tiff')
hold on
plot(details.points(:,2), details.points(:,1),'r.','MarkerSize', 10)
for j=1:sizeCoord(1)
    for i=1:sizeCoord(3)
        X(i) = details.coord(j,1,i);
        Y(i) = details.coord(j,2,i);
    end
    % plot(Y(:),X(:),'r.','MarkerSize', 10)
    for i=1:(sizeCoord(3)-1)
        plot([Y(i); Y(i+1)], [X(i); X(i+1)],'LineWidth',5)
    end
    plot([Y(sizeCoord(3)); Y(1)], [X(sizeCoord(3)); X(1)],'LineWidth',5)
end
hold off

end