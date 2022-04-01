function plot_general(x, brokenLine)

plot(x,brokenLine,'Color','b')
hold on
for i =1:length(x)
    text(x(i),brokenLine(i),num2str(brokenLine(i)),'Color','r')
end
xlabel('IoU')
ylabel('precentage')
title('Cellpose using test images')

end