clear;clc;close all;

im_jpg = imread('1.jpg');
% im_png = imread('01.png');
im_1 = im2double(im_jpg);
% [a,b] = find(im_png==1);
% im_1(a,b,:) = 0;
% [aa, bb] = find(im_png==2);
% for i =1:size(aa,1)
%     im_1(aa(i),bb(i),:) = 0;
% end
% f1=im_1;
%去光照不均匀
% im=f1;%f1为读取的图片
% [h,s,v]=rgb2hsv(im);    %转到hsv空间，对亮度h处理
%  % 高斯滤波
% HSIZE= min(size(im,1),size(im,2));%高斯卷积核尺寸
% q=sqrt(2);
% SIGMA1=15;
% SIGMA2=80;
% SIGMA3=250;
% F1 = fspecial('gaussian',HSIZE,SIGMA1/q);
% F2 = fspecial('gaussian',HSIZE,SIGMA2/q);
% F3 = fspecial('gaussian',HSIZE,SIGMA3/q);
% gaus1= imfilter(v, F1, 'replicate');
% gaus2= imfilter(v, F2, 'replicate');
% gaus3= imfilter(v, F3, 'replicate');
% gaus=(gaus1+gaus2+gaus3)/3;    %多尺度高斯卷积，加权，权重为1/3
% m=mean(gaus(:));
% [w,height]=size(v);
% out=zeros(size(v));
% gama=power(0.5,((m-gaus)/m));%根据公式gamma处理
% out=(power(v,gama));
% im_1=hsv2rgb(h,s,out);   %转回rgb空间显示

figure,imshow(im_1);
R = im_1(:,:,1);
G = im_1(:,:,2);
B = im_1(:,:,3);
EXB = 2.7*B-R-G;
figure,imshow(EXB);
gray = rgb2gray(im_1);

% T1 = adaptthresh(EXB, 0.4);
% BW1 = imbinarize(EXB,T1);
% figure
% imshowpair(T1, BW1, 'montage')
% bw=im2bw(EXB);
% figure,imshow(bw);
gray = EXB;
% Gray_level_correction(gray);

T1 = adaptthresh(gray,0.4,'ForegroundPolarity','dark','Statistic','mean');
BW1 = imbinarize(gray,T1);
% T2 = adaptthresh(gray,0.4,'ForegroundPolarity','dark','Statistic','median');
% BW2 = imbinarize(gray,T2);
T3 = adaptthresh(gray,0.4,'ForegroundPolarity','dark','Statistic','gaussian');
BW3 = imbinarize(gray,T3);
figure,imshowpair(T1, ~BW1, 'montage');
% figure,imshowpair(T2, ~BW2, 'montage');
% figure,imshowpair(T3, ~BW3, 'montage');
imwrite(double(EXB),'EXB1.jpg');
imwrite(double(T1),'EXB2.jpg');
imwrite(double(~BW1),'EXB3.jpg');
% se = strel('disk',15);
% background = imopen(EXB,se);
% imshow(background);
% f1=im_1;
% %去光照不均匀
% im=f1;%f1为读取的图片
% [h,s,v]=rgb2hsv(im);    %转到hsv空间，对亮度h处理
%  % 高斯滤波
% HSIZE= min(size(im,1),size(im,2));%高斯卷积核尺寸
% q=sqrt(2);
% SIGMA1=15;
% SIGMA2=80;
% SIGMA3=250;
% F1 = fspecial('gaussian',HSIZE,SIGMA1/q);
% F2 = fspecial('gaussian',HSIZE,SIGMA2/q);
% F3 = fspecial('gaussian',HSIZE,SIGMA3/q);
% gaus1= imfilter(v, F1, 'replicate');
% gaus2= imfilter(v, F2, 'replicate');
% gaus3= imfilter(v, F3, 'replicate');
% gaus=(gaus1+gaus2+gaus3)/3;    %多尺度高斯卷积，加权，权重为1/3
% m=mean(gaus(:));
% [w,height]=size(v);
% out=zeros(size(v));
% gama=power(0.5,((m-gaus)/m));%根据公式gamma处理
% out=(power(v,gama));
% im_1=hsv2rgb(h,s,out);   %转回rgb空间显示
% figure,imshow(im_1);
% R = im_1(:,:,1);
% G = im_1(:,:,2);
% B = im_1(:,:,3);
% EXB = 2*B-R-G;
% figure,imshow(EXB);
% bw = im2bw(EXB,1/255);
% figure,imshow(bw);
% EX = (G+R+B)/3;
% figure,imshow(EX);
% 
% gray = rgb2gray(im_1);
% figure,imshow(gray);
% bw = im2bw(gray);
% BW2 = edge(gray,'canny');
% figure;
% imshow(BW2)
% title('Canny Filter');
