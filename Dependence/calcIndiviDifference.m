function [mInfo_tune, mNSS_tune, opt] = calcIndiviDifference(opt_set, EXPALLFixations, ALLFeatures, faceFeatures, indiviNum)

load RandomSeed_20121220
opt = opt_set;
opt.start_time = datestr(now,'dd-mmm-yyyy HH:MM:SS');
M = opt.M;
N = opt.N;
tool = toolFunc(opt);
% toolFunc: return angel, distance and gauss
for order_fromfirst=1:opt.n_order_fromfirst
    [thresholdLength, thresholdAngle, n_samples_each_region] = getThresholdLength(order_fromfirst, EXPALLFixations, opt);
    opt.thresholdLength{order_fromfirst} = thresholdLength;
    opt.thresholdAngle{order_fromfirst} = thresholdAngle;
    opt.n_samples_each_region{order_fromfirst} = n_samples_each_region;
    clear thresholdLength thresholdAngle n_samples_each_region
end

for trial=1:opt.n_trial
    region_stat_near = zeros(1,opt.n_region);
    region_stat_far = zeros(1,opt.n_region);
    fprintf('XXXXXXXXXXXXXXX trial: %d\n', trial);

    rand_param = sum(RandomSeed{trial});
    opt.rand_param{trial} = rand_param;
    
    [sample_saccade, testingsamles] = getIndiTTsamples(rand_param, EXPALLFixations, opt, indiviNum);
    
    fprintf('Creating infos_base...\n'); tic
    infos_base = zeros(M*N, 8);
    for tm=1:M
        for tn=1:N
            infos_base(N*(tm-1)+tn, :) = [0 tn tm 0 0 0 0 0];
            % 1. imgidx, 2.X, 3. Y, 4. distance to P(NEXT), 5. distance to P(PREV),
            % 6. Region number,
            % 7. Angle(degree) based on P(PREV),
            % 8. Angle(index) (horizontal:1, up:2, down:3Åj
        end
    end
    ones_ = ones(size(infos_base, 1),1);
    fprintf([num2str(toc), ' seconds \n']);

    for order_fromfirst=1:opt.n_order_fromfirst
        %order_fromfirst: take consider from the 1st to nth saccade

        rand('state',rand_param*trial*order_fromfirst);

        fprintf('---------------- order_fromfirst: %d\n', order_fromfirst);

        thresholdLength = opt.thresholdLength{order_fromfirst};

        sample_order1 = sample_saccade(find(sample_saccade(:,2)<=order_fromfirst&sample_saccade(:,8)==1),:);
        sample_order1_perm = randperm(size(sample_order1, 1));
        sample_order1 = sample_order1(sample_order1_perm, :);% random reordered

        %---------------

        num_near_all = 0;
        num_far_all = 0;
        c_near = 0;
        c_far = 0;


        num_feat_A = 10;
        infomat_near_distance = zeros(opt.posisize*1.1,1);
        if(opt.enable_angle)
            infomat_near_A = zeros(opt.posisize*1.1,3*num_feat_A*size(thresholdLength,2));
            infomat_far_A = zeros(opt.posisize*opt.ngrate*1.1,3*num_feat_A*size(thresholdLength,2));
        else
            infomat_near_A = zeros(opt.posisize*1.1,num_feat_A*size(thresholdLength,2));
            infomat_far_A = zeros(opt.posisize*opt.ngrate*1.1,num_feat_A*size(thresholdLength,2));
        end

        rate = 1;
        psamples = tool.get_distance(1)*tool.get_distance(1)*1.05*pi*size(sample_order1, 1);
        if(psamples > opt.posisize)
            rate = psamples/opt.posisize;
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
            sample_imgidx = sample_order1(find(sample_order1(:,1)==imgidx),:);
            if(size(sample_imgidx, 1)==0)
                clear sample_imgidx
                continue
            end

            c1 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{1}{1}, [M N], 'bilinear');
            c2 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{1}{2}, [M N], 'bilinear');
            c3 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{1}{3}, [M N], 'bilinear');
            i1 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{2}{1}, [M N], 'bilinear');
            i2 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{2}{2}, [M N], 'bilinear');
            i3 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{2}{3}, [M N], 'bilinear');
            o1 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{3}{1}, [M N], 'bilinear');
            o2 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{3}{2}, [M N], 'bilinear');
            o3 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{3}{3}, [M N], 'bilinear');

            color = imresize(ALLFeatures{imgidx}.graphbase.top_level_feat_maps{1}, [M N], 'bilinear');
            intensity = imresize(ALLFeatures{imgidx}.graphbase.top_level_feat_maps{2}, [M N], 'bilinear');
            orientation = imresize(ALLFeatures{imgidx}.graphbase.top_level_feat_maps{3}, [M N], 'bilinear');
            % face = faceFeatures{imgidx};
            face = imresize(faceFeatures{imgidx}, [M N], 'bilinear');

            for i=1:size(sample_imgidx,1)
                infomat = infos_base;
                infomat(:,1) = imgidx;
                t_px = sample_imgidx(i, 3);
                t_py = sample_imgidx(i, 4);
                t_nx = sample_imgidx(i, 5);
                t_ny = sample_imgidx(i, 6);

                infomat(:,4) = ...
                    sqrt(((t_nx+0.5).*ones_-infomat(:,2)).*((t_nx+0.5).*ones_-infomat(:,2))+...
                         ((t_ny+0.5).*ones_-infomat(:,3)).*((t_ny+0.5).*ones_-infomat(:,3)));
                infomat(:,5) = ...
                    sqrt(((t_px+0.5).*ones_-infomat(:,2)).*((t_px+0.5).*ones_-infomat(:,2))+...
                         ((t_py+0.5).*ones_-infomat(:,3)).*((t_py+0.5).*ones_-infomat(:,3)));

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

                t_infomat_near = infomat(find(infomat(:,4)<opt.th_near&infomat(:,6)~=0),:);
                t_infomat_far = infomat(find(infomat(:,4)>opt.th_far&infomat(:,6)~=0),:);
                num_near_all = num_near_all + size(t_infomat_near, 1);
                num_far_all = num_far_all + size(t_infomat_far, 1);

                t_infomat_near_sel = randperm(size(t_infomat_near,1));
                t_infomat_far_sel = randperm(size(t_infomat_far,1));

                t_infomat_near_sel = t_infomat_near_sel(1:round(size(t_infomat_near,1)/rate)); %adjust positive sample to 
                t_infomat_far_sel = t_infomat_far_sel(1:size(t_infomat_near_sel,2)*opt.ngrate);
%% Positive samples

                for j=1:size(t_infomat_near_sel,2)
                    ji=t_infomat_near_sel(j);
                    c_near = c_near+1;
                    item = t_infomat_near(ji,:)';
                    region_idx = item(6);
                    region_stat_near(1,region_idx) = region_stat_near(1,region_idx)+1;
                    angle_idx = item(8);
                    infomat_near_distance(c_near, 1) = item(4);
                    item_main = [c1(item(3),item(2)) c2(item(3),item(2)) c3(item(3),item(2))...
                                 i1(item(3),item(2)) i2(item(3),item(2)) i3(item(3),item(2))...
                                 o1(item(3),item(2)) o2(item(3),item(2)) o3(item(3),item(2)) face(item(3),item(2)) ];

                    if(opt.enable_angle)
                        infomat_near_A(c_near,num_feat_A*3*(region_idx-1)+(angle_idx-1)*num_feat_A+1:num_feat_A*3*(region_idx-1)+angle_idx*num_feat_A)=item_main(:);
                    else
                        infomat_near_A(c_near,num_feat_A*(region_idx-1)+1:num_feat_A*region_idx)=item_main(:);
                    end
                    clear item item_main
                end
%% Negative samples

                for j=1:size(t_infomat_far_sel,2)
                    ji=t_infomat_far_sel(j);
                    c_far = c_far + 1;
                    item = t_infomat_far(ji,:)';
                    region_idx = item(6);
                    region_stat_far(region_idx) = region_stat_far(region_idx)+1;
                    angle_idx = item(8);
                    item_main = [c1(item(3),item(2)) c2(item(3),item(2)) c3(item(3),item(2))...
                                 i1(item(3),item(2)) i2(item(3),item(2)) i3(item(3),item(2))...
                                 o1(item(3),item(2)) o2(item(3),item(2)) o3(item(3),item(2)) face(item(3),item(2)) ];

                    if(opt.enable_angle)
                        infomat_far_A(c_far,num_feat_A*3*(region_idx-1)+(angle_idx-1)*num_feat_A+1:num_feat_A*3*(region_idx-1)+angle_idx*num_feat_A)=item_main(:);
                    else
                        infomat_far_A(c_far,num_feat_A*(region_idx-1)+1:num_feat_A*region_idx)=item_main(:);
                    end

                    clear item item_main
                end

                clear t_px t_py t_nx t_ny infomat t_infomat_near t_infomat_far t_infomat_near_sel t_infomat_far_sel
            end

            clear sample_imgidx c1 c2 c3 i1 i2 i3 o1 o2 o3 color intensity orientation face
        end
        fprintf([num2str(toc), ' seconds \n']);
        fprintf('all: num_near:%d num_far:%d\n', num_near_all, num_far_all);
        fprintf('use: num_near:%d num_far:%d\n', c_near, c_far);

        infomat_near_distance = tool.gauss(opt.u_sigma, infomat_near_distance(1:c_near,:));

        infomat_near_A = infomat_near_A(1:c_near,:);
        infomat_far_A = infomat_far_A(1:c_far,:);

        %featall_A = [repmat(infomat_near_distance, [1 num_feat_A*size(thresholdLength,2)]).*infomat_near_A; infomat_far_A];
        featall_A = [infomat_near_A; infomat_far_A];
        labelall = [ones(c_near, 1); zeros(c_far, 1)];

        clear infomat_near_A infomat_near_distance

        fprintf('Training...\n'); tic
        info_tune = {};

        fprintf('|tune|');
        [m_,n_] = size(featall_A);
        %[info_tune.weight,info_tune.resnorm,info_tune.residual,info_tune.exitflag,info_tune.output,info_tune.lambda]  =  lsqnonneg(featall_A, labelall);
        [info_tune.weight,info_tune.resnorm,info_tune.residual,info_tune.exitflag,info_tune.output,info_tune.lambda]  =  lsqlin(featall_A, labelall,-eye(n_,n_),zeros(n_,1));
        fprintf([num2str(toc), ' seconds \n']);

        clear featall_A labelall

        if(order_fromfirst == 5)
            order_fromfirst_ = 0;
        else
            order_fromfirst_ = order_fromfirst;
        end

        NSS_tune = testSaliencymap(opt, ALLFeatures, faceFeatures, thresholdLength, info_tune.weight, testingsamles, order_fromfirst_);

        mInfo_tune{trial}{order_fromfirst} = info_tune;
        mNSS_tune{trial}{order_fromfirst} = NSS_tune;

        clear info_tune

    end
    mTraining{trial} = sample_saccade;
end

opt.end_time = datestr(now,'dd-mmm-yyyy HH:MM:SS');
time_stamp = datestr(now,'yyyymmddHHMMSS');
savefile = sprintf('../Output/storage/EXP_%s_angle%dregion%dTestSub%d_%s.mat', ...
                   opt.time_stamp, opt.enable_angle, opt.n_region, indiviNum, time_stamp);
save(savefile,'opt','mNSS_tune','mInfo_tune','mTraining','-v7.3');
