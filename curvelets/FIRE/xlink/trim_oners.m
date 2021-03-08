function[X F V R] = trim_oners(X,F,V,R)
%TRIM_ONERS - removes cases where single edges stick out

[X F V R] = trimxfv(X,F,V,R);

fremove = zeros(length(F),1);
for vi = 1:length(V);
    f = V(vi).f;
    if length(f) == 1        
        fremove(f) = 1;
    end
end
F(fremove==1) = [];
[X F V R] = trimxfv(X,F,V,R);
    