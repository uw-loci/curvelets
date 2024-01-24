function[d p] = sample_image(type)

switch type
    case 1
        w = 3;
        d(1,:,:) = zeros(w,w);
        d(2,:,:) = [0 0 0; 1 2 1; 0 0 0];
        d(3,:,:) = zeros(w,w);
        p.K = w; p.M = w; p.N = w;
    case 2
        w = 5;
        d(1,:,:) = zeros(w,w);
        d(2,:,:) = zeros(w,w);
        d(3,:,:) = [0 0 0 0 0; 0 0 1 0 0; 1 1 2 1 1; 0 1 2 1 0; 0 0 1 0 0];
        d(4,:,:) = zeros(w,w);
        d(5,:,:) = zeros(w,w);
        p.K = w; p.M = w; p.N = w;  
    case {3,'cyl','cylinder'}
        xx = -8:8;
        w  = length(xx);
        r  =  4;
        [x y z] = meshgrid(xx);
       
        ii = find( sqrt(x.^2+y.^2)<r);
        jj = find( sqrt(x.^2+z.^2)<r);
        kk = find( sqrt(y.^2+z.^2)<r);
        
        X = zeros(size(x));
        X(ii) = 1;
        X(jj) = 1;
        X(kk) = 1;
        
        d = bwdist(~X);
        p.K = w; p.M = w; p.N = w;   
        p.size = [w w w];
    case {4,'111'}
        xx = -12:12;
        r  = 3;
        [x y z] = meshgrid(xx);
        
end