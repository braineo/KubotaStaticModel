%% all sample for training
% Divide into 3 regions
% Angle disabled

clear all
clearvars -EXCEPT Info EXPALLFixations ALLFeatures faceFeatures sampleinfo sampleinfoStat
info = {};
info.time_stamp = datestr(now,'yyyymmddHHMM');
info.start_time = datestr(now,'dd-mmm-yyyy HH:MM:SS');

%% ----------------- TEMPLATE -----------------------------

%% set model type
% modelType = [a,b]
% a = 1: free viewing 2: preference
% b = 1: fractal 2: high context 3: scene 4: all
opt = {};
for i = 1:1
    for j = 1:2
modelType = [i,j];
if(modelType(2)~=4)
    a = modelType(2);
    opt.trainImgIndex = 150*(a-1)+1:150*a;
elseif(modelType(2) == 4)
    opt.trainImgIndex = 1:450;
else
    error('input a valid parameter for modelType');
end
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
fprintf([num2str(toc), ' seconds \n']);


opt.time_stamp = info.time_stamp;
% opt.IMGS = './final_resize';
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

opt.rand_param = {};
%opt.discard_short_saccade = tool.get_distance(2);
opt.discard_short_saccade = -1;

opt.thresholdLength = {};
opt.thresholdAngle = {};
opt.thresholdAngleInit = {5, 8, 11, 14, 20, 57};
%opt.thresholdAngleInit = {6, 9, 12, 16, 22, 80};

opt_base = opt;
clear opt
%% ----------------- TEMPLATE -----------------------------

%% ----------------- SETTING -----------------------------
opt = opt_base;
opt.posisize = 1200; % no effect
opt.ngrate = 20;  % no effect
opt.n_trial = 1;  % no effect
opt.n_order_fromfirst = 1;
opt.thresholdLengthType = 's_uni'; %
opt_base = opt;
clear opt
%% ----------------- SETTING -----------------------------

info.opt_base = opt_base;

for subjecti = 1:12   
    opt = opt_base;
    opt.n_region = 2; %fixed, do not change it.
    opt.enable_angle = 0;
    fprintf('========================================================= angle: %d region: %d\n', opt.enable_angle, opt.n_region);
    RET = {};
%     opt.thresholdLength = Info.thresholdLength{opt.n_order_fromfirst};
    [sampleinfo,opt] = makeSampleInfo(opt,EXPALLFixations,subjecti);
    sampleinfoStat = makeSampleStat(sampleinfo,subjecti);
    [RET.mInfo_tune, RET.mNSS_tune, RET.opt_ret] = calcuModel20130926(opt, EXPALLFixations, ALLFeatures, faceFeatures, sampleinfo,sampleinfoStat, subjecti);
    EXP_INDV_REGION_NOANGLE_ms6{subjecti} = RET;
    clear opt RET
    
end

info.end_time = datestr(now,'dd-mmm-yyyy HH:MM:SS')
savefile = sprintf('../Output/model0926_%d%d_%s.mat',modelType(1),modelType(2), info.time_stamp);
save(savefile,'EXP_INDV_REGION_NOANGLE_ms6','info','-v7.3');
    end 
end