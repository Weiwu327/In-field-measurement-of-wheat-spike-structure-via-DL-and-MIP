clear;clc;close all;

im_jpg = imread('1.jpg');
im_1 = im2double(im_jpg);
R = im_1(:,:,1);
G = im_1(:,:,2);
B = im_1(:,:,3);
% gray = 2.7*B-R-G;
gray = R + G - 2 * B;
T1 = adaptthresh(gray,0.4,'ForegroundPolarity','dark','Statistic','mean');
BW1 = imbinarize(gray,T1);
figure,imshow(BW1);

spike = BW1;
se = strel('disk',15);
ear = imopen(spike, se);
% figure,imshow(ear);
se1 = strel('disk',15);
ear = imdilate(ear,se1);
figure,imshowpair(spike, ear, 'montage');

awn = spike;
[aa, bb] = find(ear==0);
for i =1:size(aa,1)
    awn(aa(i),bb(i),:) = 0;
end
% se2 = strel('disk',5);
% awn = imclose(awn, se2);
awn = imfill(awn,"holes");
figure,imshow(awn);

spike1 = im_1;
awn1 = im_1;
[m, n] = find(awn==0);
for i =1:size(m,1)
    spike1(m(i),n(i),:) = 0;
end
[mm, nn] = find(awn==1);
for i =1:size(mm,1)
    awn1(mm(i),nn(i),:) = 0;
end
figure,imshowpair(spike1, awn1, 'montage');

R = awn1(:,:,1);
G = awn1(:,:,2);
B = awn1(:,:,3);
% gray = 2.7*B-R-G;
gray = 3*B-R-G;
T1 = adaptthresh(gray,0.6,'ForegroundPolarity','dark','Statistic','mean');
BW1 = imbinarize(gray,T1);
awn2 = ~BW1;
figure,imshow(awn2);
for i =1:size(mm,1)
    awn2(mm(i),nn(i),:) = 0;
end
figure,imshowpair(~BW1, awn2, 'montage');

% out = bwskel(awn2,'MinBranchLength',5);
% figure,imshowpair(awn2, out, 'montage');
% figure;imshow(labeloverlay(gray,out,'Transparency',0));
% out2 = bwskel(awn2,'MinBranchLength',50);
% imshow(labeloverlay(gray,out2,'Transparency',0))
% figure,imshowpair(out, out2, 'montage');
% % 
% L = bwlabeln(awn2);
% S = regionprops(L, 'Area');
% bw2 = ismember(L, find([S.Area] >= 200));
% figure,imshow(bw2);
% bw2 = fillsmallholes(bw2,100);
% figure,imshow(bw2);

% % bw= bwmorph(im2bw(I),'skel',inf);
% % figure,imshow(bw);title('骨架提取');
% img=double(out2); 
% img = imgaussfilt(img,.5); 
% zz_out = zeros(size(img)); 
% % %%150调节显示多少
% for ii = -5:.5:150 
%     se = strel('line',10,ii); 
%     zz = imerode(img,se); 
%     zz_out = or(zz,zz_out); 
% end 
% figure, imshow(zz_out);title('去除二值化图中的相交线、连接线');
% bw= bwmorph(zz_out,'skel',inf);
% figure,imshow(bw);title('骨架提取');