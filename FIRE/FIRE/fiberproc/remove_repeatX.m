function[X F V R] = remove_repeatX(X,F,V,R,plotflag)
%REMOVE_REPEAT - account for cases where a particular X is repeated
%or when two identifical vertices are in a row, or a middle and edge of teh
%same fiber

if nargin<5
    plotflag = 0;
end
if isempty(X)
    return
end

%find when different X's are identical
    Xr = max(1,ceil(X/max(X(:))*1000));
    s  = max(Xr);
    ind = sub2ind(s,Xr(:,1),Xr(:,2),Xr(:,3));
    [isort idsort] = sort(ind);
    dsort = diff(isort);
    idiff = find(dsort==0);
    same  = [idsort(idiff) idsort(idiff+1)];
        
%replace all identical x's with the same vertex id
    for i=1:size(same,1)
        vi = same(i,1);
        vj = same(i,2);
        f = V(same(i,1)).f;
        for j=f
            F(j).v(F(j).v==vi) = vj;
        end
    end    

%remove instances of two identical vertices being in a row in a fiber
%i. e. F(i).v = [3 23 45 45 9] -> [3 23 45 9]
    for i=1:length(F)
        vi = F(i).v;
        vd = diff(vi);
        F(i).v(vd==0) = []; %same vertices next to each other
    end

    [X F V R] = trimxfv(X,F,V,R);    