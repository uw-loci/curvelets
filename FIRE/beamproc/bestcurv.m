function[AL AR] = bestcurv(X,pins,lam,plotflag)
%FIBERAPPROX - approximate a fiber, represented by Xpts, with a series of 3
%nodes, using the interpolation functions in Bathe79.
%
%X = (nx3) matrix of nodal positions
%pins = a set of indices, indicating which X vertices are fixed 
%lam  = regularization constant
%plotflag - if nonzero, it will plot the interpolated fiber
%
%bestcurv(X,pins,lam,plotflag)
    if nargin<4
        plotflag=0;
    end
    H1 = inline('x.^3-2*x.^2+x','x');
    H2 = inline('-x.^3 + x.^2','x');
       
    for i=1:length(pins)-1
        %compute subfiber positions
            ii = pins(i):pins(i+1);
            Xi = X(ii,:);
        
        if size(Xi,1)<=2 %no need for optimization
            AL(i,:) = [0 0];
            AR(i,:) = [0 0];
        else
            %calculate rotation matrix
                X1 = Xi(1,:);
                Xi = Xi-ones(size(Xi(:,1)))*X1;
                R  = Rcalc3(Xi(end,:));

            %transform X to local coordinate system
                Xir = (R*Xi')';
                L   = Xir(end,1); %length of x

                if L==0
                    AL(i,:) = [0 0];
                    AR(i,:) = [0 0];
                else
                    x   = Xir(:,1)/L;
                    y   = Xir(:,2);
                    z   = Xir(:,3);

                    %compute the Hermite polynomials
                        h1  = H1(x);
                        h2  = H2(x);

                    %construct matrices for minimization of least squared errors
                    %solve for constants
                        A(1,1) = (lam + sum(h1.^2));
                        A(1,2) = (sum(h1.*h2));
                        A(2,1) = A(1,2);
                        A(2,2) = sum(lam + sum(h2.^2));

                        By(1,1) = sum(h1.*y);
                        By(2,1) = sum(h2.*y);
                        Bz(1,1) = sum(h1.*z);
                        Bz(2,1) = sum(h2.*z);                

                        cy = A\By;
                        cz = A\Bz;

                    AL(i,:) = [cy(1) cz(1)];
                    AR(i,:) = [cy(2) cz(2)];
                end
        end
    end        
    
    %plot result
        if plotflag
            clf
            plotbeam(X(pins,:),AL,AR,1);
            hold on
            plot3(X(:,1),X(:,2),X(:,3),'rx')
            hold off
            xlabel('x'); ylabel('y'); zlabel('z')
        end
end