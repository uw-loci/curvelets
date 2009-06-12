function [x_vec,y_vec] = centerPlot(centers)

x_vec = [];
y_vec = [];

%group x,y vectors
for ii = 1:length(centers)
    goto = size(centers{ii});
    if goto(2) ==0;
        continue
    else
    x_temp = centers{ii}(1,:);
    y_temp = centers{ii}(2,:);
    x_vec = [x_vec,x_temp];
    y_vec = [y_vec,y_temp];
    
    %initialize
    x_temp = 0;
    y_temp = 0;
    end
end

