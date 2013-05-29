function[L] = len3d(x,y,z)
%LEN3D - estimate the length of a 3d curve

if isempty(x)
    L = [];
    return
end

L = sqrt(cdiff(x).^2 + cdiff(y).^2 + cdiff(z).^2);