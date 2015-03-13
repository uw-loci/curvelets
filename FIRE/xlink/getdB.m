function[dB] = getdB(u,r,s);
%getdB - returns 2 matrices for the bounday elements of the
%box centered at u with radius r
%
%it returns dBside, dBedge, dBcorn
%for each, the first column are the indices for teh boundary
%teh latter columns are the indices for the neighbors

%warning off

K = s(1); M = s(2); N = s(3);
x = u(1); y = u(2); z = u(3);

zs = 1;
ys = K;
xs = K*M;

x1 = max(x-r,1); x2 = min(x+r,N);
y1 = max(y-r,1); y2 = min(y+r,M);
z1 = max(z-r,1); z2 = min(z+r,K);

xr = ((x1+1):(x2-1))';
yr = ((y1+1):(y2-1))';
zr = ((z1+1):(z2-1))';

% Get the sides
        [C1 C2] = ndgrid(yr,xr); c1 = C1(:); c2 = C2(:);  o  = ones(size(c1));
        dBzsub  = [o*z1  c1     c2; ...
                   o*z2  c1     c2];
        zi  = sub2ind(s,dBzsub(:,1),dBzsub(:,2),dBzsub(:,3));
        
        [C1 C2] = ndgrid(zr,xr); c1 = C1(:); c2 = C2(:);  o  = ones(size(c1));
        dBysub  = [c1     o*y1    c2; ...
                   c1     o*y2    c2];
        yi  = sub2ind(s,dBysub(:,1),dBysub(:,2),dBysub(:,3));
               
        [C1 C2] = ndgrid(zr,yr); c1 = C1(:); c2 = C2(:);  o  = ones(size(c1));
        dBxsub  = [c1     c2     o*x1; ...
                   c1     c2     o*x2];
        xi  = sub2ind(s,dBxsub(:,1),dBxsub(:,2),dBxsub(:,3));

    %convert to indices
       
    %identify the neighbors
        dBxn    = [xi+ys+zs xi+ys xi+ys-zs xi-zs xi-ys-zs xi-ys xi-ys+zs xi+zs];
        dByn    = [yi+xs+zs yi+xs yi+xs-zs yi-zs yi-xs-zs yi-xs yi-xs-zs yi+zs];
        dBzn    = [zi+xs+ys zi+xs zi+xs-ys zi-ys zi-xs-ys zi-xs zi-xs-ys zi+ys];
    
    %return dBside
        dBside = [xi dBxn; yi dByn; zi dBzn];
    
%get the edges
    dBedge = [];

    %get the edges that run along the x direction
        o     = ones(size(xr));
    
        sub   = [o*z1 o*y1 xr];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+xs i-xs   i+xs+ys i+ys i-xs+ys   i+xs+zs i+zs i-xs+zs];
        dBedge= [dBedge; n];

        sub   = [o*z2 o*y1 xr];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+xs i-xs   i+xs+ys i+ys i-xs+ys   i+xs-zs i-zs i-xs-zs];
        dBedge= [dBedge; n];     
        
        sub   = [o*z1 o*y2 xr];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+xs i-xs   i+xs-ys i-ys i-xs-ys   i+xs+zs i+zs i-xs+zs];
        dBedge= [dBedge; n];
       
        sub   = [o*z2 o*y2 xr];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+xs i-xs   i+xs-ys i-ys i-xs-ys   i+xs-zs i-zs i-xs-zs];
        dBedge= [dBedge; n];        
        
    %get the edges that run along the y direction
        o     = ones(size(yr));    
    
        sub   = [o*z1 yr o*x1];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+ys i-ys   i+ys+xs i+xs i-ys+xs   i+ys+zs i+zs i-ys+zs];
        dBedge= [dBedge; n];
        
        sub   = [o*z2 yr o*x1];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+ys i-ys   i+ys+xs i+xs i-ys+xs   i+ys-zs i-zs i-ys-zs];
        dBedge= [dBedge; n];     
        
        sub   = [o*z1 yr o*x2];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+ys i-ys   i+ys-xs i-xs i-ys-xs   i+ys+zs i+zs i-ys+zs];
        dBedge= [dBedge; n];
       
        sub   = [o*z2 yr o*x2];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+ys i-ys   i+ys-xs i-xs i-ys-xs   i+ys-zs i-zs i-ys-zs];
        dBedge= [dBedge; n];              
        
    %get the edges that run along the z direction
        o     = ones(size(zr));    
    
        sub   = [zr o*y1 o*x1];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+zs i-zs   i+zs+xs i+zs i-zs+xs   i+zs+ys i+ys i-zs+ys];
        dBedge= [dBedge; n];
        
        sub   = [zr o*y2  o*x1];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+zs i-zs   i+zs+xs i+xs i-zs+xs   i+zs-ys i-ys i-zs-ys];
        dBedge= [dBedge; n];     
        
        sub   = [zr o*y1  o*x2];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+zs i-zs   i+zs-xs i-xs i-zs-xs   i+zs+ys i+ys i-zs+ys];
        dBedge= [dBedge; n];
       
        sub   = [zr o*y2  o*x2];
        i     = sub2ind(s,sub(:,1),sub(:,2),sub(:,3));
        n     = [i i+zs i-zs   i+zs-xs i-xs i-zs-xs   i+zs-ys i-zs i-zs-ys];
        dBedge= [dBedge; n]; 

%get the corners (8)
        zz = [z2 z1];
        yy = [y2 y1];
        xx = [x2 x1];
        
        dBcorner = [];
        for ii=1:2
        for jj=1:2
        for kk=1:2
            si = (-1)^ii;
            sj = (-1)^jj;
            sk = (-1)^kk;
    
            i     = sub2ind(s,zz(kk),yy(jj),xx(ii));
            dBcorner = [dBcorner; i i+si*xs i+sj*ys i+sk*zs ...
                            i+si*xs+sj*ys i+sj*ys+sk*zs i+si*xs+sk*zs];
        end
        end
        end
        
dB.side = dBside;
dB.edge = dBedge;
dB.corner=dBcorner;
          
%warning on

