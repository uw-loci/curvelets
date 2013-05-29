function[alignment Ohist] = est_orientation(P,U,vect)
%EST_ALIGNMENT(P,U,vect) - look at the fiber alignment

if nargout >=3
    histflag = 1;
else
    histflag = 0;
end

X0 = P.X0;
F  = P.F;

if histflag
    thetaN = 10;
    phiN   = 10;
    Ohist = zeros(thetaN,phiN);
    Anorm = zeros(thetaN,phiN);

    theta_range = (0:thetaN)/thetaN*2*pi;
    phi_range   = (0:phiN)/phiN*pi/2;
    for it = 1:thetaN
        for ip = 1:phiN
            Anorm(it,ip) = 2*(sin(phi_range(ip+1))-sin(phi_range(ip)))*(theta_range(it+1)-theta_range(it));
        end
    end
end
    
%order_param = zeros(size(U,2),1);
%order_param_norm = zeros(size(U,2),1);
alignment = zeros(size(U,2),1);
for ui=1:size(U,2)
    Ui = v2m(U(1:numel(X0),ui),P.dim);
    X  = X0 + Ui;
    
    O     = zeros(3);
    Onorm = zeros(3);
    Lsqtot= 0;
    ei = 0;
    for fi=1:length(F)
        v = F(fi).v;
        for iv=1:length(v)-1
            ei = ei+1;
            
            %calculate direction
                v1 = v(iv);
                v2 = v(iv+1);

                x1 = X(v1,:);
                x2 = X(v2,:);

                di = x2-x1;
                di(3) = abs(di(3)); %we restrict ourselves to z>0, since fibers don't have a direction

                Li = norm(di);
                Lsqtot = Lsqtot + Li^2;
                dnormi = di/Li;

            %calculate orientation matrixw
                O = O + di'*di;
                Onorm = Onorm + dnormi'*dnormi;

            %calculate histogram
                if histflag
                    theta = atan2(di(2),di(1));
                    if theta < 0
                        theta = theta + 2*pi;
                    end
                    xyl   = sqrt(di(1).^2 + di(2).^2);
                    phi   = atan2(di(3),xyl);

                    itheta = max(1,ceil(theta/(2*pi)*thetaN));
                    iphi   = ceil(phi/(pi/2)*phiN);

                    if itheta == 0
                        itheta = 1;
                    end
                    if iphi == 0
                        iphi = 1;
                    end

                    Ohist(itheta,iphi) = Ohist(itheta,iphi) + Li;        
                end
        end
    end
    ne = ei;
    
    O = O/sum(Lsqtot);
    Onorm = Onorm/ne;

    alignment(ui) = vect*O*vect';
    %eigvals(ui,:) = eig(O);
    %order_param(ui) = max(eig(O)-1/3)*3/2;
    %order_param_norm(ui) = max(eig(Onorm)-1/3)*3/2;
    
    if histflag
        Ohist(:,end) = [];
        Anorm(:,end) = [];
        [T P] = ndgrid(theta_range(1:end-1),phi_range(2:end-1));
        surf(P,T,Ohist./Anorm)
        keyboard
    end
end
1;
