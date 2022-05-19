classdef modelEvaluation
    
    properties
        numImg
        brokenLineAverage
        area
    end
    
    methods
        function obj = modelEvaluation(results, masks)
            if length(results) ~= length(masks)
                errID = 'myComponent:inputError';
                msgtext = 'Input images and masks do not match.';
                ME = MException(errID,msgtext);
                throw(ME)
            end
            brokenLineCount = [0 0 0 0 0 0];
            obj.numImg = length(results);
            imagesSorted = sort(results);
            masksSorted = sort(masks);
            for i=1:length(imagesSorted)
                brokenLine = evaluateImage(obj, imagesSorted(i), masksSorted(i));
                brokenLineCount = brokenLineCount + brokenLine.';
            end
            brokenLineAverage = brokenLineCount / length(results);
            obj.brokenLineAverage = brokenLineAverage;
            area = 0;
            for i=1:5
                area = area + 0.1 * (brokenLineAverage(i)+brokenLineAverage(i+1)) / 2;
            end
            obj.area = area;
        end
        
        function brokenLine = evaluateImage(obj, image, mask)
            answers = individual_IoU(image, mask);
            brokenLine = ansAna(answers);
            mask = imread(mask);
            [L,n] = bwlabel(mask(:,:));
            brokenLine = brokenLine / n;
        end
    end
    methods (Static)
        function plot(brokenLineAverage, titleString)
            x = [0.5 0.6 0.7 0.8 0.9 1.0];
            plot(x,brokenLineAverage,'Color','b')
            hold on
            for i =1:length(x)
                text(x(i),brokenLineAverage(i),num2str(brokenLineAverage(i)),'Color','r')
            end
            xlabel('IoU')
            ylabel('precentage')
            title(titleString)       
        end
    end
end

