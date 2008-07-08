% make a moving average filter to smooth data

function y = movAve(x)

M = 5;
B = ones(M,1)/M;
ytemp = filter(B,1,x);
y = [x(1:M)' ytemp(M+1:end)'];
