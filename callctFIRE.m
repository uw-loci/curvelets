% call_ctFIRE_ex1.m

%% case 1: test ctFIRE_1.m
% clear;close all; clc;home
% [fileName pathName] = uigetfile({'*.tif';'*.tiff';'*.jpg';'*.jpeg';'*.*'},'Select Image(s)','MultiSelect','on');
% dir1 = pathName;
% 
% addpath(dir1)
% cd(dir1);
% 
% pd1 = pwd;
% imagenames = [dir1 fileName(1:3),'*.tiff'];
% Fnum = dir(imagenames);
% iNF = 1:length(Fnum);
% LW1 = 1.2;
% 
% for iN = iNF
%     
%     fname = Fnum(iN).name;
% %     fname = fileName;
%     info = imfinfo(fname);
%     num_images = numel(info);
%     pixw = info(1).Width;  % find the image size
%     pixh = info(1).Height;  
% %     fname = 'reg_03_05_08 Slide 2B-a2-01_C2.tiff';
% break
%     data = ctFIRE_1(fileName,pathName);
% %     cd(pd1);
% %     LL1 = 30;
% %     FNL = 2999;
% %     
% %     FN = find(data.M.L>LL1);
% %     FLout = data.M.L(FN);
% %     LFa = length(FN);
% % 
% %     if LFa > FNL
% %         LFa = FNL;
% %     end
% %     
% %     rng(1001)           
% %     clrr2 = rand(LFa,3); % set random color 
% %    
% %     % overlay CTpFIRE extracted fibers on the original image
% %     figure(52);clf;
% %     set(gcf,'position',[300 50 pixw/2 pixh/2]);
% %     set(gcf,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128])
% % %     imshow(IS1); colormap gray; axis xy; axis equal; hold on;
% % %     clrr0 = 'rgbmcyg';
% %     for LL = 1:LFa
% %        
% %         VFa.LL = data.Fa(1,FN(LL)).v;
% %         XFa.LL = data.Xa(VFa.LL,:);
% %         plot(XFa.LL(:,1),abs(XFa.LL(:,2)-pixh-1), '-','color',clrr2(LL,1:3),'linewidth',LW1);
% %         hold on
% %         axis equal;
% %         axis([1 pixw 1 pixh]);
% %     end
% %      set(gca, 'visible', 'off')
% %      print('-dtiff', '-r128', fOL2);
% 
% end

%% case 2:  test ctFIRE.m
clear;clc;home;
imgPath = 'Z:\liu372\CAA\images\Slide 2B man reg\'
ctFIREout = ctFIRE(imgPath);
