function[x,y,z,t] = plotbeam(X,AL,AR,plotflag,N)
%PLOTBEAM - plots fiber represented by nodal positions and angles
%X is an nx3 matrix of nodal positions
%if we visualize the beam goes from left to right
%AL in an (n-1)x3 angle matrix of the lef side of the edge
%AR is an (n-1)x3 angle matrix of the right side of the edge

if nargin<4
    plotflag=0;
end
if nargin<5
    N = 10; %number of points in each beam
end
H1 = inline('x.^3-2*x.^2+x','x');
H2 = inline('-x.^3 + x.^2','x');

%interpolate functions
    n = size(X,1);
    x = [];
    y = [];
    z = [];
    t = [];
    for i=1:n-1
        X1 = X (i,  :);
        X2 = X (i+1,:);
        
        if norm(X2-X1)==0
            x = X1(1);
            y = X1(2);
            z = X1(3);        
        else
            R3 = Rcalc3(X2-X1);
            L = norm(X2-X1);
            
            xloc = (0:(N-1))/(N-1);
            yloc = AL(i,1)*H1(xloc)+AR(i,1)*H2(xloc);
            zloc = AL(i,2)*H1(xloc)+AR(i,2)*H2(xloc);
            xloc = xloc*L;
           
            Xglob= R3'*[xloc; yloc; zloc] + X1'*ones(1,N);        

            x = [x; Xglob(1,:)'];
            y = [y; Xglob(2,:)'];
            z = [z; Xglob(3,:)'];
            if isempty(t)
                t = xloc;
            else
                t = [t; xloc+t(end)];
            end
        end
    end
    
%plotbeam
    if plotflag==1
        cla; 
        hold on
        plot3(x,y,z); 
        plot3(X(:,1),X(:,2),X(:,3),'o')
        hold off
    end