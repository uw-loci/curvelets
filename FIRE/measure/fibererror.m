function[M] = fibererror(Xt,Ft,Et,Vt,Xa,Fa,Ea,Va)
%FIBERERROR - measures properties of fibers network and compares no actual
%network
    M.a = network_stat(Xa,Fa,Ea,Va);
    M.t = network_stat(Xt,Ft,Et,Vt);
 
%calculate distance between all fibers
    v1 = Ea(:,1);
    v2 = Ea(:,2);
    x1 = Xa(v1,:);
    x2 = Xa(v2,:);
    for i = 1:size(Et,1)
        %true edge vertices
            vi1 = Et(i,1);
            vi2 = Et(i,2);

            xi1 = Xt(vi1,:);
            xi2 = Xt(vi2,:);

        %calculate distance between edges
            d12 = dcalc(xi1,x1) + dcalc(xi2,x2); %dist(Ei(i,1),E(:,1)) + dist(Ei(i,2),E(:,2))
            d21 = dcalc(xi1,x2) + dcalc(xi2,x1); %dist(Ei(i,1),E(:,2)) + dist(Ei(i,2),E(:,1))
            [d,ind]   = min([d12 d21],[],2);

        %match edges.  Ematch(i) maps true edge i to Approximated Edge Ematch(i)
            [dmatch(i) Ematch(i)] = min(d);

    end    
    
%calculate angle error
    Xt1          = Xt(Et(:,1),:);
    Xt2          = Xt(Et(:,2),:);    
    Xa1          = Xa(Ea(Ematch,1),:);
    Xa2          = Xa(Ea(Ematch,2),:);    
    Lt           = dcalc(Xt(Et(:,1),:),Xt(Et(:,2),:));        
    La           = dcalc(Xa1,Xa2);
    
    Angle        = acos(dotcalc(Xt2-Xt1,Xa2-Xa1)./(Lt.*La));    
    M.angdiff    = mean( min([Angle pi-Angle],[],2))*180/pi;
    