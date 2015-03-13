function[X,F,E,V] = rand3dnet(NF,W,Lstep,D,coltype,Lmax,rseed,Lp)
%RAND3DNET - generates a 3d network given num fibers, length, and diam^2
%inside a unit box [0,1]^3
%rand3dnet(NF,Lstep,D,coltype,Lmax,rseed,Lp)
%
%  NF       = number of fibers
%  Lstep    = Length step increase
%  D        = diameter of a segment
%  coltype  = indicates what happens during a collision
%               - T, Bacoras, original, stop - fiber stops growing 
%               - Stein2, fixedlen - fiber continues growing
%  Lmax     = maximum length of fiber
%  rseed    = random number seed (so it can be repeatable)
%  shape    = indicates shape of fiber
%               - linear = straight line fibers
%               - fourier= fibers are represented by fourier modes
%*****************************************************************************/
%*              Written by by A. Stein
%*              University of Michigan (Ann Arbor)
%*              Advisors: Len Sander and Trace Jackson
%               email: amstein@umich.edu
%
%
%*              <<Based off code by T. Stylianopoulos    >>                  */
%*              << University of Minnesota (Twin Cities) >>                  */
%*              <<   Academic Advisor: Victor Barocas    >>                  */
%*              <<    E-Mail: styliano@cems.umn.edu      >>
%*/
%*              <<        Phone: (612) 626-9032          >>                  */
%*                _______________________________________  


%*****************************************************************************/
%
%
if nargin<5
    Lmax = W/2;
end
if nargin >= 6
    rand('seed',rseed)
    randn('seed',rseed)
end
if nargin < 7
    Lp = Inf;
else
    sigma = sqrt(2*Lstep/Lp); %noise term for angular diffusion for pers. length
end

switch coltype %collision type
    case{1,'stop','T','Barocas','original'}
        Lmax = Inf;
    case{2,'Stein2','fixedlen'}
        %Lmax has been entered by the user or set above
end

NS = 2 * NF; % Number of "segments."  Since each fiber
%                       can grow in two directions, N = 2*NF
NL = NS; % Number of "living" segments

%initial seeds - declare in this way so that
%as NF increases, the network stays the same with just the addition of
%another fiber    
    X0 = zeros(NF,3);
    DX1= zeros(NF,3);
    for i=1:NF
        X0(i,:)  = W*rand(1,3);
        DX1(i,:) = rand(1,3)-0.5;
    end
    
%seeds can go in both directions, so we double the number of ends in X     
    XE(1:2:NF*2,:) = X0; %the end vertices
    XE(2:2:NF*2,:) = X0;
    X(1:NF,:)      = X0; %the total vertex list
    
%fiber directions
    D1  = sqrt(sum(DX1.^2,2));
    DX1 = DX1./(D1*ones(1,3));
    
    DX(1:2:NF*2,:) =  DX1;
    DX(2:2:NF*2,:) = -DX1;
    
% Create vector of "living" segments
    live = 1:NL;

%create a Fiber and Vertex structure
    F(NF).v = [];
    V(NF).f = [];
    for i=1:NF
        F(i).v   = i;
        F(i).len = 0;
        V(i).f   = i;
        F(i).fcon= i;
    end

%create a large vertex matrix to keep track of all vertices
    VM   = zeros(W,W,W,'uint32');
    XR   = min(max(1,round(X)),W);
    ind  = sub2ind([W W W],XR(:,3),XR(:,2),XR(:,1));
    VM(ind) = 1:size(X,1);
    
% Start adding monomer
while (NL > 0)   
   j    = floor(rand*NL)+1;  % Select fiber to update
   k    = live(j);
   fk   = ceil(k/2);
   endk = mod(k,2); %1 if beginning of fiber, 0 if at the end

   if Lp<Inf % there's a persistance length, so we update DX
        v1      = DX(k,:)';
        R       = Rcalc3(v1);
        dvloc   = [0 randn(1,2)]';
        dvloc   = sigma*dvloc/norm(dvloc);
        dv      = R'*dvloc;
        v2      = v1+dv;
        DX(k,:) = v2'/norm(v2);
        1;
   end
   
   %update structures with new position
        XE(k,:)   = XE(k,:) + Lstep*DX(k,:);  
        Xk        = XE(k,:);
        vnum      = size(X,1)+1;
        V(vnum).f = fk;
        X(vnum,:) = Xk;    
        XR(vnum,:)= min(max(1,round(Xk)),W);
       
       if endk==1
           F(fk).v = [vnum F(fk).v];
           x1 = X(vnum,:);
           v2 = F(fk).v(2);
           x2 = X(v2,:);
           F(fk).len = F(fk).len + norm(x2-x1);
       else
           F(fk).v = [F(fk).v vnum];
           v1 = F(fk).v(end-1);
           x1 = X(v1,:);
           x2 = X(vnum,:);
           F(fk).len = F(fk).len + norm(x2-x1);           
       end
   
   % Check for fiber out of the box or fiber being too long
       u(1:3) = (Xk - W);
       u(4:6) = (-Xk)     ;
       [Lu ind] = max(u);             
       
       if (Lu > 0) % Fiber out of box
           dxind = mod(ind-1,3)+1;
           Xk = Xk - DX(k,:)*Lu / abs(DX(k,dxind));
           live = setdiff(live,k);
           NL = NL-1;
       % check for fiber being too long
       elseif F(fk).len >= Lmax-eps
           live = setdiff(live,k);
           NL = NL - 1;
           Xk = Xk - (F(fk).len-Lmax)*DX(k,:);
           F(fk).len = Lmax;
       end
   
    %update matrices and structures accordingly
    
        Xr = min(max(1,round(X(vnum,:))),W);
        XR(vnum,:) = Xr;
        
    %check for collisions 
        w  = D/Lstep;   
        vnear = findclose(XR,vnum,w,VM);
        
        for fi = F(fk).fcon
            vnear = setdiff(vnear,F(fi).v);
        end
        
        if isempty(vnear) %no collisions, we're done.  add a new X            
            VM(Xr(3),Xr(2),Xr(1)) = vnum;
        else %there is a nearby vertex
            vnear = vnear(1);           
            %Keep Xk the same, but create a new vertex, Xnew
            %at the point of intersection            
                xnear       = X(vnear,:);
                xmean       = (Xk + xnear)/2;
                X(vnear,:)  = xmean;
                Xk          = xmean;
                xnearr= min(max(1,round(xnear)),W);
                xmeanr= min(max(1,round(xmean)),W);
                XR(vnum,:)  = xmeanr;
                
            %update vertex location in VM
                VM(xnearr(3),xnearr(2),xnearr(1)) = 0;
                VM(xmeanr(3),xmeanr(2),xmeanr(1)) = vnear;
                
            %update fiber and vectex indices.
                V(vnear).f(end+1)      = fk; %add fiber to V           
                F(fk).v(F(fk).v==vnum) = vnear; %replace new vertex with crosslinked one
                for fi=V(vnear).f
                    F(fk).fcon(end+1) = fi;
                    F(fi).fcon(end+1) = fk;
                end
                    
            switch coltype
                case{1,'T','Barocas','original'}
                    %kill segment in 
                        live = setdiff(live,k);
                        NL   = NL - 1;
                case{2,'Stein2','fixedlen'} %same as case1, but we don't kill the fiber
                    %don't kill any segements, just because of an
                    %intersection                       
            end
        end
   
   %update XE
        XE(k,:)     = Xk;           
        X(vnum,:)   = Xk;
        XR(vnum,:)  = min(max(1,round(Xk)),W);
        1;
end

X = max(min(X,W),0);
[X F V] = trimxfv(X,F,V);
E = fiber2edge(F,V);
