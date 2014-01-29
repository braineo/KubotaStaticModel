%% makeSampleInfo, return all sample infomation

function [sampleInfo, opt] = makeSampleInfo(opt_set,saccadeData,subjecti)
    sampleInfo = {};
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

    nthSaccade = opt.n_order_fromfirst;

    subjectSaccade=cell(12);
    rand_param = 0;
%     for subjecti = 1:12
        [sample_saccade, testingsamles] = getIndiTTsamples(rand_param, saccadeData, opt, subjecti);
        subjectSaccade{subjecti} = sample_saccade;
%     end

    fprintf('Creating infos_base...\n'); tic
    infos_base = zeros(M*N, 8);
    for tm=1:M
        for tn=1:N
            infos_base(N*(tm-1)+tn, :) = [0 tn tm 0 0 0 0 0];
            % 1. imgi, 2.X, 3. Y, 4. distance to P(NEXT), 5. distance to P(PREV),
            % 6. Region number,
            % 7. Angle(degree) based on P(PREV),
            % 8. Angle(index) (horizontal:1, up:2, down:3)
        end
    end

    allOnesMat = ones(size(infos_base, 1),1);
    fprintf([num2str(toc), ' seconds \n']);

%     for subjecti = 1:12
        fprintf('---------------- Subject#: %d\n', subjecti);
        
        
         nthi = nthSaccade;
            fprintf('---------------- nthSaccade: %d\n', nthi);
            thresholdLength = opt.thresholdLength{nthi};
            sample_saccade = subjectSaccade{subjecti};
            sampleSaccadeOrderSelected = sample_saccade(find(sample_saccade(:,2)<=nthi&sample_saccade(:,8)==1),:);
            num_feat_A = 10; %total number of features
            fprintf('Prepare Training data...\n'); tic
            infomatNear = [];
            infomatFar =[];       
            
            for imgi = 1:450
                
                if(mod(imgi,10)==0)
                    fprintf('%d, ', imgi);
                end
                if(mod(imgi,100)==0)
                    fprintf('\n');
                end
                sampleIndexSelected = sampleSaccadeOrderSelected(find(sampleSaccadeOrderSelected(:,1)==imgi),:);
                if(size(sampleIndexSelected, 1)==0)
                    clear sampleIndexSelected
                    continue
                end
                
                for i=1:size(sampleIndexSelected,1)
                    %% Fill in infomat
                    infomat = infos_base;
                    infomat(:,1) = imgi;
                    t_px = sampleIndexSelected(i, 3);
                    t_py = sampleIndexSelected(i, 4);
                    t_nx = sampleIndexSelected(i, 5);
                    t_ny = sampleIndexSelected(i, 6);
                    % 1. imgi, 2.X, 3. Y, 
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

                    
                    infomat(:,7) = ...
                        atan2(-(infomat(:,3)-(t_py+0.5).*allOnesMat), abs(infomat(:,2)-(t_px+0.5).*allOnesMat));

                    infomat(find(infomat(:,7)>-pi/4&infomat(:,7)<pi/4),8) = 1; %direction: horizontal
                    infomat(find(infomat(:,7)>=pi/4),8) = 2; %direction: up
                    infomat(find(infomat(:,7)<=-pi/4),8) = 3; %direction: down
                    
                    
                    for k=1:size(thresholdLength,2)
                        infomatRegionedNear{k} = infomat(find(infomat(:,4)<opt.th_near & infomat(:,6) == k),:);
                        infomatRegionedFar{k} = infomat(find(infomat(:,4)>opt.th_far & infomat(:,6) == k),:);
                    end
                end
                
                sampleInfo{subjecti}{imgi}{1} = infomatRegionedNear;
                sampleInfo{subjecti}{imgi}{2} = infomatRegionedFar;
                
            end
%     end
end
