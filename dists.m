function d = dists(x,y)

% dists.m
% This function finds the distance between curvelet centers
% 
% Carolyn Pehlke, Laboratory for Optical and Computational Instrumentation, July 2010

for bb = 1:length(x)
    for cc = bb:length(y)
        dd(cc) = sqrt((x(bb,1) - y(cc,1))^2 + (x(bb,2) - y(cc,2))^2);
    end
    if bb > 1
    dd(1:bb-1) = 5000;
    end
    d{bb} = dd;
    dd = [];
end