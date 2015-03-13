function[Lp] = calc_persistent2(X,F,plotflag)
%CALC_PERSISTANT - calculates the persistance length of fibers

warning off
if nargin<3
    plotflag = 0;
end

Lp   = zeros(length(F),1);

opt = optimset;
opt = optimset(opt,'Display','off');

for fi=1:length(F)
    v = F(fi).v;
    n  = length(v);

    nn = (n-2)*(n-1)/2;
    
    dot = zeros(nn,1);
    L      = zeros(nn,1);
    
    ii = 0;
    for i=1:n-2
        vi1 = v(i);
        vi2 = v(i+1);
        xi1 = X(vi1,:);
        xi2 = X(vi2,:);
        dxi  = xi2-xi1;
        ti   = dxi/(norm(dxi)+eps);
        
        for j=i+1:n-1
            ii = ii+1;
            
            vj1 = v(j);
            vj2 = v(j+1);
            xj1 = X(vj1,:);
            xj2 = X(vj2,:);
            dxj  = xj2-xj1;
            tj   = dxj/(norm(dxj)+eps);
            
            dot(ii)= sum( ti     .*tj      );
            L(ii)= norm(xi1-xj1);
                        
        end
    end
    
    %fit curve    
        m = lsqnonlin(@errfun,0,[],[],opt,L,dot);
        %m = (log(dot)'*L) / (L'*L);
        Lp(fi) = -1/m;
                
    if plotflag==1
        clf
        subplot(2,1,1)
            plotfiber(X,F(fi),2,0,[],'o');
            title(sprintf('Fiber %d',fi))
            axis equal
        subplot(2,1,2)
            hold on
            l = 0:max(L)/50:max(L);
            plot(L,dot,'.')
            plot(l,exp(-l./Lp(fi)),'b','LineWidth',2)
            title(sprintf('Lp = %2.1f',Lp(fi)));
    end
    1;
end    
warning on

function[err] = errfun(m,x,y)
    err = exp(m*x) - y;
    if any(isnan(err) | isinf(err))
        keyboard
    end