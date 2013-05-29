function[V boundary1 boundary2] = find_boundary(X,F,V,db,blist)
%FIND_BOUNDARY - identifies the boundary of teh network
%db = thickness of boundary
%blist = vector that can contain a subset of [1 2 3]

if isempty(X)
    V = [];
    boundary1 = [];
    boundary2 = [];
    return
end

boundary1 = [];
boundary2 = [];
for id=blist
    bmin = min(X(:,id));
    bmax = max(X(:,id));
    
    for i=1:length(F)
        for v = [F(i).v(1) F(i).v(end)]        
            b = X(v,id);
            if b<bmin+db  %point is on one boundary
                boundary1 = [boundary1 v];                
            elseif b>bmax-db %point is on the other boundary
                boundary2 = [boundary2 v];
            end
        end
    end
end

for vi=1:length(V)
    if ismember(vi,boundary1)
        V(vi).b = 1;
    elseif ismember(vi,boundary2)
        V(vi).b = 2;
    else
        V(vi).b = 0;
    end
end