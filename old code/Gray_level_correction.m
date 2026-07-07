% 对pout.tif进行不均匀光照的校正
function Gray_level_correction(im)
%     img = imread('pout.tif');  % 读取文件
%     img = imread('rice.png');  % 读取文件
    img=im;
    figure('Name','不均匀光照的校正');  % 开一个叫不均匀光照的校正的窗口
    subplot(3,3,1);imshow(img);title('pout.tif原图');   % 显示原图
    subplot(3,3,4);imhist(img);title('pout.tif原图直方图');   % 显示直方图
    img_1 = blkproc(img,[32,32],'min(x(:))');             % 相当于滤波 大一点不会出现突兀的色块
    s = size(img_1);
    if(img_1(s(1),s(2))==0) % blkproc可能会出现黑边
        img_1 = img_1(1:s(1)-1,1:s(2)-1);
    end
    img_1 = imresize(img_1, size(img), 'bilinear');       % 双线性插值，插到原图大小
    subplot(3,3,2);imshow(img_1);title('pout.tif背景');   % 显示背景
    img_1 = imsubtract(img,img_1);  % 图像减法
    subplot(3,3,3);imshow(img_1);title('pout.tif光照校正图像');   % 显示光照校正图像
    subplot(3,3,6);imhist(img_1);title('pout.tif校正直方图');   % 显示直方图
    max_1 = double(max(img_1(:)));    % 得到像素最大值
    min_1 = double(min(img_1(:)));    % 得到像素最小值
    subplot(3,3,5);plot([min_1,max_1],[0,255]);
    axis([0 255 0 255]);title('线性变换函数');   %显示线性变换函数
    img_2 = imadjust(img_1,[min_1/255,max_1/255],[]);
    subplot(3,3,9);imhist(img_2);title('pout.tif变换后直方图');   % 显示变换后直方图
    subplot(3,3,7);imshow(img_2);title('pout.tif变换后图像');   % 显示变换后图像
end