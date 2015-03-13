function[X F V R] = cut_network(X,F,V,R,window)
%REDUCE_NETWORK - takes only a piece of the larger network

xkeep = zeros(size(X,1),1);

ikeep=find( X(:,1)>=window(1) & ...
            X(:,1)<=window(2) & ...
            X(:,2)>=window(3) & ...
            X(:,2)<=window(4) & ...
            X(:,3)>=window(5) & ...
            X(:,3)<=window(6) );
        
xkeep(ikeep) = 1;

for fi=1:length(F)
    v = F(fi).v;
    F(fi).v = v(xkeep(v)==1);
end
    
[X F V R] = trimxfv(X,F,V,R);                