function[D] = dotcalc(xi,X)
%DOTCALC - calculates dot product between a vector xi and a series of points X

s = size(xi);
S = size(X);
if s(1)==3 & s(2)==1
    xi=xi';
end
if S(1)==3 & S(2)~=3
    X = X';
end

if all(s==S) | all(s==fliplr(S));
    D = sum(xi.*X,2);
else
    o = ones(size(X,1),1);
    D = sum( (o*xi).*X,2);
end