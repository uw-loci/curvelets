function[Amin err] = mincurv(X0,plotflag,options)
%FIBERAPPROX - approximate a fiber, represented by Xpts, with a series of 3
%nodes, using the interpolation functions in Bathe79.
    if nargin<2
        plotflag=0;
    end
    if nargin<3
        options = optimset('MaxFunEvals',1000);%,'Display','iter');
    end

    x = X0(:,1);
    y = X0(:,2);
    z = X0(:,3);
    n = length(x);
        
    %calculate initial guess for A0 (assume beam is mainly in the Z-plane)
        A0 = zeros(size(X0));
        A0(1    ,3) = atan2(y(2  )-y(1    ),x(2  )-x(1    ));
        A0(2:n-1,3) = atan2(y(3:n)-y(1:n-2),x(3:n)-x(1:n-2));
        A0(  n  ,3) = atan2(y(  n)-y(  n-1),x(  n)-x(  n-1));
        
    %add a second rotation about the x or y axis, depending on orientation
        a     = A0(:,3);
        iyrot = find( abs(a)<pi/4 | abs(a) > 3*pi/4);
        ixrot = setdiff(1:size(A0,1),iyrot);

        if ismember(1,iyrot) %rotate about y axis
            A0(1,2) = atan2(x(2)-x(1),z(2)-z(1));
        else %rotate about x axis
            A0(1,1) = atan2(z(2)-z(1),y(2)-y(1));
        end
        if ismember(length(x),iyrot) %rotate about y axis
            A0(n,2) = atan2(x(n)-x(n-1),z(n)-z(n-1));
        else %rotate about x axis
            A0(n,1) = atan2(z(n)-z(n-1),y(n)-y(n-1));
        end
        ii = intersect(iyrot,2:n-1);
        A0(ii,2) = atan2(x(ii+1)-x(ii-1),z(ii+1)-z(ii-1));
        ii = intersect(ixrot,2:n-1);
        A0(ii,2) = atan2(z(ii+1)-z(ii-1),y(ii+1)-y(ii-1));
        
    %find optimal angle
        err = minfun(A0,X0);
        if err > 1e-3 %no need for optimization
            [Amin err] = fminsearch(@minfun,A0,options,X0);
        else
            Amin = A0;
        end

    %plot result
        if plotflag
            cla
            hold on
            plotbeam([X0 Amin],1);
            xlabel('x'); ylabel('y'); zlabel('z')
        end
        1;
        
end

function[err] = minfun(A,X)
    [x,y,z,t] = plotbeam([X A]);
    K         = curv3d(t,x,y,z);
    L         = len3d(x,y,z);
    err       = sum(L); %sum(K).*sum(L)^3;
end