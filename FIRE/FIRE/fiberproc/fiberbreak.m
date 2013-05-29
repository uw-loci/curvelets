function[X F V] = fiberbreak(X,F,V)
%fiberbreak(X,F,V) - breaks fibers at cross-links for AMIRA comparison

len_init = length(F);
for fi=1:length(F)
    v = F(fi).v;
    vstart = 1;
    for j = 2:length(v-1)
        vj = v(j);
        nj = length(V(vj).f);
        if nj > 1 %if vertex contains more than one fiber
            F(end+1).v = v(vstart:j);
            vstart = j;
        end
    end
    F(end+1).v = v(vstart:end);
end

F(1:len_init) = [];

[X F V] = trimxfv(X,F,V);
1;