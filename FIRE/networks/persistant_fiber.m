function[a,b,curve] = persistant_fiber(L,Lp,N,M,plotflag)
%PERSISTANT_FIBER - gets a random set of fourier coefficients for a fiber of
%length L and persistance length Lp
%
%based on eqs. 3 and 21 from VanDillen et. al., 2006 in the arXiv 0611230

if nargin<3
    N = [];
end
if isempty(N)
    N = max(10,ceil(10*L/Lp)); %number of modes
end

%find the fourier coefficients
    q = pi*(1:N)/L; %frequency of mode
    s = 1./(sqrt(Lp) * q); %standard dev. of random variable (Eq. 4) 
    a = randn(1,N).*s;
    b = randn(1,N).*s;

%find the actual curve (if asked for in the output)
    if nargout>2
        if nargin<4
            M = 100; %number of points in curve
        end  
        t = L*(1:M)'/M;

        curve(:,1)   = t;
        curve(:,2:3) = 0;

        for n=1:N
            curve(:,2) = curve(:,2) + a(n)*sin(q(n)*t);
            curve(:,3) = curve(:,3) + b(n)*sin(q(n)*t);
        end

        if nargin>=5
            if plotflag
                plot3(curve(:,1),curve(:,2),curve(:,3))
                axis([0 L -L/2 L/2 -L/2 L/2])
            end
        end
    end