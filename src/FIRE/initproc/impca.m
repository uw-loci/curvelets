function[lam V cm] = impca(A,plotflag);
%IMPCA - performs PCA on an image (in 2D or 3D)
%another way so say this is it computes the principle axes of rotation
%equating the pixel intensity to a mass

eps = 1e-10;
if nargin<2
    plotflag = 0;
end
    

dim = ndims(A);

a = double(A(:));
asum = sum(a);
s = size(A);

%compute centers of mass mx,my,mz
    if dim==2
        [Y X] = ndgrid(1:s(1),1:s(2));
    else
        [Z Y X] = ndgrid(1:s(1),1:s(2),1:s(3));
        z = Z(:);
        mz    = sum(a.*z)/(asum + eps);
        zc= z-mz;
    end
    y = Y(:);
    x = X(:);
    mx    = sum(a.*x)/(asum + eps);
    my    = sum(a.*y)/(asum + eps);
    xc    = x-mx;
    yc    = y-my;
    
    cm    = [mx my mz]; %center of mass
    
%compute the covariance matrix
    C(1,1) = sum( (a.*xc).^2 );
    C(2,1) = sum( (a.*xc).*(a.*yc) );
    C(1,2) = C(2,1);
    C(2,2) = sum( (a.*yc).^2 );
    
    if dim==3
        C(3,3) = sum( (a.*zc).^2 );
        C(1,3) = sum( (a.*xc).*(a.*zc));
        C(2,3) = sum( (a.*yc).*(a.*zc));
    end
    
%compute eigen vectors of covariance matrix
    [V D] = eig(C);
    [lam ind]   = sort(diag(D),1,'descend');
    V = V(:,ind); %sorted right way
    
%plot result
    if plotflag==1
        if dim==2
            clf
            imagesc(A);
            hold on
            colormap gray
            plot(mx,my,'bo')
            M = max(abs(lam));
            h = quiver(mx,my,lam(1)*V(1,1)/M,lam(1)*V(2,1)/M);
            set(h,'Color','r','LineWidth',2);
            h = quiver(mx,my,lam(2)*V(1,2)/M,lam(2)*V(2,2)/M);
            set(h,'Color','r','LineWidth',.5,'LineStyle','--');
            axis image
            hold off
        elseif dim==3
            v      = V(:,1)/norm(V(:,1));
            t=(1:-.1:-1)';            
            X0 = [mx-t*s(3)/2*v(1) my-t*s(2)/2*v(2) mz-t*s(1)/2*v(3)];
            F(1).v = [1:size(X0,1)];
            image3_fiber(A,X0,F,.2,1);
            1;
        end
    end
