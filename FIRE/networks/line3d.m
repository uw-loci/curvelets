function[vol] = line3d(vol,X0,X1)
%LINE3D - adds ones to the volume (vol) going from X0-X1
%
%line3d(vol,X0,X1)

s = size(vol);

%if X0==X1, just return
if all(X0==X1)
    if all(X0<=s) || all(X0>=1)            
        vol(X0(1),X0(2),X0(3)) = 1;
    end
    return
end

dir = (X1-X0)/norm(X1-X0); %find direction of line
[m i] = max(abs(dir)); %find direction of minimum increase

if X0(i) < X1(i)
    subi = (X0(i):X1(i))';
else
    subi = (X0(i):-1:X1(i))';
end
o   = ones(length(subi),1);
SUB = zeros(length(subi),3);
SUB(:,i) = subi;
       

j = setdiff(1:3,i);
SUB(:,j) = o*X0(j) + (subi-X0(i))*dir(j)/dir(i);
SUBR = ceil(SUB-1e-5);

ind_remove = find(SUBR(:,1)<1 | SUBR(:,1) > s(1) | SUBR(:,2) < 1 | SUBR(:,2) > s(2) | SUBR(:,3) < 1 | SUBR(:,3) > s(3) );
if ~isempty(ind_remove)
    SUBR(ind_remove,:) = [];
end

ind  = sub2ind(size(vol),SUBR(:,1),SUBR(:,2),SUBR(:,3));
vol(ind) = 1;