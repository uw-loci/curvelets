function[] = plotfiber_slice(X0,F,z1,z2,lw,rseed,colin)
%PLOTFIBER_SLICE - plots the fibers

if nargin < 5
    lw = 2;
end
if nargin<7
    colin = [];
end

rand('seed',0);
hold on
for i=1:length(F)
    if isstruct(F)
        v = F(i).v;
        if isempty(colin)
            col = rand(3,1)*.75;
        else
            col = colin;
        end
    else
        v = F(i,:);
        col = [1 1 .5];
    end
    x = X0(v,1);
    y = X0(v,2);
    z = X0(v,3);

    for j=1:length(x)-1
        if z(j) > z1 & z(j) < z2 & z(j+1) > z1 & z(j+1) < z2
            h = line([x(j) x(j+1)],[y(j) y(j+1)]);
            set(h,'Color',col,'LineWidth',lw);
            1;
            
        end
    end
end
    
    
    
    