function[vi vj] = sample_image(in,shift)

switch in
    case 1
        rr = 3;
        
        [x y] = meshgrid(-5.1:.2:5.1);
        ri = sqrt(x.^2 + y.^2); %add circle
        ii = find( x>= 2 & x <=4 & y >=1 & y <=2 );
        
        vi = zeros(size(x));
        vi = double(ri < rr);
        vi(ii) = 2;
        
        if ~exist('shift')
            shift = [2 0];
        end
        vj = volshift(vi,shift);
end