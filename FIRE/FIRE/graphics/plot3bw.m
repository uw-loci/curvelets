function[] = plot3d(bw,ms,col)
if ~iscell(bw)
    BW{1} = bw;
else
    BW    = bw;
end
if nargin<2
    ms = 1;
end
if nargin<3
    col = 'k';
end

for i=1:length(BW)
    bw = BW{i};
    ind = find(bw);
    [z y x] = ind2sub(size(bw),ind);
    plot3(x,y,z,'.','MarkerSize',ms,'Color',col);
end

