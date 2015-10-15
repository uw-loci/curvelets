function[X F V] = continuousfiber(X,F,V,plotflag)
%CONTINUOUSFIBER - makes fiber continuous that passes through common node
%node: the continuousfiber function called by fiberproc is more complicated
%in that it can handle when fibres should be merged if 3 or more come
%together at a vertex

X2 = X;
mergeflag = 1;
while mergeflag == 1
    mergeflag = 0;
    for vi=1:length(V)
        fe = V(vi).fe;
        if length(fe)==2 %exactly 2 fibers come together at end
            F = mergefiber(F,V,fe(1),fe(2));
            mergeflag = 1;
        end
    end
    [X F V]   = trimxfv(X,F,V);
end