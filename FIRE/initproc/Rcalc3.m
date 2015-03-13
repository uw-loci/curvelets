function[R] = Rcalc3(v);
%RCALC3 - computes 3d rotation matrix for a vector to [1 0 0]
    if size(v,2)==1
        v = v';
    end

%first rotate from xy plane to x direction
    Lxy = norm(v(1:2));
    if Lxy==0 %v is solely in Z direction
        R1 = eye(3);
    else
        ca = v(1)/Lxy;
        sa = v(2)/Lxy;
        R1 = [ ca sa 0; ...
              -sa ca 0; ...
                0  0 1];
    end
    vv = R1*v';

%now rotate from xz plane to x direction
    Lxz = norm(vv([1 3]));
    if Lxz==0 %would require vector to have no length at all
        R2 = eye(3);
    else
        cb = vv(1)/Lxz;
        sb = vv(3)/Lxz;
        R2 = [ cb 0 sb; ...
                0 1  0; ...
              -sb 0 cb];
    end    
    R = R2*R1;
          
