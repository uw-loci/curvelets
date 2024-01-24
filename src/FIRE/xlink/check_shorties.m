function[X F V R] = check_shorties(X,F,V,R,p)
%check_shorties(X,F,V,R,p) - identify short little connectors that don't
%do much and remove them by merging fibers together at those cross-links.
%sometimes, this might be a little complicated.
%
%aside

for fi=1:length(F)
    v1 = F(fi).v(1);
    v2 = F(fi).v(end);
    
    x1 = X(v1,:);
    x2 = X(v2,:);
    
    Li = norm(x2 - x1);
    
    if Li < p.thresh_short_L
        [F V] = mergevertex(F,V,v1,v2,X);
        xm = (x1+x2)/2;
        X(v1,:) = xm;
        X(v2,:) = xm;
    end
end

[X F V R] = trimxfv(X,F,V,R);
1;