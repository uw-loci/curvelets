function[] = plottree(t,colormat,lw,pau,plotinc);

if nargin<2
    colormat = [0 0 0];
end
if nargin<3
    lw = 4;
end
if nargin<4
    pau = 0;
end
if nargin<5
	plotinc = Inf;
end

hold on
k=0;
len = length(t);
colcounter = 0;
for i=1:len
    if mod(i,plotinc)==0
        pause(pau);
    end
    
    if isfield(t(i),'children')
        if t(i).parent == 0;
            colcounter=colcounter+1;
            ii = mod(colcounter-1,size(colormat,1))+1;
            col = colormat(ii,:);
        end
        p = t(i).pos;
        for j=1:length(t(i).children);
            c = t(i).children(j);
            q = t(c).pos;
            
            P = [p; q];
            h = plot3(P(:,1),P(:,2),P(:,3));
            k=k+1;
            set(h,'Color',col,'LineWidth',lw)
            %pause;          
        end
    end 
end