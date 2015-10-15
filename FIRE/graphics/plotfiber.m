function[] = plotfiber(X,F,lw,rseed,col,marker,col2,radiusflag)
%PLOTFIBER - plots the fibers
%plotfiber(X,F,lw,rseed,col,lintype,pau)
if isempty(F)
    fprintf('empty fiber array\n');
    return
end
if nargin==3 && isstruct(lw)
    opt = lw;
    if ~isfield(opt,'lw')
        lw = 2;
    else
        lw = opt.lw;
    end
    if ~isfield(opt,'rseed')
        rseed = 0;
    else
        rseed = opt.rseed;
    end
    if ~isfield(opt,'col')
        col = opt.col;
        rflag = 0;
    else
        rflag = 1;
    end
    if ~isfield(opt,'marker')
        marker = opt.marker
    else
        marker = 'none';
    end
    if ~isfield(opt,'col2')
        xlinkflag = 0;
        col2 = 'r';
    else
        xlinkflag = 1;
        col2 = opt.col2;
    end
    if ~isfield(opt,'radiusflag')
        radiusflag = 0;
    else
        radiusflag = opt.radiusflag;
    end
    
else    
    if nargin < 3
        lw = 2;
    end
    if nargin < 4
        rseed = 0;
    end

    rflag = 0;
    if nargin < 5
        rflag = 1;
    end
    if exist('col')
        if isempty(col)
            rflag = 1;
        end
    end
    if nargin < 6
        marker = 'none';
    end
    if nargin < 7
        xlinkflag = 0;
        col2 = 'r';
    else
        xlinkflag = 1;
    end
    if nargin < 8
        radiusflag = 0;
    end
end
if isfield(F,'r') & radiusflag == 1;
    for i=1:length(F)
        if isempty(F(i).r)
            r(i) = 0;
        else
            r(i) = F(i).r;
        end
    end
else
    r = ones(length(F),1);
end
rscale = (r+eps)/(mean(r)+eps);

rand('seed',rseed);
hold on
for i=1:length(F)
    if isstruct(F)
        f = F(i).v;
    else
        f = F(i,:);
    end

    if rflag == 1
        col = rand(3,1)*.75;
    end
    
    x = X(f,1);
    y = X(f,2);
    z = X(f,3);    
    plot3(x,y,z,'Color',col,'LineStyle','-','LineWidth',lw*rscale(i),'Marker',marker,'MarkerSize',6*rscale(i));
end

if xlinkflag == 1
    ii = zeros(size(X,1),1);
    [X F V] = trimxfv(X,F);
    for i=1:length(V)
        if length(V(i).f)>1
            ii(i) = 1;
        end
    end
    ind = find(ii==1);
    plot3(X(ind,1),X(ind,2),X(ind,3),'o','MarkerSize',12,'LineWidth',2,'Color',col2);
    plot3(X(ind,1),X(ind,2),X(ind,3),'k.','MarkerSize',4);
end
%axis equal
    
    
    