function[X F E V] = loadtext(fnameX,fnameF)
%LOADTEXT - loads in textfiles for X and F

if nargin==1
    fpref = fnameX;
    fnameX = [fpref 'X.txt'];
    fnameF = [fpref 'F.txt'];
end

X = csvread(fnameX);

f = csvread(fnameF);
for fi=1:size(f,1)
    ind = find(f(fi,:)~=0);
    F(fi).v = f(fi,ind);
end

[X F V] = trimxfv(X,F);
for i=1:length(F)
    E(i,1:2) = [F(i).v(1) F(i).v(end)];
end 