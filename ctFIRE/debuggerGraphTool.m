function debuggerGraphTool(Fb, Xa, points)

% This tool can graph any amount of fibers in an orthogonal plane
% coordinate system. The nucleation points, Xa, will be marked as x in the
% system, and the fibers will be linked. To use this tool, first run an 
% analyzation and save Fa and Xa, and then determine which fibers need to 
% be tested, and then create an Fb in the command window by using: 
% Fb = [Fa(x) Fa(y) ...]
% assuming x y etc. are the indexes of those fibers. and then pass Xa and
% Fb to this method. The points parameter takes an array of points with x
% and y coordinates. If not needed, please pass a empty matrix.

sizeFa = size(Fb);

figure
hold on
for i = 1:sizeFa(2)
    sizeFiber = size(Fb(i).v);
    x = double.empty;
    y = double.empty;
    for j = 1:sizeFiber(2)
        index = Fb(i).v(j);
        x = [x Xa(index,1)];
        y = [y Xa(index,2)];
    end
    plot(x, y, '-x')
end
for i = 1:length(points)
    plot(points(:,1), points(:,2),'r.','MarkerSize', 10)
end
hold off

end