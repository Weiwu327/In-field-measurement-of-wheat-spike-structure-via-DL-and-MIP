im = bw2;
tic
skeleton = bwmorph(im,'skeleton',Inf);
t1 = toc;
tic
skeleton1 = bwmorph(skeleton,'spur',50); 
t2 = toc;
figure
showres(im,skeleton,t1,1,2,1,'matlab库')
showres(im,skeleton1,t2,1,2,2,'matlab库（消除毛刺）')

tic
skeleton1 = method1(im);
t1 = toc;

tic
skeleton2 = method2(im);
t2 = toc;

tic
skeleton3 = method3(im);
t3 = toc;
figure
showres(im,skeleton1,t1,1,3,1,'迭代删除法')
showres(im,skeleton2,t2,1,3,2,'迭代删除法（查找表）')
showres(im,skeleton3,t3,1,3,3,'迭代删除法（简化）')

