function[vol] = net2vol(vol,X,E)
%NET2VOL - converts a network into a volume, with ones along the fiber
%edges

if isnumeric(E)
    for i=1:size(E,1);
        x1 = X(E(i,1),:);
        x2 = X(E(i,2),:);    
        vol = line3d(vol,x1,x2);
    end
elseif isstruct(E)
    F = E;
    for fi=1:length(F)
        fv = F(fi).v;
        for j=1:length(fv)-1
            v1 = fv(j);
            v2 = fv(j+1);
            x1 = X(v1,:);
            x2 = X(v2,:);
            vol = line3d(vol,x1,x2);
        end
    end
end