function[Xtrue,Ftrue,Xapp,Fapp] = rand3dnet(q)
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
%*                _______________________________________  
%*****************************************************************************/
%
%
tic;
fprintf('   drawing fibers: ')

W       = q.W;
Lstep   = q.Lstep;
coltype = q.coltype;
rand('seed',q.rseed)

sigma = sqrt(2*Lstep./Lp); %noise term for angular diffusion for pers. length

%initialize first fiber
    i=1;
    
    x0 = W*rand(1,3);
    d1 = rand(1,3)-0.5;
    d1 = dx/norm(dx);   
    d2 = -d1;

    X(i,:) = x0;
    F(i).v = 1;
    F(i).len = 0;

    
    
% Start adding monomer
Ltot = 0;
while (Ltot < q.Ltarget)     %while the total length of fibers in the network is less than Ltargen
    while (L<Lmax(i))        %while the length of fiber i is less than the maximal length of fiber i
        if length(F(i).v==1) %if we've started a brand new fiber
            rnum = rand(1);
        end  % YL: add the 'end'
%YL: comment out the syntax error          
%             if
%         
%     if length(F(i)
        
    end  % YL: add the 'end', this function seems not complete and is not used in fiber extraction
   endk = mod(k,2); %1 if beginning of fiber, 0 if at the end

   if Lp(fk)<Inf % there's a persistance length, so we update DX
        v1      = DX(k,:)';
        R       = Rcalc3(v1);
        dvloc   = [0 randn(1,2)]';
        dvloc   = sigma(fk)*dvloc/norm(dvloc);
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
        %XR(vnum,:)= min(max(1,round(Xk)),W);
       
       if endk==1
           F(fk).v = [vnum F(fk).v];
           x1 = X(vnum,:);
           v2 = F(fk).v(2);
           x2 = X(v2,:);
           seglen(k) = seglen(k) + norm(x2-x1);
       else
           F(fk).v = [F(fk).v vnum];
           v1 = F(fk).v(end-1);
           x1 = X(v1,:);
           x2 = X(vnum,:);
           seglen(k) = seglen(k) + norm(x2-x1);
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
       elseif seglen(k) >= Lmax(fk)-eps
           live = setdiff(live,k);
           NL = NL - 1;
           Xk = Xk - (seglen(k)-Lmax(fk)/2)*DX(k,:);
       end
    
   %update XE
        XE(k,:)     = Xk;           
        X(vnum,:)   = Xk;
        %XR(vnum,:)  = min(max(1,round(Xk)),W);
        1;
end
fprintf(' %2.2f min\n',toc/60);

fprintf('   boxifying elements for cross-link identification: ');
    tic;
    [B E Ecent] = boxify(X,F,Lstep,W);
fprintf(' %2.2f min\n',toc/60);
fprintf('   identifying cross-links: ')    
    tic;
    [Xtrue Ftrue] = insert_xlinks(X,F,E,V,B,Ecent,q,0);
fprintf(' %2.2f min\n',toc/60);
fprintf('   identifying apparent cross-links: ')    
    tic;
    %we scale X down to sort of properly account for the blurring
        ss = ones(size(X,1),1)*( q.D./(q.D+4*fliplr(q.postsigma)));
        Xred = X.*ss;        
        [Xappred Fapp] = insert_xlinks(Xred,F,E,V,B,Ecent,q,0);
        ss = ones(size(Xappred,1),1)*( q.D./(q.D+4*fliplr(q.postsigma)));
        Xapp = Xappred./ss;                
fprintf(' %2.2f min\n',toc/60);

Xtrue = max(min(Xtrue,W),0);
Xapp  = max(min(Xapp,W),0);