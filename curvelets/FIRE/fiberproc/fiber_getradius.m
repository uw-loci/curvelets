function[F Rad] = fiber_getradius(X,F,d,scale)
%FIBER_GETRAD - gets the radius of each fiber using the distance function

[K M N] = size(d);
Rad     = zeros(length(F),1);

for fi=1:length(F)
    v   = F(fi).v;
    Xi  = X(v,:);
    Xir = round(Xi);
    ind = sub2ind(size(d),Xir(:,3),Xir(:,2),Xir(:,1));   
    r   = d(ind)*scale(1);

    F(fi).r = mean(r);
    Rad(fi) = mean(r);
    if Rad(fi)==0
        1;
    end
end