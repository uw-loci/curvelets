function[X F V] = remove_free(X,F,V)
%REMOVE_FREE - removes free ends of fibers that don't attach to anything

%create a new class in Fiber structure with the number of fibers at each
%vertex
for fi=1:length(F)
    vi=F(fi).v;
    for j=1:length(vi)
        vj = vi(j);
        nf = length(V(vj).f);
        F(fi).n(j) = nf;
    end
end

%remove fiber danglers as needed
Fold = F;
fremove = [];
for fi=1:length(F)
    v1 = F(fi).v(1);
    if V(v1).b==1 %fiber end is on boundary
        istart = 1;
    else
        istart = min(find(F(fi).n > 1)); %find first fiber node that is part of an intersection 
    end
    
    v2 = F(fi).v(end);
    if V(v2).b==1 %fiber end is on boundary
        istop = length(F(fi).v);
    else
        istop = max(find(F(fi).n > 1)); %find last fiber node that is part of an intersection
    end
    
    if isempty(istart) | istart==istop %fiber doesn't really contribute to stiffness of gel
        fremove = [fremove fi]; %remove fiber from list
        F(fi).v = [];
        F(fi).n = [];
    else
        F(fi).v = F(fi).v(istart:istop);
        F(fi).n = F(fi).n(istart:istop);
    end
    %cla;
    %plotfiber(X,Fold,2,0,'k')
    %plotfiber(X,Fold(fi),2,0,'b')
    %plotfiber(X,F(fi),2,0,'r')
    %1;
end
F(fremove) = [];
[X F V] = trimxfv(X,F,V);