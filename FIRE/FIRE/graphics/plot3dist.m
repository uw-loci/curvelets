function[] = plot3dist(d,ms,pau,view)
if ~iscell(d)
    D{1} = d;
else
    D    = d;
end
if nargin<2
    ms = 1;
end
if nargin<3
    pau=.2;
end
if nargin<4
    view =    [-4.1920   75.3891];
end

for j=1:length(D)
    d = D{j};
    d = round(d);
    imax = max(d(:));
    imin = 1;

    colormap default
    col = colormap;

    icol = ceil( (imin:imax)*64/imax );

    for i=imax:-1:imin
        ind = find(d==i);
        [z y x] = ind2sub(size(d),ind);
        h = plot3(x,y,z,'.','Color',col(icol(i),:),'MarkerSize',ms*i);
        %set(gca,'View',view);
        hold on
        %pause(pau)
    end
    pause(pau)
end

xlabel('X')
ylabel('Y')
zlabel('Z')