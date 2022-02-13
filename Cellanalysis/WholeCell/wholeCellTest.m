function wholeCellTest(imageFile, maskFile)

answers = individual_IoU(imageFile, maskFile);
brokenLine = ansAna(answers);
x = [0.5 0.6 0.7 0.8 0.9 1.0];

mask = imread(maskFile);
[L,n] = bwlabel(mask(:,:,1));
brokenLine = brokenLine / n;

plot(x,brokenLine,'Color','k')

end