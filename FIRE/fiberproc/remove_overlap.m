function[X F V] = remove_overlap(X,F,V)
%REMOVE_OVERLAP - if one fiber is contained in another fiber, remove it

fremove = [];
for vi=1:length(V)
    f = V(vi).f;
    nf = length(f);
    if nf > 1
        for fid1 = 1:nf-1
            for fid2 = fid1+1:nf
                f1 = f(fid1);
                f2 = f(fid2);
                v1 = F(f1).v;
                v2 = F(f2).v;
                if all(ismember(v1,v2));
                    fremove(end+1) = f1;
                elseif all(ismember(v2,v1))
                    fremove(end+1) = f2;
                end
            end
        end
    end
end
F(fremove) = [];
[X F V] = trimxfv(X,F,V);