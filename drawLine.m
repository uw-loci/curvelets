clear all;
close all;

load img_add
hold on
image(img_rec);colormap(gray);axis('image');

up_over = [3 3 1;4 8 -4];

dist = sqrt(up_over(1,:).^2 + up_over(2,:).^2);

leng = 88;
mat = zeros(size(img_rec_all));
pos = findPos(C);

for kk = 1:1
    for ii = 1:round(leng/(2*dist(kk)))
    goto = size(pos{1}{kk});
        for jj = 1:goto(2)
    %     mat(pos{1}{1}(1,jj) - 3*ii,pos{1}{1}(2,jj) + 4*ii) = 1;
    %     mat(pos{1}{1}(1,jj) + 3*ii,pos{1}{1}(2,jj) - 4*ii) = 1;
        mat(pos{1}{kk}(1,jj) - up_over(1,kk)*ii,pos{1}{kk}(2,jj) + up_over(2,kk)*ii) = 1;
        mat(pos{1}{kk}(1,jj) + up_over(1,kk)*ii,pos{1}{kk}(2,jj) - up_over(2,kk)*ii) = 1;
        end
    end
end


spy(mat)
    