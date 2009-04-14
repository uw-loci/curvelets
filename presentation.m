clear all
close all

% theta = randn(1,2)*pi;
% XY = randn(2,2);
% 
% testLine = (1/sqrt(3)).*(XY(1,:).*cosd(theta) + XY(2,:).*sind(theta) + 6)./3;
% 
% figure;
% plot(testLine)
% 
% 
% for aa = 1:3
% testVal(aa) = aa*exp(-i*2*pi*aa/3)
% end
% 
% figure;
% plot(testVal,'r')
% hold on
% plot(1:10,'b')
% hold off
test = exp(-i*2*pi/.5235)
angle(test)

t = [1:30];
for aa = 1:30
sumSin(aa,:) = sin(aa*t) + sin(aa*3.7*t) + sin(aa*.25*t+aa) + sin(aa*5*t) + sin(aa*2*t-aa) + sin(aa*.5*t) + sin(aa*10*t);
sumCos(aa,:) = cos(aa*t*.3) + cos(aa*4*t+aa) + cos(t/aa) + cos(aa*11.5*t);
end
total = sumSin + sumCos;

figure;
compass(fft(total(1,:)))
hold on
plot(test,'x')
hold off
figure;
subplot(3,1,1)
plot(sumSin(1,:))
subplot(3,1,2)
plot(sumCos(1,:))
subplot(3,1,3)
plot(total(1,:))