function[L theta phi v Vmat] = fiberhist(X,F,plotflag)

if nargin<3
    plotflag = 0;
end

N = 8;
Vmat = zeros(N,N);
for fi=1:length(F)
    v1 = F(fi).v(1);
    v2 = F(fi).v(end);
    vect  = X(v1,:) - X(v2,:);
    
    L(fi)   = sqrt(vect(1).^2 + vect(2).^2 + vect(3).^2);
    theta(fi)=mod(atan2( vect(2),vect(1) )*180/pi,180);    
    phi(fi) = mod(atan2( vect(3),vect(1) )*180/pi,180);
    
    v(fi,:) = vect/L(fi);
    
    ii = ceil(abs(v(fi,1)*N)+eps);
    jj = ceil(abs(v(fi,3)*N)+eps);
    Vmat(ii,jj) = Vmat(ii,jj)+1;    
end

if plotflag
    figure(1)
        subplot(1,3,1)
            hist(L)
            xlabel('fiber length (pixels)')
            ylabel('Frequency of occurance')
        subplot(1,3,2)
            hist(theta)
            set(gca,'XLim',[0 180])
            xlabel('angle in x-y plane')
        subplot(1,3,3)
            hist(phi)
            set(gca,'XLim',[0 180])
            xlabel('angle in x-z plane')
        setfont(15)
    figure(2)
        surf((1:N)/N,(1:N)/N,Vmat)
        xlabel('Z comp.')
        ylabel('X comp.')
end
1;
