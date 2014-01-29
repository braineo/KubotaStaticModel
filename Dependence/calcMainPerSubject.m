%% Main function of the project, calculating the weights for each subject
% return the result of training and NSS score for a single test subject
% parameter:
% opt_set: Setting up options
% saccadeData: saccade data of 15 subject view 400 pictures
% featureGBVS: GBVS saliency map
% faceFeature: Gaussian face feature
% subjectIndex: ID of test subject

function  [mInfo_tune, mNSS_tune, opt] = calcMainPerSubject(opt_set, saccadeData, featureGBVS, faceFeatures, subjectIndex)

load RandomSeed_20121220
opt = opt_set;
opt.start_time = datestr(now,'dd-mmm-yyyy HH:MM:SS');
M = opt.M;
N = opt.N;
tool = toolFunc(opt); % return distance on screen by angle? not really understand

for order_fromfirst=1:opt.n_order_fromfirst % to nth saccade
    [thresholdLength, thresholdAngle, n_samples_each_region] = getThresholdLength(order_fromfirst, saccadeData, opt);
    opt.thresholdLength{order_fromfirst} = thresholdLength;
    opt.thresholdAngle{order_fromfirst} = thresholdAngle;
    opt.n_samples_each_region{order_fromfirst} = n_samples_each_region;
    clear thresholdLength thresholdAngle n_samples_each_region
end

for trial=1:opt.n_trial %times of experienment

    infomatRegionedNear = {};
    infomatRegionedFar = {};
    for k=1:opt.n_region
        infomatRegionedNear{k}=[];
        infomatRegionedFar{k}=[];
    end
    fprintf('XXXXXXXXXXXXXXX trial: %d\n', trial);
    
    rand_param = sum(RandomSeed{trial}); % set up rand generator state
    opt.rand_param{trial} = rand_param;
    
    [sample_saccade, testingsamles] = getIndiTTsamples(rand_param, saccadeData, opt, subjectIndex);
    
    fprintf('Creating infos_base...\n'); tic
    infos_base = zeros(M*N, 8);
    for tm=1:M
        for tn=1:N
            infos_base(N*(tm-1)+tn, :) = [0 tn tm 0 0 0 0 0];
            % 1. imgidx, 2.X, 3. Y, 4. distance to P(NEXT), 5. distance to P(PREV),
            % 6. Region number,
            % 7. Angle(degree) based on P(PREV),
            % 8. Angle(index) (horizontal:1, up:2, down:3)
        end
    end
    
    allOnesMat = ones(size(infos_base, 1),1);
    fprintf([num2str(toc), ' seconds \n']);
    
     for order_fromfirst=1:opt.n_order_fromfirst %order_fromfirst: take consider from the 1st to nth saccade

        rand('state',rand_param*trial*order_fromfirst);

        fprintf('---------------- order_fromfirst: %d\n', order_fromfirst);

        thresholdLength = opt.thresholdLength{order_fromfirst};

        sampleSaccadeOrderSelected = sample_saccade(find(sample_saccade(:,2)<=order_fromfirst&sample_saccade(:,8)==1),:);
        sample_order1_perm = randperm(size(sampleSaccadeOrderSelected, 1));
        sampleSaccadeOrderSelected = sampleSaccadeOrderSelected(sample_order1_perm, :);% random reordered
        
        %---------------
        
        countNearAll = 0;
        countFarAll = 0;
        
        num_feat_A = 10; %total number of features
        infomat_near_distance = zeros(opt.posisize*1.1,1);
        if(opt.enable_angle)
            featurePixelValueNear = zeros(opt.posisize*1.1,3*num_feat_A*size(thresholdLength,2)); % 3 directions, 10 features, n regions
            featurePixelValueFar = zeros(opt.posisize*opt.ngrate*1.1,3*num_feat_A*size(thresholdLength,2));
        else
            featurePixelValueNear = zeros(opt.posisize*1.1,num_feat_A*size(thresholdLength,2));
            featurePixelValueFar = zeros(opt.posisize*opt.ngrate*1.1,num_feat_A*size(thresholdLength,2));
        end

        rate = 1;
        positiveSamples = tool.get_distance(1)*tool.get_distance(1)*1.05*pi*size(sampleSaccadeOrderSelected, 1);
        if(positiveSamples > opt.posisize)
            rate = positiveSamples/opt.posisize;
        end
        
        rate

        fprintf('Prepare Training...\n'); tic
        for imgidx=1:400
            if(mod(imgidx,10)==0)
                fprintf('%d, ', imgidx);
            end
            if(mod(imgidx,100)==0)
                fprintf('\n');
            end
            sampleIndexSelected = sampleSaccadeOrderSelected(find(sampleSaccadeOrderSelected(:,1)==imgidx),:);
            if(size(sampleIndexSelected, 1)==0)
                clear sampleIndexSelected
                continue
            end
% resize feature maps
            c1 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{1}{1}, [M N], 'bilinear');
            c2 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{1}{2}, [M N], 'bilinear');
            c3 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{1}{3}, [M N], 'bilinear');
            i1 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{2}{1}, [M N], 'bilinear');
            i2 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{2}{2}, [M N], 'bilinear');
            i3 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{2}{3}, [M N], 'bilinear');
            o1 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{3}{1}, [M N], 'bilinear');
            o2 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{3}{2}, [M N], 'bilinear');
            o3 = imresize(featureGBVS{imgidx}.graphbase.scale_maps{3}{3}, [M N], 'bilinear');

            color = imresize(featureGBVS{imgidx}.graphbase.top_level_feat_maps{1}, [M N], 'bilinear');
            intensity = imresize(featureGBVS{imgidx}.graphbase.top_level_feat_maps{2}, [M N], 'bilinear');
            orientation = imresize(featureGBVS{imgidx}.graphbase.top_level_feat_maps{3}, [M N], 'bilinear');
            face = imresize(faceFeatures{imgidx}, [M N], 'bilinear');
            infomatNear = [];
            infomatFar =[];
            for i=1:size(sampleIndexSelected,1)
                %% Fill in infomat
                infomat = infos_base;
                infomat(:,1) = imgidx;
                t_px = sampleIndexSelected(i, 3);
                t_py = sampleIndexSelected(i, 4);
                t_nx = sampleIndexSelected(i, 5);
                t_ny = sampleIndexSelected(i, 6);
                % 1. imgidx, 2.X, 3. Y, 
                % 4. distance to P(NEXT), 5. distance to P(PREV),
                % 6. Region number,
                % 7. Angle(degree) based on P(PREV),
                % 8. Angle(index) (horizontal:1, up:2, down:3)
                infomat(:,4) = ...
                    sqrt(((t_nx+0.5).*allOnesMat-infomat(:,2)).*((t_nx+0.5).*allOnesMat-infomat(:,2))+...
                         ((t_ny+0.5).*allOnesMat-infomat(:,3)).*((t_ny+0.5).*allOnesMat-infomat(:,3)));
                infomat(:,5) = ...
                    sqrt(((t_px+0.5).*allOnesMat-infomat(:,2)).*((t_px+0.5).*allOnesMat-infomat(:,2))+...
                         ((t_py+0.5).*allOnesMat-infomat(:,3)).*((t_py+0.5).*allOnesMat-infomat(:,3)));

                for k=1:size(thresholdLength,2)
                    infomat(find(infomat(:,5)<thresholdLength(1,k)&infomat(:,6)==0),6) = k;
                end

                if(opt.enable_angle)
                    infomat(:,7) = ...
                        atan2(-(infomat(:,3)-(t_py+0.5).*ones_), abs(infomat(:,2)-(t_px+0.5).*ones_));

                    infomat(find(infomat(:,7)>-pi/4&infomat(:,7)<pi/4),8) = 1; %direction: horizontal
                    infomat(find(infomat(:,7)>=pi/4),8) = 2; %direction: up
                    infomat(find(infomat(:,7)<=-pi/4),8) = 3; %direction: down
                end
                infomatNear = [infomatNear ;  infomat(find(infomat(:,4)<opt.th_near & infomat(:,6)~=0),:)];
                infomatFar = [infomatFar ;  infomat(find(infomat(:,4)>opt.th_far & infomat(:,6)~=0),:)];
                for k=1:size(thresholdLength,2)
                    infomatRegionedNear{k} = [infomatRegionedNear{k}; infomat(find(infomat(:,4)<opt.th_near & infomat(:,6) == k),:)];
                    infomatRegionedFar{k} = [infomatRegionedNear{k}; infomat(find(infomat(:,4)>opt.th_far & infomat(:,6) == k),:)];
                end
            end
            %% all positive samples
            for i = find(infomatNear(:,1) == imgidx)'
                singleSample = infomatNear(i,:);
                countNearAll = countNearAll + 1;
                angleIndex = singleSample(8);
                regioni = singleSample(6);
                singleFeature = [c1(singleSample(3),singleSample(2)) c2(singleSample(3),singleSample(2)) c3(singleSample(3),singleSample(2))...
                                 i1(singleSample(3),singleSample(2)) i2(singleSample(3),singleSample(2)) i3(singleSample(3),singleSample(2))...
                                 o1(singleSample(3),singleSample(2)) o2(singleSample(3),singleSample(2)) o3(singleSample(3),singleSample(2)) face(singleSample(3),singleSample(2))];
                if(opt.enable_angle)
                    featurePixelValueNear(countNearAll,num_feat_A*3*(regioni-1)+(angleIndex-1)*num_feat_A+1:num_feat_A*3*(regioni-1)+angleIndex*num_feat_A)=singleFeature(:);
                else
                    featurePixelValueNear(countNearAll,num_feat_A*(regioni-1)+1:num_feat_A*regioni)=singleFeature(:);
                end
                
            end
            %% all negative samples
            
            for i = find(infomatFar(:,1) == imgidx)'
                singleSample = infomatFar(i,:);
                countFarAll = countFarAll + 1;
                angleIndex = singleSample(8);
                regioni = singleSample(6);
                singleFeature = [c1(singleSample(3),singleSample(2)) c2(singleSample(3),singleSample(2)) c3(singleSample(3),singleSample(2))...
                                 i1(singleSample(3),singleSample(2)) i2(singleSample(3),singleSample(2)) i3(singleSample(3),singleSample(2))...
                                 o1(singleSample(3),singleSample(2)) o2(singleSample(3),singleSample(2)) o3(singleSample(3),singleSample(2)) face(singleSample(3),singleSample(2))];
                if(opt.enable_angle)
                    featurePixelValueFar(countNearAll,num_feat_A*3*(regioni-1)+(angleIndex-1)*num_feat_A+1:num_feat_A*3*(regioni-1)+angleIndex*num_feat_A)=singleFeature(:);
                else
                    featurePixelValueFar(countNearAll,num_feat_A*(regioni-1)+1:num_feat_A*regioni)=singleFeature(:);
                end
            end
            
        end
        %% Now we have all Far and Near pixel samples and going to pick part of them
        sampleSizeNear = zeros(1,opt.n_region);
        sampleSizeFar = zeros(1,opt.n_region);
        sampleIndexNear = {};
        sampleIndexFar = {};
        for k = 1:opt.n_region
            sampleSizeNear(k)= size(infomatRegionedNear{k},1);
            sampleSizeFar(k)= size(infomatRegionedFar{k},1);
        end
        minSizeNear = min(sampleSizeNear);
        minSizeFar = min(sampleSizeFar);
        
        for k = 1:opt.n_region
            sampleIndexNear{k} = randperm(sampleSizeNear(k));
            sampleIndexFar{k} = randperm(sampleSizeFar(k));
        end
        featureMatNear = [];
        featureMatFar = [];
        indexShift = 0;
        %% select positive samples
        for regioni = 1:opt.n_region
            samplei = sampleIndexNear{regioni}(1:minSizeNear)+indexShift;
            featureMatNear = [featureMatNear ; featurePixelValueNear(samplei,:)];
            indexShift = indexShift + sampleSizeNear(regioni);
        end
        %% select negative samples
        indexShift = 0;
        for regioni = 1:opt.n_region
            samplei = sampleIndexFar{regioni}(1:minSizeFar)+indexShift;
            featureMatFar = [featureMatFar ; featurePixelValueFar(samplei,:)];
            indexShift = indexShift + sampleSizeFar(regioni);
        end
        %% Finishing selecting samples, start to train
        fprintf([num2str(toc), ' seconds \n']); 
        featureMat = [featureMatNear; featureMatFar];
        countNear = minSizeNear*opt.n_region;
        countFar = minSizeFar*opt.n_region;
        labelMat = [ones(countNear, 1); zeros(countFar, 1)];
        
        fprintf('Training...\n'); tic
        info_tune = {};

        fprintf('|tune|');
        [m_,n_] = size(featureMat);
        [info_tune.weight,info_tune.resnorm,info_tune.residual,info_tune.exitflag,info_tune.output,info_tune.lambda]  =  lsqlin(featureMat, labelMat,-eye(n_,n_),zeros(n_,1));
        fprintf([num2str(toc), ' seconds \n']);

        clear featureMat labelMat

        if(order_fromfirst == 5) %% WTF?!?!
            order_fromfirst_ = 0;
        else
            order_fromfirst_ = order_fromfirst;
        end

        NSS_tune = testSaliencymap(opt, featureGBVS, faceFeatures, thresholdLength, info_tune.weight, testingsamles, order_fromfirst_);
        info_tune.positiveSample = minSizeNear;
        info_tune.negativeSample = minSizeFar;
        mInfo_tune{trial}{order_fromfirst} = info_tune;
        mNSS_tune{trial}{order_fromfirst} = NSS_tune;

        clear info_tune
     end
     mTraining{trial} = sample_saccade;
end
opt.end_time = datestr(now,'dd-mmm-yyyy HH:MM:SS');
time_stamp = datestr(now,'yyyymmddHHMMSS');
savefile = sprintf('../Output/storage/EXP_%s_angle%dregion%dTestSub%d_%s.mat', ...
                   opt.time_stamp, opt.enable_angle, opt.n_region, subjectIndex, time_stamp);
save(savefile,'opt','mNSS_tune','mInfo_tune','mTraining','-v7.3');