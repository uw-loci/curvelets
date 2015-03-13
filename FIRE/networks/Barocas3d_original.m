clear
%*****************************************************************************/
%*                _______________________________________                    */
%*              <<      Written by T. Stylianopoulos     >>                  */
%*              << University of Minnesota (Twin Cities) >>                  */
%*              <<   Academic Advisor: Victor Barocas    >>                  */
%*              <<    E-Mail: styliano@cems.umn.edu      >>                  */
%*              <<        Phone: (612) 626-9032          >>                  */
%*                _______________________________________                    */
%*                                                                           */
%*****************************************************************************/



NF =180; % Number of Fibers
L  = 0.1; % Length of a segment in scaled units
D2 = 0.03^2; % Squared Diameter of a segment in scaled units

NS = 2 * NF; % Number of "segments."  Since each fiber
%                       can grow in two directions, N = 2*NF
NL = NS; % Number of "living" segments
NT=2*NF; % Number of Nodes that are not seeds

format long;

x  = zeros(1,NS);
y  = zeros(1,NS);
z  = zeros(1,NS);
x0 = zeros(1,NS);
y0 = zeros(1,NS);
z0 = zeros(1,NS);
dx = zeros(1,3*NS);
dy = zeros(1,3*NS);
dz = zeros(1,3*NS);
p0 = zeros(1,NS);
a  = zeros(1,NS*3);
V = zeros(3,3);
D = zeros(3,3);
norm1=0.0;
norm2=0.0;
norm3=0.0;


% Create initial seeds
for i=1:NF
       x0(i) = rand;
       y0(i) = rand;
       z0(i) = rand;
       x(2*i-1)  = x0(i);
       y(2*i-1)  = y0(i);
       z(2*i-1)  = z0(i);
       x(2*i)    = x0(i);
       y(2*i)    = y0(i);
       z(2*i)    = z0(i);
       dx1 = rand - 0.5;
       dy1 = rand - 0.5;
       dz1 = rand - 0.5;
       d1 = sqrt(dx1^2 + dy1^2 + dz1^2);
       dx(2*i-1) = dx1/d1;
       dx(2*i)   = -dx1/d1;
       dy(2*i-1) = dy1/d1;
       dy(2*i)   = -dy1/d1;
       dz(2*i-1) = dz1/d1;
       dz(2*i)   = -dz1/d1;
   p0(i)   = i;
   a(2*i-1) = 2*i-1;
   a(2*i) = 2*i;
end

% Create vector of "living" segments
live = 1:NL;

% The network generation begins

% Start adding monomer
while (NL > 0)
   g=1;
       j = floor(rand*NL)+1;  % Select fiber to update
       k = live(j);

       x(k) = x(k) + L*dx(k);  % Update fiber characteristics
       y(k) = y(k) + L*dy(k);
       z(k) = z(k) + L*dz(k);

       x1 = x(k);
       y1 = y(k);
       z1 = z(k);

       % Check for fiber out of the box
       u(1) = (x1 - 1.0)/abs(dx(k));
       u(2) = (y1 - 1.0)/abs(dy(k));
       u(3) = (z1 - 1.0)/abs(dz(k));
       u(4) = -x1/abs(dx(k));
       u(5) = -y1/abs(dy(k));
       u(6) = -z1/abs(dz(k));
       Lu = max(u);

       if (Lu > 0) % Fiber out of box
               x1 = x1 - Lu * dx(k);
               y1 = y1 - Lu * dy(k);
               z1 = z1 - Lu * dz(k);

               for m = j:(NL-1)
                       live(m) = live(m+1);  % Kill segment
               end

       NL = NL-1;
       g=0;
       end



   if(g==1)
       % Check for fiber-fiber collision
       if ((k==1)|(k==2))
               i = 2;
       else
               i = 1;
       end

       while (i < NF)

               xi0 = x(a(2*i-1));
               yi0 = y(a(2*i-1));
               zi0 = z(a(2*i-1));
               xi1 = x(a(2*i));
               yi1 = y(a(2*i));
               zi1 = z(a(2*i));

        h=sqrt((xi1-xi0)^2+(yi1-yi0)^2+(zi1-zi0)^2);
        h1=sqrt((xi1-x1)^2+(yi1-y1)^2+(zi1-z1)^2);
        h2=sqrt((xi0-x1)^2+(yi0-y1)^2+(zi0-z1)^2);

        if((h1 < h) & (h2 < h))
                  aa=(xi1-x1)^2+(yi1-y1)^2+(zi1-z1)^2;
          bb=(xi0-xi1)^2+(yi0-yi1)^2+(zi0-zi1)^2;
          cc=((xi1-x1)*(xi0-xi1)+(yi1-y1)*(yi0-yi1)+(zi1-z1)*(zi0-zi1))^2;
          dist2=(aa*bb-cc)/bb;

         if (dist2 < D2) % Collision!
           tt=-((xi1-x1)*(xi0-xi1)+(yi1-y1)*(yi0-yi1)+(zi1-z1)*(zi0-zi1))/bb;
           x1=xi1+(xi0-xi1)*tt;
           y1=yi1+(yi0-yi1)*tt;
           z1=zi1+(zi0-zi1)*tt;

                               NF = NF+1;          % Split struck fiber into two

                   a(2*NF-1)=k;
                   a(2*NF)=a(2*i);
                   dx(2*NF)=dx(2*i);
                   dy(2*NF)=dy(2*i);
                   dz(2*NF)=dz(2*i);
                   dx(2*NF-1)=dx(2*i-1);
                   dy(2*NF-1)=dy(2*i-1);
                   dz(2*NF-1)=dz(2*i-1);
                   a(2*i)=k;

                               for m = j:(NL-1)  % Kill segment in collision
                                       live(m) = live(m+1);
               end
                               NL = NL-1;

                               i =  NF; % Skip remainder of search
                       end
               end
               i = i + 1;
               if ((a(2*i-1)== k)|(a(2*i) == k))
                       i = i+1;  % skip collision with self!
       end
       end
end


  g=1;
       x(k) = x1;
       y(k) = y1;
       z(k) = z1;
end

% End of network generation. Print the network and calculate the components of the Orientation Tensor

NF
Ax = zeros(2,NF);
Ay = zeros(2,NF);
Az = zeros(2,NF);
% Bx = zeros(2,NF);
b = zeros(1,2*NF);

for i=1:NF
   Ax(1,i)=x(a(2*i-1))-0.5;
   Ax(2,i)=x(a(2*i))-0.5;
   Ay(1,i)=y(a(2*i-1))-0.5;
   Ay(2,i)=y(a(2*i))-0.5;
   Az(1,i)=z(a(2*i-1))-0.5;
   Az(2,i)=z(a(2*i))-0.5;
end

% idex=0;

figure(1);
plot3(Ax, Ay, Az);
grid on;  axis square;

om11=0.0;
om12=0.0;
om13=0.0;
om22=0.0;
om23=0.0;
om33=0.0;
len=0.0;
proj_len=0;

for i=1:NF
   elmt_no(i)=i;
   node1(i)=a(2*i-1);
   node2(i)=a(2*i);
   node1_xcoord(i)=Ax(1,i);
   node1_ycoord(i)=Ay(1,i);
   node1_zcoord(i)=Az(1,i);
   node2_xcoord(i)=Ax(2,i);
   node2_ycoord(i)=Ay(2,i);
   node2_zcoord(i)=Az(2,i);
   length(i)=sqrt((Ax(1,i)-Ax(2,i))^2 + (Ay(1,i)-Ay(2,i))^2 + (Az(1,i)-Az(2,i))^2);
   len=len+length(i);
   proj_len=proj_len+sqrt((Ax(1,i)-Ax(2,i))^2 + (Ay(1,i)-Ay(2,i))^2 );

% the components of the orientation tensor are calculated following
   cosa=(node2_xcoord(i)- node1_xcoord(i))/length(i);
   cosb=(node2_ycoord(i)- node1_ycoord(i))/length(i);
   cosg=(node2_zcoord(i)- node1_zcoord(i))/length(i);
   om11=om11+length(i)*cosg*cosg;
   om12=om12+length(i)*cosg*cosb;
   om13=om13+length(i)*cosg*cosa;
   om22=om22+length(i)*cosb*cosb;
   om23=om23+length(i)*cosa*cosb;
   om33=om33+length(i)*cosa*cosa;

    if (length(i) < 0.001)
       i
       length(i)
   end
       if ((Ax(1,i)>0.5)| (Ax(1,i)<-0.5) | (Ay(1,i)>0.5) | (Ay(1,i)<-0.5) | (Az(1,i)>0.5) | (Az(1,i)<-0.5))
          disp('fiber out of the mesh')
           i
 %          Ax(1,i)
 %          Ay(1,i)
 %          Az(1,i)
       end
       if ((Ax(2,i)>0.5) | (Ax(2,i)<-0.5) | (Ay(2,i)>0.5) | (Ay(2,i)<-0.5) | (Az(2,i)>0.5) | (Az(2,i)<-0.5))
          disp('fiber out of the mesh')
          i
  %        Ax(2,i)
  %        Ay(2,i)
  %        Az(2,i)
      end
end

len
proj_len;
fraction=(len*pi*D2)/4;
xx=sqrt(len*1.26/(fraction*1000))*0.001;


om11=om11/len;
om12=om12/len;
om13=om13/len;
om22=om22/len;
om23=om23/len;
om33=om33/len;

len=len/NF
NODES = NT;
GSSIZE=3*NODES;
ELEMENTS=NF;
ELEMENTS

%   fid = fopen('2dcol.vect','w');
 %  status = fclose(fid);

 fid = fopen('exptable.txt','w');
 fprintf(fid,'%d %d %d\n',NODES,GSSIZE,ELEMENTS);

for i=1:NF
  fprintf(fid,'%d %d %d %12.10f %12.10f %12.10f %12.10f %12.10f %12.10f\n',i, node1(i),node2(i),node1_xcoord(i),node1_ycoord(i),node1_zcoord(i),node2_xcoord(i),node2_ycoord(i),node2_zcoord(i));
end
status = fclose(fid);

% calculate the eigenvalues and eigevectors of the orientation tensor

R=[om11 om12 om13;om12 om22 om23;om13 om23 om33];

[V,D]=eig(R);
norm1=sqrt(V(1,1)^2+V(2,1)^2+V(3,1)^2);
norm2=sqrt(V(1,2)^2+V(2,2)^2+V(3,2)^2);
norm3=sqrt(V(1,3)^2+V(2,3)^2+V(3,3)^2);

v1(1)=V(1,1)/norm1; v1(2)=V(2,1)/norm1; v1(3)=V(3,1)/norm1;
v2(1)=V(1,2)/norm2; v2(2)=V(2,2)/norm2; v2(3)=V(3,2)/norm2;
v3(1)=V(1,3)/norm3; v3(2)=V(2,3)/norm3; v3(3)=V(3,3)/norm3;


v1=v1*D(1,1);
v2=v2*D(2,2);
v3=v3*D(3,3);


K1=[0 v1(1) 0 v2(1) 0 v3(1)];
K2=[0 v1(2) 0 v2(2) 0 v3(2)];
K3=[0 v1(3) 0 v2(3) 0 v3(3)];

%figure (2);
%plot3(K1,K2,K3);
%axis square; grid on;