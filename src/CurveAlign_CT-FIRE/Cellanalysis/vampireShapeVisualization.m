function vampireShapeVisualization()

% This function shows the shapes that VAMPIRE program categorizes the cells
% into. It can be ran by running vampireShapeVisualization() on the command
% window or calling vampireShapeVisualization(). xaxis.mat and yaxis.mat
% are needed. Both files will be produced by running VAMPIRE program, and
% VAMPIRE program is ran by nuclei segmentation, which is imageCard.m.

load('xaxis.mat','xaxis');
load('yaxis.mat','yaxis');

sizePoints = size(xaxis);

x0=100;
y0=100;
width=1200;
height=120;


figure
hold on
title('VAMPIRE shapes')
for i=1:sizePoints(1)
    for j=1:sizePoints(2) - 1
        plot([xaxis(i,j),xaxis(i,j+1)], [yaxis(i,j),yaxis(i,j+1)],'LineWidth',3,'Color','Red')
    end
    text(xaxis(i,37),yaxis(i,37)-1,""+i,'FontSize',14);
end
set(gcf,'position',[x0,y0,width,height])
axis image
axis off
hold off

end