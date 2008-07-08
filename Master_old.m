% Set the percentage of coefficients used in the partial reconstruction 
pctg = .01;
tic
%% Import Image
cd '/home/doot4runner/Documents/Research/finding collagen/TACS Images' 
% img = imread('1.jpg'); 
% img = imread('TACS-2a.jpg'); 
% img = imread('TACS-2b.tif'); 
% img = imread('TACS-2c.tif'); 
% img = imread('TACS-2d.jpg'); 
% img = imread('TACS-2e.jpg'); 
% img = imread('TACS-2f.jpg'); 
% img = imread('TACS-2g.tif'); 
% img = imread('TACS-2h.tif'); 
% img = imread('TACS-2i.tif'); 
% img = imread('TACS-2j.tif'); 
% img = imread('TACS-2k.tif'); 
% img = imread('TACS-2l.tif'); 
% img = imread('TACS-3a.jpg'); 
% img = imread('TACS-3b.jpg'); 
% img = imread('TACS-3c.jpg'); 
% img = imread('TACS-3d.jpg'); 
% img = imread('TACS-3e.tif'); 
% img = imread('TACS-3f.tif'); 
% img = imread('TACS-3g.tif'); 
% img = imread('TACS-3h.tif'); 
% img = imread('TACS-3j.tif'); 
% img = imread('TACS-3k.tif'); 
% img = imread('TACS-3l.tif'); 

img = double(img(1:512,1:512,1)); % Peel off one layer and make the image dyadic
figure;image(real(img)/4); axis('image'); colormap(gray); title('Original Image'); 
cd '/home/doot4runner/Documents/Research/finding collagen/Wrapping'
%% Take the curvelet transform
C = fdct_wrapping(img,1);

%% Apply a gradient so that the edges are zero

pixin = 2; % number of pixels to indent

for s = 1:length(C)
    for w = 1:length(C{s})
        sub=size(C{s}{w});
        for ii = 1:sub(2);
            C{s}{w}(end-pixin:end,ii)=linspace(C{s}{w}(end-pixin,ii),0,pixin+1);
        end
        for ii = 1:sub(2);
            C{s}{w}(1:1+pixin,ii)=fliplr(linspace(C{s}{w}(1+pixin,ii),0,pixin+1));
        end
        for ii = 1:sub(1);
            C{s}{w}(ii,end-pixin:end)=linspace(C{s}{w}(ii,end-pixin),0,pixin+1);
        end
        for ii = 1:sub(1);
            C{s}{w}(ii,1:1+pixin)=fliplr(linspace(C{s}{w}(ii,1+pixin),0,pixin+1));
        end
    end
end



%% Get threshold value
cfs =[];
for s=1:length(C)
  for w=1:length(C{s})
    cfs = [cfs; abs(C{s}{w}(:))];
  end
end
cfs = sort(cfs); cfs = cfs(end:-1:1);
nb = round(pctg*length(cfs));
cutoff = cfs(nb);

% Set small coefficients to zero
for s=1:length(C)
  for w=1:length(C{s})
    C{s}{w} = C{s}{w} .* (abs(C{s}{w})>cutoff);
  end
end

C{1}{1} = zeros(size(C{1}{1}));
 
%% Take the inverse curvelet transform
 
img_rec_all = ifdct_wrapping(C,1);
img_rec_all = img_rec_all.*(img_rec_all>0);
% 
figure; image(img_rec_all); axis('image'); colormap(gray); title(['Curvelet Transformed Image']);

% overlap_plot(abs(img),abs(img_rec_all));
%% Take the inverse curvelet transform with zeroing out all the coefficients but one
  
%Create a cell full of zeros the correct size

for xx = 1:length(C)
    for yy = 1:length(C{xx})
        Z{xx}{yy} = zeros(size(C{xx}{yy}));
    end
end

for xx = 1:length(C)
    for yy = 1:length(C{xx})
         img_add{xx}{yy} = zeros(size(C{xx}{yy}));
    end
end

% Pick off single coeffcient table and combine with cell of zeros
% 
% counter = 1; %this is just for saving picture files
for xx = 1:length(C)
  for yy = 1:length(C{xx})
       Z{xx}{yy} = C{xx}{yy}; 
       img_rec = ifdct_wrapping(Z,1);
       figure;
       spy(img_rec)
       figure;
       image(img_rec); axis('image'); colormap(gray); title(['partial reconst. with zeroing out all coeffs. but at C' num2str(xx) ',' num2str(yy)]);        
       drawnow
       pause
%        cd '/Users/doot4runner/Documents/Research/Curvelets/Finding Collagen/Pics'
%        saveas(gcf,num2str(counter),'jpg')
%        cd '/Users/doot4runner/Documents/Research/Curvelets/Finding Collagen/ifdct'
       img_add{xx}{yy} = img_rec;
       Z{xx}{yy} = zeros(size(C{xx}{yy})); % Reset the values.
%        counter = counter + 1
   end
end
% angle_1coeff = splitAngle(C,1);
% angle_2coeff = splitAngle(C,2);
% angle_3coeff = splitAngle(C,3);
% angle_4coeff = splitAngle(C,4);
% 
% angle_1rec = ifdct_usfft(angle_1coeff,1);
% angle_2rec = ifdct_usfft(angle_2coeff,1);
% angle_3rec = ifdct_usfft(angle_3coeff,1);
% angle_4rec = ifdct_usfft(angle_4coeff,1);
  
toc
%%
% curve_img = angle_1rec+angle_2rec+angle_3rec+angle_4rec;
% img1 = scaleColor(img_add,1);
% img2 = scaleColor(img_add,2);
% img3 = scaleColor(img_add,3);
% img4 = scaleColor(img_add,4);
% niceTry1 = addCell(img1);
% niceTry2 = addCell(img2);
% niceTry3 = addCell(img3);
% niceTry4 = addCell(img4);
% blah1 = angle_1rec.*(abs(angle_1rec)>1/3*max(max(angle_1rec)));
% blah2 = angle_2rec.*(abs(angle_2rec)>1/3*max(max(angle_2rec)));
% blah3 = angle_3rec.*(abs(angle_3rec)>1/3*max(max(angle_3rec)));
% blah4 = angle_4rec.*(abs(angle_4rec)>1/3*max(max(angle_4rec)));
% overlap_plot(abs(img),abs(blah1),'red');
% overlap_plot(abs(img),abs(blah2),'green');
% overlap_plot(abs(img),abs(blah3),'blue');
% overlap_plot(abs(img),abs(blah4),'orange'); 
% figure;image(real(img)/4); axis('image'); colormap(gray); title('Original Image'); 
% figure;image(real(curve_img)/2); axis('image'); colormap(gray); title('Curvelet Transformed Image'); 


