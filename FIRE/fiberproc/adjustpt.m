function[Xnew] = adjustpt(X0,imr,wid)
%ADJUSTPT - adjusts poits
s  = size(imr);

Xnew = zeros(size(X0));
for i=1:size(X0,1);
    xi = round(X0(i,:));
    ix1= max(1   ,xi(1)-wid);
    ix2= min(s(3),xi(1)+wid);
    iy1= max(1   ,xi(2)-wid);
    iy2= min(s(2),xi(2)+wid);
    iz1= max(1   ,xi(3)-wid);
    iz2= min(s(1),xi(3)+wid);
    
    IM= imr(iz1:iz2,iy1:iy2,ix1:ix2);
    [lam V cmloc] = impca(IM);
    
    cm = cmloc + [ix1 iy1 iz1] - 1;
    v1 = V(:,1)'/norm(V(:,1)); %vector from center of mass in direction of fiber
    vx = xi-cm; %vector from centeor of mass to m    
    vx1= dot(vx,v1)*v1; %vector x component in the v1 direction
    
    Xnew(i,:) = cm+vx1; %new position
end
1;
