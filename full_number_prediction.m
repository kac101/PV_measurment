clc;
clear;

% load the trained classifier
load('digitClassifierHOG_SVM.mat', 'classifier');

% load image
imgPath = 'C:\Users\jsks12312\Desktop\PV_measurement\image_processing\example_30_converted\2025_03_24_example_30_converted_binary_00h_00m_00s_033ms.png';
img = imread(imgPath);

% handle binary or grayscale input
if ~islogical(img)
    img = imbinarize(img);
end

bw = imcomplement(img);  % invert: digits become white on black

% manually crop digit display area
digitRegion = imcrop(bw, [135, 120, 360, 180]);

% detect connected components
cc = bwconncomp(digitRegion);
stats = regionprops(cc, 'BoundingBox', 'Area');

% sort by x position (left to right)
boundingBoxes = cat(1, stats.BoundingBox);
areas = cat(1, stats.Area);
[~, sortIdx] = sort(boundingBoxes(:, 1));
boundingBoxes = boundingBoxes(sortIdx, :);
areas = areas(sortIdx, :);

% prediction setup
inputSize = [28 28];
predictedString = "";
padding = 6;

for i = 1:size(boundingBoxes, 1)
    box = boundingBoxes(i, :);
    a = areas(i);

    % skip invalid boxes
    if numel(box) ~= 4 || any(box(3:4) <= 1)
        continue;
    end

    % dot detection logic
    aspectRatio = box(3) / box(4);
    if a < 50 && box(3) < 12 && box(4) < 18 && aspectRatio < 1
        predictedString = predictedString + ".";
        continue;
    end

    % crop with padding (ensure padding doesn't go negative)
    paddedBox = box + [-padding, -padding, 2*padding, 2*padding];
    paddedBox(1:2) = max(paddedBox(1:2), 1);

    try
        digitImg = imcrop(digitRegion, paddedBox);
        digitImg = imresize(digitImg, inputSize, 'Antialiasing', true);
    catch
        continue;
    end

    % predict digit
    feat = extractHOGFeatures(digitImg, 'CellSize', [4 4]);
    label = predict(classifier, feat);
    predictedString = predictedString + string(label);
end

% show result
imshow(img);
title(['predicted value: ', predictedString], 'FontSize', 14);
fprintf('\n✅ predicted number from image: %s\n', predictedString);
