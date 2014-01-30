% retrieve postive sample and negative from feature maps,
% accroding to fixation location.

function [featurePixelValueNear, featurePixelValueFar] = getFeatureSample(opt, sampleinfo, featureMaps,faceFeatures, imagei)
positiveSample = sampleinfo{1};
negativeSample = datasample(sampleinfo{2}, size(positiveSample,1)*opt.negaPosRatio);

% 1. X, 2. Y, 3. Region number, 4. Angle(index)
num_feat_A = opt.featNumber;
% Allocate storage
if(opt.enable_angle)
    featurePixelValueNear = zeros(size(positiveSample, 1), 3*num_feat_A*opt.n_region); % 3 directions, feature numbers, n regions
    featurePixelValueFar = zeros(size(negativeSample, 1),3*num_feat_A*opt.n_region);
else
    featurePixelValueNear = zeros(size(positiveSample, 1), num_feat_A*opt.n_region);
    featurePixelValueFar = zeros(size(negativeSample,1),num_feat_A*opt.n_region);
end

M = opt.M;
N = opt.N;
countNearAll = 0;
countFarAll = 0;

% reading feature map values
c = cell(1,3);
i = cell(1,3);
o = cell(1,3);

% fprintf('fetching feature map of frame#%03d\n', framei);
for scaleLeveli = 1: 3
    c{scaleLeveli} = imresize(featureMaps{imagei}.graphbase.scale_maps{1}{scaleLeveli}, [M N], 'bilinear');
    i{scaleLeveli} = imresize(featureMaps{imagei}.graphbase.scale_maps{2}{scaleLeveli}, [M N], 'bilinear');
    o{scaleLeveli} = imresize(featureMaps{imagei}.graphbase.scale_maps{3}{scaleLeveli}, [M N], 'bilinear');
end

face = imresize(faceFeatures{imagei}, [M N], 'bilinear');

negIdx = find(negativeSample(:,1) == imagei)';
%% Postive Sample values
for j = 1:size(positiveSample,1)
    singleSample = positiveSample(j,:);
    angleIndex = singleSample(4);
    regioni = singleSample(3);
    countNearAll = countNearAll + 1;
    
    tmpX = singleSample(2); % actually is Y
    tmpY = singleSample(1); % acutally is X
    singleFeature = [c{1}(tmpX,tmpY) c{2}(tmpX,tmpY) c{3}(tmpX,tmpY)...
        i{1}(tmpX,tmpY) i{2}(tmpX,tmpY) i{3}(tmpX,tmpY)...
        o{1}(tmpX,tmpY) o{2}(tmpX,tmpY) o{3}(tmpX,tmpY)...
        face(tmpX,tmpY)];
    if(opt.enable_angle)
        featurePixelValueNear(countNearAll,num_feat_A*3*(regioni-1)+(angleIndex-1)*num_feat_A+1:num_feat_A*3*(regioni-1)+angleIndex*num_feat_A)=singleFeature(:);
    else
        featurePixelValueNear(countNearAll,num_feat_A*(regioni-1)+1:num_feat_A*regioni)=singleFeature(:);
    end
end

clear tmpX tmpY
%% Negative Samples
for j = 1:size(negativeSample,1)
    singleSample = negativeSample(j,:);
    angleIndex = singleSample(4);
    regioni = singleSample(3);
    countFarAll = countFarAll + 1;
    
    tmpX = singleSample(2);
    tmpY = singleSample(1);
    singleFeature = [c{1}(tmpX,tmpY) c{2}(tmpX,tmpY) c{3}(tmpX,tmpY)...
        i{1}(tmpX,tmpY) i{2}(tmpX,tmpY) i{3}(tmpX,tmpY)...
        o{1}(tmpX,tmpY) o{2}(tmpX,tmpY) o{3}(tmpX,tmpY)...
        face(tmpX,tmpY)];
    if(opt.enable_angle)
        featurePixelValueFar(countFarAll,num_feat_A*3*(regioni-1)+(angleIndex-1)*num_feat_A+1:num_feat_A*3*(regioni-1)+angleIndex*num_feat_A)=singleFeature(:);
    else
        featurePixelValueFar(countFarAll,num_feat_A*(regioni-1)+1:num_feat_A*regioni)=singleFeature(:);
    end
    
end

fprintf('pos: %d, neg: %d\n\n', countNearAll, countFarAll)