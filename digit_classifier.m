clc;
clear;

%% === step 1: load digit dataset ===
% dataset folder contains subfolders named 0-9 with digit images
dataFolder = 'F:\pv\Datasets_digits';

imds = imageDatastore(dataFolder, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

%% === step 2: extract HOG features for each image ===
inputSize = [28 28];  % resize target size (like MNIST)
features = [];
labels = [];

disp('extracting HOG features from digit images...');

for i = 1:numel(imds.Files)
    img = readimage(imds, i);
    img = imresize(img, inputSize);  % resize to standard size

    if size(img, 3) == 3
        img = rgb2gray(img);  % convert to grayscale if needed
    end

    % extract histogram of oriented gradients (HOG) features
    hogFeatures = extractHOGFeatures(img, 'CellSize', [4 4]);

    features = [features; hogFeatures];
    labels = [labels; imds.Labels(i)];
end

%% === step 3: train SVM classifier ===
disp('training multi-class SVM classifier...');
classifier = fitcecoc(features, labels);  % one-vs-one SVM for multi-class

%% === step 4: save the trained model ===
save('digitClassifierHOG_SVM.mat', 'classifier');
disp('✅ classifier trained and saved as "digitClassifierHOG_SVM.mat"');
