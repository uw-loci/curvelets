function[Lp_xy Lp_xz Lp3] = calc_persistent(X,F,plotflag)
%CALC_PERSISTANT - calculates the persistance length of fibers

if nargin<3
    plotflag = 0;
end
dim = size(X,2);

Lp_xy = zeros(length(F),1);
Lp_xz = zeros(length(F),1);
Lp3   = zeros(length(F),1);

for fi=1:length(F)
    fv = F(fi).v;
    n  = length(fv);

    D       = zeros(n-1,1);
    CDA_xy  = zeros(n-1,1);
    CDA_xz  = zeros(n-1,1);
    CDA3    = zeros(n-1,1);
    CDAS_xy = zeros(n-1,1);
    CDAS_xz = zeros(n-1,1);
    CDAS3   = zeros(n-1,1);
    
    D(1)    = 0;
    CDA_xy(1)=1;
    CDA_xz(1)=1;
    CDA3(1)  =1;
    
    if n >= 3
        %rotate fiber so that it lies along x axis
            Xi = X(fv,:);
            Xi = Xi - ones(n,1)*Xi(1,:);
            if dim==2
                R  = Rcalc2(Xi(n,:));
            else
                R  = Rcalc3(Xi(n,:));
            end
            Xi = (R*Xi')';
        
        %calculate xy and xz angle   
            i1 = 1:n-1;            
            i2 = 2:n;
            
            x1 = Xi(i1,1);
            x2 = Xi(i2,1);
            y1 = Xi(i1,2);
            y2 = Xi(i2,2);            
            a_xy = atan2(y2-y1,x2-x1);        
            d  = sqrt( (y2-y1).^2 + (x2-x1).^2 );
            
            if dim==3
                z1 = Xi(i1,3);
                z2 = Xi(i2,3);
                a_xz = atan2(z2-z1,x2-x1);
                d  = sqrt(d.^2 + (z2-z1).^2);
                a3 = a_xy + a_xz;
            end
            
        %calculate cosine correlation function    
            dtau = zeros(size(i1'));
            for tau=1:n-2
                i1 = 1:n-1-tau;            
                i2 = tau+1:n-1;

                dtau = dtau(1:end-1) + d(1+tau:end);               
                D(tau+1) = mean(dtau);
                
                cda_xy = cos(a_xy(i2)-a_xy(i1));           
                CDA_xy(tau+1) = mean(cda_xy);
                CDAS_xy(tau+1)= std(cda_xy)/sqrt(length(D));

                if dim==3
                    cda_xz = cos(a_xz(i2)-a_xz(i1));
                    CDA_xz(tau+1) = mean(cda_xz);
                    CDAS_xz(tau+1)= std(cda_xz)/sqrt(length(D));
                    
                    cda3   = cos(a3(i2)-a3(i1));
                    CDA3(tau+1) = mean(cda3);                    
                    CDAS3(tau+1)= std(cda3)/sqrt(length(D));
                end

                1;
            end

        ind = find(diff(CDA_xy)>0 | diff(CDA_xz)>0 | diff(CDA3)>0 | CDA3(1:end-1)<.45);
        if isempty(ind)
            ind = length(D);
        end
        istop = ind(1);    

        %compute persistance
            a = polyfit(D(1:istop),log(CDA_xy(1:istop)),1);
            beta_xy = a(1);
            A_xy    = exp(a(2));
            Lp_xy(fi) = (-1/(2*beta_xy));
            if abs(real(Lp_xy(fi)))==Inf
                Lp_xy(fi) = NaN;
            end
            Lp_xz(fi) = NaN;
            Lp3(fi)   = NaN;

            if dim==3
                a = polyfit(D(1:istop),log(CDA_xz(1:istop)),1);
                beta_xz = a(1);
                A_xz = exp(a(2));
                Lp_xz(fi) = (-1/(2*beta_xz));
                if abs(real(Lp_xz(fi)))==Inf
                    Lp_xz(fi)=NaN;
                end
                
                a = polyfit(D(1:istop),log(CDA3(1:istop)),1);
                beta3 = a(1);
                A3    = exp(a(2));
                Lp3(fi) = (-1/(beta3));
                if abs(real(Lp3(fi)))==Inf
                    Lp3(fi)=NaN;
                end
            end
    
            
    %plot result
        if plotflag == 1
            clf
            subplot(dim,1,1)
                hold on
                errorbar(D,CDA_xy,CDAS_xy)
                plot(D,A_xy*exp(beta_xy*D),'r')
                %set(gca,'YScale','log');
                title(sprintf('Lp-xy = %2.2f',Lp_xy(fi)));
                set(gca,'YLim',[0 1])

            if dim==3
                subplot(dim,1,2)
                    hold on
                    errorbar(D,CDA_xz,CDAS_xz)
                    plot(D,A_xz*exp(beta_xz*D),'r')
                    %set(gca,'YScale','log');
                    title(sprintf('Lp-xz = %2.2f',Lp_xz(fi)));           
                    set(gca,'YLim',[0 1])

                subplot(dim,1,3)
                    hold on
                    errorbar(D,CDA3,CDAS3)
                    plot(D,A3*exp(beta3*D),'r')
                    %set(gca,'YScale','log');
                    title(sprintf('Lp3 = %2.2f',Lp3(fi)));           
                    set(gca,'YLim',[0 1])
                if real(Lp_xz)
                    if real(Lp3(fi))==Inf
                        Lp3(fi) = NaN;
                    end
                end
            
            end
                hold off
                pause(.001)
        end    
    else
        Lp_xy(fi) = NaN;
        Lp_xz(fi) = NaN;
        Lp3(fi)   = NaN;
    end
end    
    1;
