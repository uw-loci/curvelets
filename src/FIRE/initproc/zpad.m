function[f] = zpad(u,n);
%ZPAD - pad variable u with n zeros on each dimension

s  = size(u);
if nargin==1
    n = min(s);
end
sz = s + 2*n;
f  = zeros(sz);

if ndims(u)==2
    f(n+1:s(1)+n,n+1:s(2)+n) = u;
elseif ndims(u)==3
    f(n+1:s(1)+n,n+1:s(2)+n,n+1:s(3)+n) = u;
else
    error('code only handles 2 and 3 dims')
end
