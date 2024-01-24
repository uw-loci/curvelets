function[v] = smooth(v,sigma)
%SMOOTH - smooths v by convolving with a gaussian box of radius r
if all(sigma)==0
    vs = v;
    return
end
if length(sigma)==1
    s(1:ndims(v)) = sigma;
elseif length(sigma)==ndims(v)
    s = sigma;
else
    error('improper input for sigma')
end

    R = ceil(2*s);
    x1 = -R(1):R(1); n1 = length(x1);
    x2 = -R(2):R(2); n2 = length(x2);
    
    gx1= exp(-x1.^2/(2*s(1)^2));
    gx1= gx1/sum(gx1);
    gx1= reshape(gx1,n1,1);
    
    gx2= exp(-x2.^2/(2*s(2)^2));
    gx2= gx2/sum(gx2);
    
if ndims(v)==3   
    x3 = -R(3):R(3); n3 = length(x3);
    
    gx3= exp(-x3.^2/(2*s(3)^2));
    gx3= gx3/sum(gx3);
    gx3= reshape(gx3,1,1,n3);
end

v = imfilter(v,gx1,'same');
v = imfilter(v,gx2,'same');
if ndims(v)==3
    v = imfilter(v,gx3,'same');
end
1;