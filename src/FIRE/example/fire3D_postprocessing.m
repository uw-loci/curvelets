% fire3D_postprocessing.m
clear,clc,home
outputDir = pwd;
outputFile = 'fire3D_test1_output.mat';

load(fullfile(outputDir,outputFile),'data')

%datafields = fieldnames(data)
% 
% datafields =
% 
%   16×1 cell array
% 
%     {'X'    }
%     {'F'    }
%     {'R'    }
%     {'Xa'   }
%     {'Fa'   }
%     {'Va'   }
%     {'Ea'   }
%     {'Ra'   }
%     {'Xab'  }
%     {'Fab'  }
%     {'Vab'  }
%     {'Xc'   }
%     {'Fc'   }
%     {'Vc'   }
%     {'M'    }
%     {'xlink'}

LL1 = 10; %length threshold 
LW1 = 2; % line width for the extracted fibers
FN = find(data.M.L > LL1);
FLout = data.M.L(FN);
LFa = length(FN);
rng(1001,"twister");
clrr1 = rand(LFa,3); % set random color
gcf51 = figure(51);clf;
set(gcf51,'name','FIRE3d output: extracted fibers ','numbertitle','off')
% 

for LL = 1:LFa
    VFa.LL = data.Fa(1,FN(LL)).v;
    XFa.LL = data.Xa(VFa.LL,:);
    plot3(XFa.LL(:,1),XFa.LL(:,2),XFa.LL(:,3), '-','color',clrr1(LL,1:3),'linewidth',LW1);
    hold on  
end
axis ij
axis equal;
xlim auto
ylim auto
zlim auto
% set(gca, 'visible', 'off')
% set(gcf51,'PaperUnits','inches','PaperPosition',[0 0 pixw/128 pixh/128]);
% set(gcf51,'Units','normal');
% set (gca,'Position',[0 0 1 1]);
% print(gcf51,'-dtiff', ['-r',num2str(RES)], fOL1);  % overylay FIRE extracted fibers on the original image
% imshow(fOL1);
% set(gcf51,'Units','pixel');
% set(gcf51,'position',[0.005*sw0 0.1*sh0 0.75*sh0,0.75*sh0*pixh/pixw]);