function[D] = dcalc(xi,X)
%DCALC - calculates distance between a point xi and a series of points X
%these are three dimensional points
%if xi is a series of points of the same dim as X, then compute distance
%pairwise

if nargin==2
    s = size(xi);
    S = size(X);

    if s(1)==3 & s(2)==1
        xi=xi';
    end
    if S(1)==3 & S(2)~=3
        X = X';
    end

    if all(s==S)
        Xd = xi-X;
    else
        o = ones(size(X,1),1);
        Xd= (o*xi - X);
    end
    D = sqrt(sum(Xd.^2,2));
elseif nargin==1
    D = sqrt(sum(xi.^2,2));
end
1;
