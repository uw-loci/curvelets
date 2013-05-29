function[B,dBx dBy dBz, Bx By Bz] = getbox(u,r,s)
%GETBOX - gets B, dB given a point u = [ix iy iz] and radius
%
%Bx By Bz is a 3D matrix of indices referring to the original image
%dBx, dBy, dBz are stacks of 2 2d matrices that indicate the left and right
%x boundary, y boundary and z boundary respectively
%
%[B,dBx dBy dBz, Bx By Bz] = getbox(u,r,s)
    ix = u(1);
    iy = u(2);
    iz = u(3);

    ix1 = max(ix-r,1);
    iy1 = max(iy-r,1);
    iz1 = max(iz-r,1);
    
    ix2 = min(ix+r,s(3));
    iy2 = min(iy+r,s(2));
    iz2 = min(iz+r,s(1));
    
    ixr = ix1:ix2;
    iyr = iy1:iy2;
    izr = iz1:iz2;
    

    [Bz By Bx] = ndgrid(izr,iyr,ixr);
    B = sub2ind(s,Bz,By,Bx);    
    
    
    if nargout >=2
        dBz = B([1 end],:,:);
        dBy = B(:,[1 end],:);
        dBx = B(:,:,[1 end]);
    end