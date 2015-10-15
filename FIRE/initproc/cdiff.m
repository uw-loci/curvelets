function[d] = cdiff(x)
%CDIFF - computes central difference of x, using left and right differences
%at the end points

if isempty(x)
    d = [];
    return
elseif length(x)==1
    d = x;
    return
end

s = size(x);
if length(s) > 2 || all(s>1)
    error('input must be a vector');
end

n = length(x);
d(1)     =  x(2)   - x(1);
d(2:n-1) = (x(3:n) - x(1:n-2))/2;
d(n)     =  x(n)   - x(n-1);

if size(x,1)>1 %x is a column vector
    d = d';
end
    
