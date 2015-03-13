function[X F R] = mergenetworks(X1,F1,R1,X2,F2,R2)
%MERGENETWORKS - merges two networks together
n1 = size(X1,1);
for fi=1:length(F2)
    F2(fi).v = F2(fi).v + n1;
end

X = [X1; X2];
F = F1;
F(end+1:end+length(F2)) = F2;

R = R1;
R(end+1:end+length(R2)) = R2;