function[vertex_matrix, indic_matrix] = make_vertexmatrix(X,s,xsubset,indic)
%MAKE_VERTEXMATRIX - returns an array of the same dimension of the image,
%that is zeros everywhere, but one where a vertex is present.

if nargin<3
    xsubset = 1:size(X,1);
end

if size(X,1) < 2^16-1
    vertex_matrix = zeros(s,'uint16');
else
    vertex_matrix = zeros(s,'uint32');
end

Xr = round(X);

ind = sub2ind(s,Xr(xsubset,3),Xr(xsubset,2),Xr(xsubset,1));
vertex_matrix(ind) = xsubset;

if nargin==4
    if size(X,1) < 2^16-1
        indic_matrix = zeros(s,'uint16');
    else
        indic_matrix = zeros(s,'uint32');
    end
    indic_matrix(ind) = indic;
end