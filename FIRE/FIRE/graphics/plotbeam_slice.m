function[] = plotbeam_slice(X0,F,z1,z2,lw)
%PLOTBEAM_SLICE - plots the beams that pass through a z-slice

if nargin < 5
    lw = 2;
end

rand('seed',0);
hold on
for i=1:length(F)
    if isstruct(F)
        v = F(i).v;
        col = rand(3,1)*.75;
    else
        v = F(i,:);
        col = [1 1 .5];
    end
    [x,y,z] = plotbeam(X0(v,:));
    zind = find(z>z1 & z<z2);
    dzind= diff(zind);
    
    ii   = find(dzind==1);
    for j=1:length(x)-1
        if z(j) > z1 & z(j) < z2 & z(j+1) > z1 & z(j+1) < z2
            h = line([x(j) x(j+1)],[y(j) y(j+1)]);
            set(h,'Color',col,'LineWidth',lw);
            1;            
        end
    end
end
    
    
    
    