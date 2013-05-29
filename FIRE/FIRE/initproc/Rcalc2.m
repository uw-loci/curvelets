function[R] = Rcalc2(v);
%RCALC3 - computes 3d rotation matrix for a vector to [1 0 0]
    if size(v,2)==1
        v = v';
    end

%first rotate from xy plane to x direction
    Lxy = norm(v);
    if Lxy==0 
        R  = eye(2);
    else
        ca = v(1)/Lxy;
        sa = v(2)/Lxy;
        R  = [ ca sa; ...
              -sa ca];
    end
