function[iclose] = findclose(X,i,r,VM)
%FINDCLOSE - finds other vertices (in VM) a distance r from X
    [K M N] = size(VM);

    rc = ceil(r);

    x = round(X(i,1));
    y = round(X(i,2));
    z = round(X(i,3));
    x1= max(x-rc,1);
    x2= min(x+rc,N);
    y1= max(y-rc,1);
    y2= min(y+rc,M);
    z1= max(z-rc,1);
    z2= min(z+rc,K);
    vm= VM(z1:z2,y1:y2,x1:x2);

    iclose  = vm(vm~=0 & vm~=i);
    d       = dcalc([x y z],X(iclose,1:3));
    iclose  = iclose(d<=r);
    1;
