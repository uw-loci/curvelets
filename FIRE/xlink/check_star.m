function[X F V R] = check_star(X,F,V,R,nstar)
%check_star(X,F,V,R,nstar) - removes danglers from "star" vertices, with
%more than nstar branches coming out, and those branches don't lead
%anywhere.

fremove = zeros(size(F));

for vi=1:length(V)
    if length(V(vi).f) > nstar
        fi = V(vi).f;
        for fj=fi
            v1 = F(fj).v(1);
            v2 = F(fj).v(end);
            
            nf1 = length(V(v1).f);
            nf2 = length(V(v2).f);
            
            if (nf1==1) || (nf2==1)
                fremove(fj) = 1;
            end
        end
    end
end

F(fremove==1) = [];
[X F V R] = trimxfv(X,F,V,R);
1;