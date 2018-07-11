clc; close all;clear all
A = double(imread('sample2.jpg'));
figure; imshow(uint8(A)); title('Image 1');
B = double(imread('wheel.png'));
figure; imshow(uint8(B)); title('Image 2');
[M, N, ~] = size(A);
j  = N/2 ;

% Laplacian pyramid for each image
depth = floor(log(M) / log(2)) - 4;
lapA = genPyramid(A, depth); 
lapB = genPyramid(B, depth);
mA = zeros(size(A));
mA(:, 1:j, :) = 1;
maskB = 1 - mA;
blur = fspecial('gauss', 30, 15);
mA = imfilter(mA, blur, 'replicate');
maskB = imfilter(maskB, blur, 'replicate');
for i = 1: depth
	[Mp, Np, ~] = size(lapA{i});
	maskAP = imresize(mA,[Mp, Np]);
	maskBP = imresize(maskB,[Mp, Np]);
	lapO{i} = lapA{i}.*maskAP + lapB{i}.*maskBP;
end

for i = length(lapO)-1:-1:1
	lapO{i} = lapO{i}+pyrExpand(lapO{i+1});
end
Belnded = lapO{1};
figure; imshow(uint8(Belnded)); title('Blended Image');

function [pyramid] = genPyramid(img, level)
pyramid = cell(1, level);
pyramid{1} = im2double(img);
for i = 2:level
	pyramid{i} = pyrReduce(pyramid{i-1});
end

for i = level-1:-1:1 % adjust the image size
	osz = size(pyramid{i+1})*2-1;
	pyramid{i} = pyramid{i}(1:osz(1),1:osz(2),:);
end

for i = 1:level-1
	pyramid{i} = pyramid{i} - pyrExpand(pyramid{i+1});
end
end


function [imgout] = pyrReduce(img)
cw = .375;
ker1d = [.25-cw/2 .25 cw .25 .25-cw/2];
kernel = kron(ker1d,ker1d');

img = im2double(img);
sz = size(img);
imgout = [];

for i = 1:size(img,3)
	img1 = img(:,:,i);
	imgFiltered = imfilter(img1,kernel,'replicate','same');
	imgout(:,:,i) = imgFiltered(1:2:sz(1), 1:2:sz(2));
end
end

function [imgout] = pyrExpand(img)
kw = 5;
cw = .375;
ker1d = [.25-cw/2 .25 cw .25 .25-cw/2];
kernel = kron(ker1d,ker1d')*4;

% expand [a] to [A00 A01;A10 A11] with 4 kernels
ker00 = kernel(1:2:kw, 1:2:kw); % 3*3
ker01 = kernel(1:2:kw, 2:2:kw); % 3*2
ker10 = kernel(2:2:kw, 1:2:kw); % 2*3
ker11 = kernel(2:2:kw, 2:2:kw); % 2*2

img = im2double(img);
sz = size(img(:,:,1));
osz = sz*2-1;
imgout = zeros(osz(1),osz(2),size(img,3));

for i = 1:size(img,3)
	img1 = img(:,:,i);
	img1ph = padarray(img1,[0 1],'replicate','both'); % horizontally padded
	img1pv = padarray(img1,[1 0],'replicate','both'); % horizontally padded
	
	img00 = imfilter(img1,ker00,'replicate','same');
	img01 = conv2(img1pv,ker01,'valid'); % imfilter doesn't support 'valid'
	img10 = conv2(img1ph,ker10,'valid');
	img11 = conv2(img1,ker11,'valid');
	
	imgout(1:2:osz(1),1:2:osz(2), i) = img00;
	imgout(2:2:osz(1),1:2:osz(2), i) = img10;
	imgout(1:2:osz(1),2:2:osz(2), i) = img01;
	imgout(2:2:osz(1),2:2:osz(2), i) = img11;
end
end

