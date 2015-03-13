function[Xr,Fr,Vr,Rr] = remove_floppy_edges(X,F,E,V,R,B1,B2,dir,plotflag)
%REMOVE_FLOPPY_EDGES - removes edges that don't contribute to stiffness of
%network.  we do this by finding all the paths from boundary 1 (B1) to
%boundray 2 (B2) and remove any edges and vertices not contained in these
%paths (Glen's idea)
%
%note - could be made faster if a nonstiff part of the network is never
%searched again
%
if nargin<7
    dir = 1;
end
if nargin<8
    plotflag = 0;
end

stiff = zeros(length(V),1);
boundary = zeros(length(V),1);
boundary(B1) = 1;
boundary(B2) = 1;

if plotflag
    clf
    plotnetwork(X,E,'k',1);
    plot3(X(B1,1),X(B1,2),X(B1,3),'ks','LineWidth',2)
    plot3(X(B2,1),X(B2,2),X(B2,3),'ks','LineWidth',2)  
end

%for efficiency sake, i think it makes sense to first start with the
%boundary nodes in order to find a stiff one.  we look for paths that
%connect the two boundaries together and label all nodes along those paths
%as stif
    z = zeros(size(stiff)); %don't avoid any vertices
    vend = z;
    vend(B2) = 1;
    for v1 = B1
        p = find1path(v1,vend,z,X,E,V,dir,plotflag);
        stiff(p) = 1;
        vend(p) = 1;
    end
    
    vend = stiff;
    vend(B1) = 1;
    for v1 = B2
        p = find1path(v1,vend,z,X,E,V,dir,plotflag);
        stiff(p) = 1;
        vend(p) = 1;
    end
    
%then we loop through all the nonstiff vertices and find cases where there
%are two different paths that connect that vertex to stiff parts of the
%network.  those vertices are also consideredd stiff
    for vi = 1:length(V)
        if stiff(vi)~=1 && boundary(vi)==0 && ~isempty(V(vi).e)
            p1 = find1path(vi,stiff,z,X,E,V,dir,plotflag);            
            if ~isempty(p1)
                avoid = z;
                avoid(p1) = 1;
                p2 = find1path(vi,stiff,avoid,X,E,V,dir,plotflag);
            else
                p2 = [];
            end
            if ~isempty(p2)
                stiff([p1; p2]) = 1;
            end
        end
    end


%reduce Edge matrix
    vstiff = find(stiff==1);
    Er = E(ismember(E(:,1),vstiff) & ismember(E(:,2),vstiff),:);

%remake X,F,V
    for fi=length(F):-1:1
        v = F(fi).v;
        si= stiff(v); %get stiffness of vertices
        if sum(si==1)<2 %fiber has less than 2 stiff vertices
            F(fi) = [];
        else
            ii = find(si==1);
            istart = ii(1);
            istop  = ii(end);
            F(fi).v= v(istart:istop);
        end
    end
    [Xr Fr Vr Rr] = trimxfv(X,F,V,R);
    
if plotflag
    clf
    plotnetwork(X,E,'k',1);
    plotnetwork(X,Er,'r',2);
    plot3(X(B1,1),X(B1,2),X(B1,3),'ks','LineWidth',2)
    plot3(X(B2,1),X(B2,2),X(B2,3),'ks','LineWidth',2)
    plot3(X(vstiff,1),X(vstiff,2),X(vstiff,3),'bo','MarkerFaceColor','b')
end

