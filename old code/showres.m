function showres(im,skeleton,t,i,j,k,titlename)
subplot(i,j,k),imshow(im)
hold on
[x,y] = find(skeleton);
plot(y,x,'r.')
title(['\fontsize{16}',titlename])
xlabel(['\fontsize{16}耗时(秒)：',num2str(t)])
end