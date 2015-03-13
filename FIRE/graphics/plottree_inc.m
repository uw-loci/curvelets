function[] = plottree_inc(t,inc,colormat,lw);
%PLOTTREE_INC - plots an incremental bit of a tree

if nargin<3
    colormat = [0 0 0];
end
if nargin<4
    lw = 3;
end

ncol = size(colormat,1);

k=0;
hold on

for i=inc   
    icol = mod(t(i).treenum-1,ncol)+1;
    col  = colormat(icol,:);

    %draw parent just to be "safe"
    if t(i).parent > 0
        p = t(i).pos;
        ip = t(i).parent;
        q = t(ip).pos;
        P = [p; q];
        h = plot3(P(:,1),P(:,2),P(:,3));
        set(h,'Color',col,'LineWidth',lw)
    end
    if isfield(t(i),'children')
        p = t(i).pos;
        for j=1:length(t(i).children);
            c = t(i).children(j);
            q = t(c).pos;            
            P = [p; q];
            h = plot3(P(:,1),P(:,2),P(:,3));
            set(h,'Color',col,'LineWidth',lw);
        end
    end 
end