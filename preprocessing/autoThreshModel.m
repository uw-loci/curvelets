classdef autoThreshModel < handle 
    %Model class for the auto threshold module
  
    
    properties(SetObservable)
        % variable for keeping instances of Image
        I 
        %# of images in stack
        numSections 
        flag
        conv8bit
        darkObjectCheck
        info
        % store tif meta-data tags
        % local window size (ws X ws) as required
        ws
        % file path
        myPath
    end

    properties
        thresholdOptions_List = {'Global Otsu Method','Ridler-Calvard (ISO-data) Cluster Method',...
            'Kittler-Illingworth Cluster Method','Kapur Entropy Method',...
            'Local Otsu Method','Local Sauvola Method','Local Adaptive Method'};
    end
    
    methods
        function obj = autoThreshModel()
            obj.reset();
        end
        
        function reset(obj)
            obj.I = [];    
            obj.numSections = 1;
            obj.conv8bit = 0;
            obj.darkObjectCheck = 0; 
            obj.flag = 1;
            obj.myPath = '';   % define directory
            obj.info = []; 
            obj.ws = 32; 
        end      
        
        function setConv8bit(obj,conv8bit)
            obj.conv8bit = conv8bit;
        end
        
        function setFlag(obj,flag)
            obj.flag = flag;
        end
        
        function setdarkObjectCheck(obj,darkObjectCheck)
            obj.darkObjectCheck = darkObjectCheck;
        end
        
        function setPath(obj,myPath,info,numSections)
            obj.myPath = myPath;
            obj.info = imfinfo(ff); % store tif meta-data tags
            obj.numSections = numel(info); % # of images in stack
        end
        
%    thresholdOptions_list = {'1 Global Otsu Method','2 Ridler-Calvard (ISO-data) Cluster Method',...
%             '3 Kittler-Illingworth Cluster Method','4 Kapur Entropy Method',...
%             '5 Local Otsu Method','6 Local Sauvola Method','7 Local Adaptive Method','8 All'};
        
        function [thresh,I] = AthreshInternal(obj,stackValue) % function to threshold an image with many options
%             obj.myPath = '/Users/ympro/Google Drive/Sabrina_ImageAnalysisProjectAtLOCI_2021.6_/programming/BF-testImages/SHG.tif';
            ImgOri = imread(obj.myPath,stackValue);
            obj.info = imfinfo(obj.myPath);
            Imin = min(min(ImgOri));
            Imax = max(max(ImgOri));
            switch obj.flag
                case 1 %3. Use Global Otsu Method to threshold images
                    [threshLevel,EM] = graythresh(ImgOri);
                    I = im2bw(ImgOri,threshLevel); % output as binary mask
                    thresh  = round((Imax-Imin)*threshLevel);
                    %                 maxInt = max(ImgOri(:));
                    if obj.numSections > 1
                        fprintf('Automatic Image Thresholding done with a %f Effectiveness Metric for slice %u.\n',EM,S)
                    else
                        
                        fprintf('Automatic Image Thresholding done with %f Effectiveness Metric.\n',EM)
                    end
                    drawnow
                case 2 %3. Use Ridler-Calvard (ISO-data) Cluster threshold method
                    vImgOri = ImgOri(:); % vectorize image matrix
                    [PixCt,PixInt] = imhist(vImgOri); % histogram of image
                    % setup formula for iterated threshold
                    T(1) = round(sum(PixCt .* PixInt) ./ sum(PixCt));
                    Change = 1;
                    i=1; % counter of iterations of ThreshItr
                    while (Change ~= 0) && (i<15)
                        T_indexes = find(PixInt >= T(i)); % sort Pixel Intensity bins
                        T_i = T_indexes(1);	% finds the value (in "intensity") that is closest to the threshold.
                        % calculate mean below current threshold: MBT
                        MBT = sum(PixCt(1:T_i) .* PixInt(1:T_i) ) ./ sum(PixCt(1:T_i));
                        % calculate mean above current threshold: MAT
                        MAT = sum(PixCt(T_i:end) .* PixInt(T_i:end) ) ./ sum(PixCt(T_i:end));
                        % Iterate new threshold as mean of MAT and MBT
                        i= i+1;
                        T(i) = round((MBT + MAT) ./ 2);
                        Change = T(i) - T(i-1);
                    end
                    threshi = T(i);
                    % Normalize threshold to interval [0,1]
                    threshLevel = (threshi - 1) / (PixInt(end) - 1);
                    I = im2bw(ImgOri,threshLevel); % output as binary mask
                    thresh  = round((Imax-Imin)*threshLevel);
                case 3 %3. Use Kittler-Illingworth Cluster threshold method
                    [threshLevel, ~]= kittlerMinErrThresh(ImgOri); % Apply method by Kocki
                    I = im2bw(ImgOri,threshLevel); % output as binary mask
                    thresh  = round((Imax-Imin)*threshLevel);
                case 4 %3. Use Kapur Entropy threshold method
                    threshLevel = Kapur(ImgOri); % Apply method by Bianconi
                    I = im2bw(ImgOri,threshLevel); % output as binary mask
                    thresh  = round((Imax-Imin)*threshLevel);
                case 5 %3. Use Local Otsu Method to threshold image
                    % setup function for Global Otsu method to be applied to local blocks
                    fun = @(block_struct) im2bw(block_struct.data,min(max(graythresh(block_struct.data),0),1));
                    thresh = nan; % thresholds are local so there is no real global value to output.
                    % apply block proccesing to locally threshold the image
                    I = blockproc(ImgOri,bestblk([obj.info.Width obj.info.Height]),fun,'PadPartialBlocks',true,'PadMethod','replicate');
                case 6 %3. Use Local Sauvola threshold method
                    [threshLevel, I] = sauvola(ImgOri,[obj.ws obj.ws]); % Apply method by yzan
                    thresh  = round((Imax-Imin)*threshLevel);
                case 7 %3. Use Local Adaptive threshold method
                    C = 0.02; % Constant adjustment factor ((mean or median)-C)
                    tm = 0; % Flag for method using mean(0) or median (1)
                    [threshLevel, I] = adaptivethreshold(ImgOri,obj.ws,C,tm); % Apply method by Guanglei Xiong
                    thresh  = round((Imax-Imin)*threshLevel);
                case 8
                    disp('To be added later')
            end
        end
        
    end
end

