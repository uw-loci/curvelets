function brokenLine = ansAna(answer)

% This function analyzes the answers returned by individual_IoU.m by taking
% in the IoU scores of each cell the number of cells that have IoU scores 
% higher than 0.5, 0.6, 0.7, 0.8, 0.9, 1.0.

brokenLine = zeros(6,1);

for i=1:length(answer)
    for j=5:10
        if answer(i) > (j/10)
            brokenLine(j-4) = brokenLine(j-4) + 1;
        end
    end
end

end