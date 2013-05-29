function[p] = find1path(vstart,vend_indic,vavoid_indic,X,E,V,dir,plotflag)
%FIND1PATH - find a single path from vstart to any node in vendlist

if nargin<7
    dir = 1;
end
if nargin<8
    plotflag = 0;
end
visited    = zeros(length(V),1); %indicator list of visited nodes
p       = zeros(length(V),1);
hp      = p;

p(1)    = vstart; %current path we are traversing (starting from vstart)
level   = 1;
vcurr   = vstart;
visited(vstart) = 1;

if plotflag
    cla
    plotnetwork(X,E,'k',1,'-',3);
    h = plot3(X(vcurr,1),X(vcurr,2),X(vcurr,3),'ko','MarkerFaceColor','g');
    i1 = find(vend_indic==1);
    i2 = find(vavoid_indic==1);
    plot3(X(i1,1),X(i1,2),X(i1,3),'ks','MarkerFaceColor','k');
    plot3(X(i2,1),X(i2,2),X(i2,3),'m^','MarkerFaceColor','m');
end

while level ~= 0 && vend_indic(vcurr) == 0 %while we haven't gotten back to the start and we haven't reached an end node
    if plotflag
        set(h,'Marker','none')
        h = plot3(X(vcurr,1),X(vcurr,2),X(vcurr,3),'ko','MarkerFaceColor','g');
        pause(.001)
    end
    
    v     = V(vcurr).v;       %vertices connected to vcurr
    vnext = v(visited(v)==0 & vavoid_indic(v)==0); %   such taht they haven't been visited yet.        
    
    if isempty(vnext) %there are no more children, so go back one node, but keep the current node marked as visited
        if plotflag && level>1
            set(hp(level),'Color','r');
        end
        level = level-1;
        if level~=0
            vcurr = p(level);
        end        

        
    else %there's another child left to visit
        level = level+1;    %increase path level by one
        
        %choose the next node to the be point farthest along in the x direction
            x     = X(vnext,dir);
            [m jj]= max(x); %choose point that is farthest in x direction
            vcurr = vnext(jj);%update current vertex        
            p(level) = vcurr; %update path
            visited(vcurr) = 1;
            
        if plotflag
            ii        = p(level-1:level);
            hp(level) = line(X(ii,1),X(ii,2),X(ii,3));
            set(hp(level),'Color','b','LineWidth',2);
        end
    end   
    1;
end

if vend_indic(vcurr)==1
    p = p(1:level); %return the path
elseif level == 0
    p = [];
else
    error('I don''t understand why the program terminated');
end