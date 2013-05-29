function[stiff] = findpaths(vstart,vstartall,vend,E,V,stiff,X,maxstep,plotflag)
%FINDPATHS - find all paths from vstart (number) to vend (vector) through
%the graph given by edgelist E and vertex list V

if nargin<7
    maxstep = Inf;
end
if nargin<8
    plotflag = 0;
end
p(1) = vstart; %current path we are traversing (starting from vstart)
level = 1;
vcurr= vstart;
visited{1} = [];

if plotflag
    h = plot3(X(vcurr,1),X(vcurr,2),X(vcurr,3),'ko','MarkerFaceColor','g');
end
step = 0;
while level ~= 0 & step < maxstep %there are still more paths to explore    
    step = step+1;
    if plotflag
        set(h,'Marker','none')
        h = plot3(X(vcurr,1),X(vcurr,2),X(vcurr,3),'ko','MarkerFaceColor','g');
        title([num2str(step) ' of ' num2str(maxstep)]);
        pause(.001)
    end
    v     = V(vcurr).v;
    
    vnext = setdiff(v,p(1:level)); %set of vertices vcurr connects to that don't include vertices already visited on path
    vnext = setdiff(vnext,visited{level}); %also exclude the vertices already visited from this node
    if stiff(vcurr) == 1  %also, if this vertex is stiff, don't go to other stiff vertices
        ind   = find(stiff(vnext)==0);
        vnext = vnext(ind);
    end                              
    ind = find(stiff(vnext))==-1; %remove indices that don't go anywhere
    vnext(ind) = [];    
    vnext = setdiff(vnext,vstartall); %don't go into one of the starting indices
        
    if isempty(vnext) %there are no more children, so go back one node
        if length(v)==1 %if vertex only has one neighbor and isn't on boundary
            if ~ismember(vcurr,[vstart vend])
                stiff(vcurr) = -1; %it is a floppy vertex
                if plotflag
                    plot3(X(vcurr,1),X(vcurr,2),X(vcurr,3),'md','LineWidth',4);
                end
            end
        elseif length(v)>1 %if vertex has multiple neighbors
            sneighbor = stiff(v);
            s = sum(sneighbor==-1) ;
            if s==length(v)-1 %if all but one of these neighbors is floppy
                stiff(vcurr) = -1; %vcurr is floppy, too
                if plotflag
                    plot3(X(vcurr,1),X(vcurr,2),X(vcurr,3),'md','LineWidth',4);
                end
            end
        end

        if plotflag & level>1
            set(hp(level),'Color','k','LineWidth',1);        
        end        
        level = level-1;
        if level~=0
            vcurr = p(level);
        end
        
    else %there's another child left to visit
        level = level+1; %increase path level by one
        
        visited{level} = []; %this node is newly visited, so it can go anywhere, next
        x     = X(vnext,1);
        [m jj]= max(x); %choose point that is farthest in x direction
        vcurr = vnext(jj);%update current vertex        
        visited{level-1}(end+1) = vcurr;
        p(level) = vcurr; %update path
        if stiff(vcurr)==1 | ismember(vcurr,vend) %then this path has reached an end node
            for j=1:length(visited)
                visited{j} = [];
            end
            vv = p(1:level);
            stiff(vv) = 1; %add the nodes in this path to the collection of stiff nodes            
            if plotflag
                plot3(X(vv,1),X(vv,2),X(vv,3),'bs','MarkerFaceColor','b','MarkerSize',10);
            end 
            level = level-1; %go back up one            
        elseif plotflag
            ii = [p(level-1) p(level)];
            hp(level) = line(X(ii,1),X(ii,2),X(ii,3));
            set(hp(level),'Color','r','LineWidth',2);
        end
    end
    1;
end
if plotflag
    set(h,'Marker','none')
end