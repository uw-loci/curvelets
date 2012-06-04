% readTrace.m
%
% reads in image channels, designates outputs according to user choices
% Inputs:
% num = number of channels
% names = names of image channels
% filePath = location of images
% anals = user selected analyses
% outFolder = location to write output
% intT = intensity threshold
% curvT = curvelet coefficient threshold
% roi = pixel width of outer ROI
% numR = number of regions in timeseries analysis
%
% Written by Carolyn Pehlke
% Laboratory for Optical and Computational Instrumentation
% April 2012

function readTrace(num,names,filePath,anals,outFolder,intT,curvT,roi,varargin)

numR = 0;
if nargin == 9
    numR = varargin{1};
end

% initialize image data structure
    IMG = cell(num,1);
    wb1 = waitbar(0,'Reading Images','Position',[150 300 300 75]);
% read in images from file
    for aa = 1:num
        slices = length(imfinfo(filePath{aa})); 
        imgStack = cell(length(slices),1);
        for bb = 1:slices
            tempi = imread(filePath{aa},bb);
            imgStack{bb}(:,:,:,:) = tempi; 
        end
        IMG{aa} = imgStack;
        waitbar(aa/num)
    end
    close(wb1)
% initialize variables
    pts = [];
    plots = cell([num 1]);
    alignVal = 0;
    dats = cell([num 1]);
    timeDats = cell([num 1]);
% perform selected operations on each image   
    for cc = 1:num
        switch anals{cc}
% operations for the mask/morphology channel
            case 'Mask/Morphology'
                
                % find initial starting point for timeseries regions
                [~,~,~,~,~,~,RR,CC] = cellTrace(IMG{cc}{1},intT);
                % initialize variables
                BW = cell(1,length(IMG{cc}));
                BWborder = cell(1,length(IMG{cc}));
                BWmask = cell(1,length(IMG{cc}));
                cent = cell(1,length(IMG{cc}));
                r = cell(1,length(IMG{cc}));
                c = cell(1,length(IMG{cc}));
                r1 = cell(1,length(IMG{cc}));
                c1 = cell(1,length(IMG{cc}));
% find outlines, create masks
                wb2 = waitbar(0,'Finding Outlines','Position',[150 300 300 75]);
                for dd = 1:length(IMG{cc})   
                [BW{dd},BWborder{dd},BWmask{dd},cent{dd},r{dd},c{dd},r1{dd},c1{dd}] = cellTrace(IMG{cc}{dd},intT,RR,CC);  
                RR = r{dd}(1);
                CC = c{dd}(1);
                waitbar(dd/length(IMG{cc}))
                end
                close(wb2)

% find filter size for creating other ROIs from mask
                kSize = roi; 
% create other ROIs from mask
                if numR == 0
                    [BWshow,tempInner,tempOuter] = bwROIs(BWborder,BWmask,names{cc},kSize,numR,r,c,outFolder);
                else
                    [BWshow tempInner tempOuter BWinner BWouter tempBorder pts] = bwROIs(BWborder,BWmask,names{cc},kSize,numR,r,c,outFolder);
                end

                % BWinner, BWouter, tempBorder are stacks of ROIs
                % tempInner, tempOuter and BWborder are single image ROIs
                if numR ~= 0
                    h = figure; set(h,'NextPlot','replacechildren'); set(h,'Visible','off');
                    set(h, 'PaperPositionMode', 'auto'); set(h,'PaperOrientation','landscape'); 
                    ax1 = gca;
                    for bb = 1:length(r)
                        imshow(BWshow{bb},'Parent',ax1)
                        hold on
                        axis image
                        plot(c{bb}(pts{bb}),r{bb}(pts{bb}),'dr','MarkerFaceColor','r','MarkerSize',8)
                        plot(c{bb}(pts{bb}(1)),r{bb}(pts{bb}(1)),'dy','MarkerFaceColor','y','MarkerSize',8)
                        hold off
                        F = hardcopy(h,'-DOpenGL','-r0');
                        plotImg(:,:,:,bb) = F;
                    end
                    close(h)
                    implay(plotImg)
                end
                
                
% find Euclidean distance between all points on outline and
% center of cell
                dists = cellfun(@(x,y,z) cellDists(x,y,z),r,c,cent,'UniformOutput',false);
                maxDist = max(cellfun(@max,dists));
                maxLength = max(cellfun(@length,dists));
                % find distances at each region per timepoint
                if numR ~= 0
                    aveDists = cellfun(@(x,y) timeDists(x,y),tempBorder,cent,'UniformOutput',false);
                    timeDats{cc} = aveDists;
                    aveDirec = cell(size(aveDists));
                    aveDirec{1} = zeros(length(aveDists{1}),1);
                    % if the difference is greater than the previous
                    % distance, motion is in positive direction
                    for ff = 2:length(aveDists)
                        aveDirec{ff} = aveDists{ff} - aveDists{ff-1};
                    end
                end
% normalize distances to largest distance in series
                fDists = cellfun(@(x) lineFilt(x),dists,'UniformOutput',false);
                nDists = cellfun(@(x) normalizeOut(x,maxDist),fDists,'UniformOutput',false);                
% store values for data analysis and plotting
                plots{cc} = nDists;
                dats{cc} = dists;
                
% operations for the inner intensity channel
            case 'Inner Intensity'
% find intensity in inner ROI
                inInt = cellfun(@(x,y,z,a) inIntense(x,y,z,a,kSize),IMG{cc},tempInner,r,c,'UniformOutput',false);
% apply smoothing filter to intensity data                
                fiPlot = cellfun(@(x) lineFilt(x),inInt,'UniformOutput',false);
                maxIn = max(cellfun(@max,fiPlot));
                % find inner intensity at each ROI per time point
                if numR ~= 0
                    aveIn = cellfun(@(x,y) timeInt(x,y),BWinner,IMG{cc},'UniformOutput',false);
                    timeDats{cc} = aveIn;
                end
% normalize to max value in series                
                InPlot = cellfun(@(x) normalizeOut(x,maxIn),fiPlot,'UniformOutput',false); 
% store values for data analysis and plotting
                plots{cc} = InPlot;
                dats{cc} = fiPlot;
                
% operations for the outer intensity channel                
            case 'Outer Intensity'
% find intensity in outer ROI
                outInt = cellfun(@(x,y,z,a) outIntense(x,y,z,a,kSize),IMG{cc},tempOuter,r,c,'UniformOutput',false);
% apply smoothing filter to intensity data
                foPlot = cellfun(@(x) lineFilt(x),outInt,'UniformOutput',false);
                maxOut = max(cellfun(@max,foPlot));
                % find outer intensity at each ROI per timepoint
                if numR ~= 0
                    aveOut = cellfun(@(x,y) timeInt(x,y),BWouter,IMG{cc},'UniformOutput',false);
                    timeDats{cc} = aveOut;
                end
% normalize to max value in series
                outPlot = cellfun(@(x) normalizeOut(x,maxOut),foPlot,'UniformOutput',false);
% store values for data analysis and plotting
                plots{cc} = outPlot;
                dats{cc} = foPlot;
                
% operations for the outline intensity channel                
            case 'Outline Intensity'
% find intensity at outline
                inty = cellfun(@(x,y,z) cellIntense(x,y,z),IMG{cc},r,c,'UniformOutput',false);
% apply smoothing filter to intensity data
                flPlot = cellfun(@(x) lineFilt(x),inty,'UniformOutput',false);
                maxInt = max(cellfun(@max,flPlot));
                % find outline intensity for each ROI per timepoint
                if numR ~= 0
                    aveLine = cellfun(@(x,y) timeOline(x,y), IMG{cc},tempBorder,'UniformOutput',false);
                    timeDats{cc} = aveLine;
                end
% normalize to max value in series
                intPlot = cellfun(@(x) normalizeOut(x,maxInt),flPlot,'UniformOutput',false);
% store values for data analysis and plotting
                plots{cc} = intPlot;
                dats{cc} = flPlot;

% operations for the alignment channel               
            case 'Alignment'
% initialize variables                
                CENTS = cell(1,length(slices)); 
                angs = cell(1,length(slices)); 
                pts = cell(1,length(slices));
% for each image
                % find all angles and curvelet centers
                wb4 = waitbar(.4,'Calculating Alignment, this may take a few minutes','Position',[100 300 300 75]);
                object = cellfun(@(x) newCurv(x,curvT),IMG{cc},'UniformOutput',false);
                waitbar(.7)
                for dd = 1:slices
                    % centers and angles for each total slice
                    CENTS{dd} = vertcat(object{dd}.center);
                    angs{dd} = vertcat(object{dd}.angle);
                end
                % centers and angles for each sub-region of each slice
                if numR ~= 0
                    [tempAngs, tempCents] = cellfun(@(x,y,z) prepAngs(x,y,z),CENTS,angs,BWouter,'UniformOutput',false);
                    aveAngs = cellfun(@(x,y) timeAngs(x,y),tempAngs,tempBorder,'UniformOutput',false);
                    timeDats{cc} = aveAngs;
                end
                waitbar(.9)
                % centers and angles within entire ROI for each slice
                [angles, centers, Ind] = cellfun(@(x,y,z) prepAngs(x,y,z),CENTS,angs,tempOuter,'UniformOutput',false);

                for ee = 1:slices
                    pts{ee} = CENTS{ee}(Ind{ee},:);
                end
                % indicates which image channel is used for alignment
                alignVal = cc;
% process angles and find angle between boundary and each curvelet
                tempAngs = cellfun(@(x,y,z,a) makeAngle(x,y,z,a,kSize),centers,angles,r,c,'UniformOutput',false); 
                outAngs = cellfun(@(x) inpaint_nans(x,4),tempAngs,'UniformOutput',false);
% apply smoothing filter to alignment data
                fOutAngs = cellfun(@(x) lineFilt(x),outAngs,'UniformOutput',false);
% normalize all angles to 90º
                angPlot = cellfun(@(x) normalizeOut(x,90),fOutAngs,'UniformOutput',false);
% store values for data analysis and plotting
                plots{cc} = angPlot;
                dats{cc} = fOutAngs;
                close(wb4)

        end
    end

% call data analysis function
if numR == 0
    makeDats(dats,timeDats,outFolder,names,numR);   
else
    timeDats{num+1} = aveDirec;
    makeDats(dats,timeDats,outFolder,names,numR);  
end

% if alignment channel is used, pass specific arguments to plotting
% function
    if ~isempty(pts)
        makePlots(IMG,BWshow,names,plots,maxLength,cent,r1,c1,alignVal,pts);
    else
        makePlots(IMG,BWshow,names,plots,maxLength,cent,r1,c1,alignVal);
    end     


end

