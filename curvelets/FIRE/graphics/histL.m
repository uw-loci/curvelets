function[range len number] = histL(L,n)

if nargin < 2
    n = 10;
end

m = min(L);
M = max(L);

range = m + (0:n)*(M-m)/n;

range(1) = range(1)-1000*eps;
range(end) = range(end)+1000*eps;

number = zeros(n,1);
len    = zeros(n,1);

for i=1:n
    ii = find(L>=range(i) & L < range(i+1));
    
    number(i)  = length(ii);
    len(i)     = sum(L(ii));
end

x = range(1:end-1) + (range(2)-range(1))/2;

bar(x,len,1)