function[X,F,V,R] = minnodes_network(X,F,V,R)
%MINNODES_NETWORK - reduces a network to the minimum number of nodes needed
%to maintain connectivity.  in other words, only the crosslinks are kept

fremove = zeros(length(F),1);
for fi=1:length(F)
    v = F(fi).v;
    nx= zeros(size(v));
    for vj = 2:length(v)-1
        nx(vj) = length(V(vj).f);
    end
    nx(1) = Inf; nx(end) = Inf; %automatically keep beginning and end
    vkeep   = v(nx>=2); %keep only vertices that are connected to more than one iber
    F(fi).v = vkeep;
end
F(fremove==1) = [];
[X F V R] = trimxfv(X,F,V,R);