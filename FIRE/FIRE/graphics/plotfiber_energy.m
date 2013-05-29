function[] = plotfiber_energy(X,F,lwmax,EMAX,marker)
%PLOTFIBER_ENERGY - plots the fibers
%plotfiber(X,F,lw,rseed,col,lintype,pau)
lwmin = 1;
if isempty(F)
    fprintf('empty fiber array\n');
    return
end
if nargin < 3
    lwmax = 4;
end
if nargin < 4
    eflag = 0;
else
    eflag = 1;
end


colmat = [0 0 1; 1 0 0; .5 0 .5];

Emax = zeros(length(F),1);
colind=zeros(length(F),1);
for i=1:length(F)
    %calculating stretching, compressing, and bending energy in fibers
    E(i,1) = sum(F(i).Es);
    E(i,2) = sum(F(i).Ec);
    E(i,3) = sum(F(i).Eb);

    [Emax(i) colind(i)] = max(E(i,:));
end
if eflag == 0
    EMAX = max(E(:));
end

hold on
for i=1:length(F)
    v = F(i).v;
    
    x = X(v,1);
    y = X(v,2);
    z = X(v,3);
    
    lw = max(lwmin,lwmax*Emax(i)/EMAX);
    col = colmat(colind(i),:);
    
    plot3(x,y,z,'Color',col,'LineStyle','-','LineWidth',lw);
end
1;

    
    