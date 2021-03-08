function[F Len Rad] = calc_fiberlen(X,F,R)
%CALC_FIBERLEN - calculates the length of the fibers and returns them in
%the form of a field in F and a Length array
Len = zeros(length(F),1);
for fi=1:length(F)
    fv = F(fi).v;
    len = 0;
    for j=1:length(fv)-1
        v1 = fv(j);
        v2 = fv(j+1);
        len = len+norm(X(v2,:)-X(v1,:));
    end
    F(fi).len = len;
    Len(fi) = len;
    if nargout >= 3
        Rad(fi,1) = mean(R(fv));
    end
end