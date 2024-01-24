function[] = plotbox(d,u,r,pt);
%PLOTBOX - plots the distance function (d) at the surface of a box 
%centered at u of radius r, where the size of d is given in p.size
%
%plotbox(d,u,p,pt)
%  d = distance function (z,y,x)
%  u = point at which to plot (x,y,z)
%  r = radius of box
% pt = points to plot on the surface of the box (optional)
hold on



iz = u(3);

iy = u(2);

ix = u(1);

di = d(iz,iy,ix);

[B dBx dBy dBz Bx By Bz] = getbox(u,r,size(d));



%[x y z] = meshgrid(1:2*r+1);

%[x,y,z] = meshgrid(-r:r);

%slice(x,y,z,d(B),[-r r],[-r r],[-r r])



c = colormap;

boxcol = d;

M = max(boxcol(:));

m = min(boxcol(:));

boxcol = ceil( (boxcol-m)/(M-m)*64);



h1 = .5*[-1  1  1 -1 -1]';

h2 = .5*[-1 -1  1  1 -1]';

o  = ones(5,1);



%plot top and bottom of

[K M N] = size(d);

for k=[-r r]

for j=-r:r

for i=-r:r

    z = u(3)+k;

    y = u(2)+j;

    x = u(1)+i;



    if k==-r

        Z = z*o;

    elseif k==r

        Z = z*o;

    end

    Y = y+h1;

    X = x+h2;

    

    if (x>=1 & x<=N & y>=1 & y<=M & z>=1 & z<=K)

        fill3(X,Y,Z,boxcol(z,y,x));    

    end

end

end

end





for k=-r:r

for j=[-r r];

for i=-r:r

    z = u(3)+k;

    y = u(2)+j;

    x = u(1)+i;



    if j==-r

        Y = y*o;

    else

        Y = y*o;

    end

    Z = z+h1;

    X = x+h2;

    if (x>=1 & x<=N & y>=1 & y<=M & z>=1 & z<=K)

        fill3(X,Y,Z,boxcol(z,y,x));    

    end

end

end

end



for k=-r:r

for j=-r:r;

for i=[-r r]

    z = u(3)+k;

    y = u(2)+j;

    x = u(1)+i;



    if i==-r

        X = x*o;

    else

        X = x*o;

    end

    Y = y+h1;

    Z = z+h2;

    if (x>=1 & x<=N & y>=1 & y<=M & z>=1 & z<=K)

        fill3(X,Y,Z,boxcol(z,y,x));    

    end

end

end

end

xlabel('X')

ylabel('Y')

zlabel('Z')



if nargin>3 %then we have input some points to plot

    hold on

    plot3(pt(:,1),pt(:,2),pt(:,3),'k.','MarkerSize',30)

end