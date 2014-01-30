%% Kubota model static image version code
% Divide into 3 regions
% Angle disabled

clear
info = {};
info.time_stamp = datestr(now,'yyyymmddHHMM');
info.start_time = datestr(now,'dd-mmm-yyyy HH:MM:SS');

%% ----------------- TEMPLATE -----------------------------

%% set model type
% modelType = [a,b]
% a = 1: free viewing 2: preference
% b = 1: fractal 2: high context 3: scene 4: all
opt = {};

modelType = [2,4];
opt.trainImgIndex = 151:300; % images with these indices will be used in training

%%
fprintf('Load EXPALLFixations, EXPALLFeatures...'); tic
if(modelType(1) == 1)
    load('../Data/EXPALLFixationsFree.mat'); % fixation data
    load('../Data/EXPfaceFeaturesFree.mat'); % face locations
    load('../Data/freeViewFeatures.mat');% GBVS saliency map
elseif(modelType(1) == 2)
    load('../Data/EXPALLFixationsPref.mat'); % fixation data
    load('../Data/EXPfaceFeaturesPref.mat'); % face locations
    load('../Data/preferenceFeatures.mat');% GBVS saliency map
else
    error('input a valid parameter for modelType');
end


opt.time_stamp = info.time_stamp;
opt.minimize_scale = 6;
opt.width = 1920;
opt.height = 1080;
opt.M = round(opt.height/opt.minimize_scale);
opt.N = round(opt.width/opt.minimize_scale);
M = opt.M;
N = opt.N;
tool = toolFunc(opt);

opt.th_near = tool.get_distance(1.0);
opt.th_far = tool.get_distance(4.0);
opt.u_sigma = tool.get_distance(1.0);

%opt.discard_short_saccade = tool.get_distance(2);
opt.discard_short_saccade = -1;

opt.thresholdLength = {};
opt.thresholdAngle = {};
opt.thresholdAngleInit = {5, 8, 11, 14, 20, 57};

%% ----------------- TEMPLATE -----------------------------

%% ----------------- SETTING -----------------------------
opt.n_order_fromfirst = 1; % from the first to nth saccade are used
opt.thresholdSubjectIndex = 1:12; % Data of these subjects is used to determined threshold length
opt.thresholdLengthType = 's_uni'; % how threshold is determined
opt.n_region = 3; % region number
opt.enable_angle = 0;
opt.featNumber = 10; % feature numbers in 1 region
opt.subjectNumber = 1; % number of test subjects
opt.stimuliNumber = 450; % number of stimuli
opt.posSampleSizeAll = 400000; % size of positive sample for 1 test subject
opt.negaPosRatio = 1000; % ratio of negaSize:posSize

%% ----------------- SETTING -----------------------------

for order_fromfirst=1:opt.n_order_fromfirst % to nth saccade
    [thresholdLength, thresholdAngle, n_samples_each_region] = getThresholdLength(order_fromfirst, EXPALLFixations, opt);
    opt.thresholdLength{order_fromfirst} = thresholdLength;
    opt.thresholdAngle{order_fromfirst} = thresholdAngle;
    opt.n_samples_each_region{order_fromfirst} = n_samples_each_region;
    clear thresholdLength thresholdAngle n_samples_each_region
end

info.opt = opt;
featureWeight = cell(1, opt.subjectNumber);

for subjecti = 1:opt.subjectNumber
    
    fprintf('\n\n========================================================= \n Current test subject: #%02d\n', subjecti);
    RET = {};
    [RET.mInfo_tune, RET.mNSS_tune, RET.opt_ret] = calcuModel(opt, EXPALLFixations, ALLFeatures, faceFeatures, subjecti);
    featureWeight{subjecti} = RET;
    clear RET
    
end

info.end_time = datestr(now,'dd-mmm-yyyy HH:MM:SS')
savefile = sprintf('../Output/feature_weight_%s.mat', info.time_stamp);
save(savefile,'featureWeight','info','-v7.3');
