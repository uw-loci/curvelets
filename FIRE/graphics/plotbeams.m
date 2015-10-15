function[] = plotbeams(X,A,F,lw,rseed,col,marker,pau)
%PLOTFIBER - plots the fibers
%plotbeams(X,A,F,lw,rseed,col,marker,pau)
if nargin < 4
    lw = 2;
end
if nargin < 5
    rseed = 0;
end

rflag = 0;
if nargin < 6
    rflag = 1;
    
end
if exist('col')
    if isempty(col)
        rflag = 1;
    end
end
if nargin < 7
    marker = 'none';
end

if nargin < 8
    pau = 0;
end

rand('seed',rseed);
hold on
for i=1:length(F)
    v = F(i).v;
    a = F(i).a;

    if rflag == 1
        col = rand(3,1)*.75;
    end
    
    [x,y,z] = plotbeam([X(v,:) A(a,:)]);
    plot3(x,y,z,'Color',col,'LineStyle','-','LineWidth',lw);
    plot3(X(v,1),X(v,2),X(v,3),'LineWidth',lw,'MarkerEdgeColor',col,'Marker',marker,'LineStyle','none');
    if length(v)>=3 & nargin >= 8
        pause(pau)
        ylabel(num2str(i))
    end
end
axis equal
    
    
    