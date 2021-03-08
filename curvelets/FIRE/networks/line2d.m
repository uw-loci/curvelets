function[im] = line3d(im,X0,X1);
%LINE2D - draws a line in 2d from X0 to X1

%if X0==X1, just return
if all(X0==X1)
    im(X0(1),X0(2)) = 1;
    return
end

eps = 1e-10;

dir = (X1-X0)/norm(X1-X0); %find direction of line
[m i] = max(abs(dir)); %find direction of minimum increase

if X0(i) < X1(i)
    subi = (X0(i):X1(i))';
else
    subi = (X0(i):-1:X1(i))';
end
o   = ones(length(subi),1);
SUB = zeros(length(subi),2);
SUB(:,i) = subi;
       

j = setdiff(1:2,i);
SUB(:,j) = o*X0(j) + (subi-X0(i))*dir(j)/(dir(i)+eps);
SUBR = ceil(SUB);
ind  = sub2ind(size(im),SUBR(:,1),SUBR(:,2));
im(ind) = 1;