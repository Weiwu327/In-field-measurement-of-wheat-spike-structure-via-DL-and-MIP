clear;clc;close all;

im_jpg = imread('1.jpg');
im_1 = im2double(im_jpg);
R = im_1(:,:,1);
G = im_1(:,:,2);
B = im_1(:,:,3);
gray = 2.7 * B - R - G;
T1 = adaptthresh(gray,0.4,'ForegroundPolarity','dark','Statistic','mean');
BW1 = imbinarize(gray,T1);

spike = ~BW1;

L = bwlabeln(spike);
S = regionprops(L, 'Area');
bw = ismember(L, find([S.Area] >= 200));
% figure,imshow(bw2);
spike = fillsmallholes(bw,100);
% figure,imshow(spike);

se = strel('disk',15);
ear = imopen(spike, se);
% figure,imshow(ear);
se1 = strel('disk',100);
ear1 = imdilate(ear,se1);
% figure,imshowpair(spike, ear, 'montage');
[r, c]=find(ear1==1);
spike1 = tubao(spike,r,c);
figure,imshow(spike1);       % Display the image

se2 = strel('disk',200);
ear2 = imdilate(ear1,se2);
[r2, c2]=find(ear2==1);
spike2 = tubao(spike,r2,c2);
figure,imshow(spike2);       % Display the image


awn = spike;
[aa, bb] = find(ear==1);
for i =1:size(aa,1)
    awn(aa(i),bb(i),:) = 0;
end
% se2 = strel('disk',5);
% awn = imclose(awn, se2);

out = bwskel(awn,'MinBranchLength',5);
figure,imshowpair(awn, out, 'montage');
LL = bwlabeln(out);
SS = regionprops(LL, 'Area');
out = ismember(LL, find([SS.Area] >= 20));

out1 = zeros(size(out));
out1 = tubao(out1,r,c);
se3 = strel('disk',3);
out1 = imdilate(out1,se3);
figure,imshowpair(out, out1, 'montage');
% out2 = tubao(out,r,c);
out2 = out + out1 + ear +awn;
figure,imshow(out2);       % Display the image

K = out.*out1;
figure,imshow(K);       % Display the image


% % figure;imshow(labeloverlay(gray,out,'Transparency',0));
% out2 = bwskel(awn,'MinBranchLength',50);
% % imshow(labeloverlay(gray,out2,'Transparency',0))
% figure,imshowpair(out, out2, 'montage');
% 
% K1=filter2(fspecial("average",9),awn);
% figure;imshow(K1),xlabel("原图5*5卷积和均值滤波");


% L = bwlabeln(out2);
% S = regionprops(L, 'Area');
% bw2 = ismember(L, find([S.Area] >= 200));
% figure,imshow(bw2);


% % bw= bwmorph(im2bw(I),'skel',inf);
% % figure,imshow(bw);title('骨架提取');
% img=double(bw2); 
% img = imgaussfilt(img,.5); 
% zz_out = zeros(size(img)); 
% %%150调节显示多少
% for ii = -5:.1:150 
%     se = strel('line',20,ii); 
%     zz = imerode(img,se); 
%     zz_out = or(zz,zz_out); 
% end 
% figure, imshow(zz_out);title('去除二值化图中的相交线、连接线');
