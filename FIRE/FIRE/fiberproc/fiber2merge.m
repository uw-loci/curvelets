function[F V] = fiber2merge(X,F,V);
%FIBER2MERGE - anywhere 2 fibers come together, merge them

for vi=1:length(V)
    if length(V(vi).fe)==2
        f1 = V(vi).fe(1);
        f2 = V(vi).fe(2);        
        F  = mergefiber(F,V,f1,f2);
    end
end

[X F V] = trimxfv(X, F, V);