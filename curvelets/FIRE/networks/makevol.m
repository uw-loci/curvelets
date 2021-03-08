function[vol] = makevol(X,F,q,kernel,fname,imtype,writeflag)
%MAKEVOL - makes an image volume

if nargin < 5
    fname = 'temp';
end
if nargin < 6
    imtype = 'tif';
end
if nargin < 7
    writeflag = 0;
end

if length(q.W)==1
    q.W = [q.W q.W q.W];
end

% get the network
    Xr = round(X);
    
%make a 3d volume from image
    fprintf('   making binary volume: ');
    tic;
    vol = zeros(q.W(3),q.W(2),q.W(1),'uint8');
    vol = net2vol(vol,fliplr(Xr),F);
    
    if isfield(kernel,'x')
        vol = imfilter(vol,kernel.x,'symmetric','same');
        vol = imfilter(vol,kernel.y,'symmetric','same');
        vol = imfilter(vol,kernel.z,'symmetric','same');
    else
        vol = imfilter(vol ,kernel  ,'symmetric','same');
        vol = uint8(255)*uint8(vol>0);
    end
    fprintf(' %2.2f min\n',toc/60);
    
%organize X as (z,y,x) to be consistent
    X = fliplr(X); %organize as (z,y,x)
    
%output images to files
    fprintf('   writing volume: ');
    tic;
    if writeflag == 1
        if ~isempty(fname)
            im3write(vol,fname,imtype)
        end
    end
    fprintf(' %2.2f min\n',toc/60);