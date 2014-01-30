%% Main function of the project, calculating the weights
% return the result of training and NSS score for a single test subject
% Random sampling algorithm: reservoir sampling
% parameter:
% opt_set: Setting up options
% saccadeData: saccade data of 15 subject view 450 pictures
% featureGBVS: GBVS saliency map
% faceFeature: Gaussian face feature
% subjectIndex: ID of test subject

function  [mInfo_tune, mNSS_tune, opt] = calcuModel(opt_set, EXPALLFixations, featureMaps, faceFeatures,subjecti)
    tic
    opt = opt_set;
    opt.start_time = datestr(now,'dd-mmm-yyyy HH:MM:SS');
    M = opt.M;
    N = opt.N;
    tool = toolFunc(opt); % return distance on screen by angle? not really understand
    %% initialize training matrix
    fprintf('Start Calculation on Subject#%d...\n',subjecti);

    num_feat_A = opt.featNumber; %total number of features
    if(opt.enable_angle)
        featurePixelValueNear = zeros(opt.posSampleSizeAll, 3*num_feat_A*opt.n_region); % 3 directions, feature numbers, n regions
        featurePixelValueFar = zeros(opt.posSampleSizeAll*opt.negaPosRatio, 3*num_feat_A*opt.n_region);
    else
        featurePixelValueNear = zeros(opt.posSampleSizeAll, num_feat_A*opt.n_region);
        featurePixelValueFar = zeros(opt.posSampleSizeAll*opt.negaPosRatio, num_feat_A*opt.n_region);
    end

    fprintf('Get training sample...\n');

    countNearAll = 0;
    countFarAll = 0;

    for imagei = opt.trainImgIndex
        % postive and negative sample (pixel position)
        sampleinfo = makeSampleInfo(opt, allFixations, subjecti, imagei);
        if(isempty(sampleinfo))
            continue
        end
        [pos, neg] = getFeatureSample(opt, sampleinfo, videoi);
        posSize = size(pos, 1);
        negSize = size(neg, 1);
        featurePixelValueNear(countNearAll+1: countNearAll+posSize, :) = pos;
        featurePixelValueFar(countFarAll+1: countFarAll+negSize, :) = neg;
        countNearAll = countNearAll + posSize;
        countFarAll = countFarAll + negSize;   
    end

        %%  start to train

        featureMat = [featurePixelValueNear(1:countNearAll,:); featurePixelValueFar(1:countFarAll,:)];

        labelMat = [ones(countNearAll, 1); zeros(countFarAll, 1)];

        fprintf('Training...\n'); tic
        info_tune = {};

        fprintf('|tune|');
        [m_,n_] = size(featureMat);
        [info_tune.weight,info_tune.resnorm,info_tune.residual,info_tune.exitflag,info_tune.output,info_tune.lambda]  =  lsqlin(featureMat, labelMat,-eye(n_,n_),zeros(n_,1));
        fprintf([num2str(toc), ' seconds \n']);

        clear featureMat labelMat        
        NSS_tune = [];
        mInfo_tune = info_tune;
        mNSS_tune = NSS_tune;
        clear info_tune


    % opt.end_time = datestr(now,'dd-mmm-yyyy HH:MM:SS');
    % time_stamp = datestr(now,'yyyymmddHHMMSS');
    % savefile = sprintf('../Output/storage/EXP_%s_angle%dregion%dTestSub%d_%s.mat', ...
    %                    opt.time_stamp, opt.enable_angle, opt.n_region, subjectIndex, time_stamp);
    % save(savefile,'opt','mInfo_tune','-v7.3');