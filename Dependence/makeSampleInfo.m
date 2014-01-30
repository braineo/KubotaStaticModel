%% makeSampleInfo, return all sample infomation for all images
% this code is only valid for static model
% error will raise if used in motion model

function sampleInfo = makeSampleInfo(opt_set,saccadeData, subjecti, imagei)

   
    opt = opt_set;
    M = opt.M;
    N = opt.N;
    tool = toolFunc(opt); % return distance on screen by angle? not really understand
    sampleInfo = {};
    
    fprintf('Subject #%02d Image #%03d trainning data...\n', subjecti, imagei);

    nthSaccade = opt.n_order_fromfirst;

    sample_saccade = getTTsamples(opt, saccadeData, subjecti, imagei);
    
    infos_base = zeros(M*N, 9);
    for tm=1:M
        for tn=1:N
            infos_base(N*(tm-1)+tn, :) = [0 tn tm 0 0 0 0 0 0];
            % 1. imagei, 2.X, 3. Y, 4. distance to P(NEXT), 5. distance to P(PREV),
            % 6. Region number,
            % 7. Angle(degree) based on P(PREV),
            % 8. Angle(index) (horizontal:1, up:2, down:3)
            % 9. time tag (frame number)
        end
    end

    allOnesMat = ones(size(infos_base, 1),1);
    

    nthi = nthSaccade;
    thresholdLength = opt.thresholdLength{nthi};

    sampleSaccadeOrderSelected = sample_saccade(find(sample_saccade(:,2)<=nthi&sample_saccade(:,8)==1),:);
    
    sampleIndexSelected = sampleSaccadeOrderSelected(find(sampleSaccadeOrderSelected(:,1)==imagei),:);
    if(size(sampleIndexSelected, 1)==0)
        clear sampleIndexSelected
        return
    end
    infoBaseSize = size(infos_base,1);
    infoAll = zeros(nthSaccade*infoBaseSize, size(infos_base,2));
    for i=1:size(sampleIndexSelected,1)
        %% Fill in infomat
        infomat = infos_base;
        infomat(:,1) = imagei;
        t_px = sampleIndexSelected(i, 3);
        t_py = sampleIndexSelected(i, 4);
        t_nx = sampleIndexSelected(i, 5);
        t_ny = sampleIndexSelected(i, 6);
        % 1. imagei, 2.X, 3. Y, 
        % 4. distance to P(Current), 5. distance to P(PREV),
        % 6. Region number,
        % 7. Angle(degree) based on P(PREV),
        % 8. Angle(index) (horizontal:1, up:2, down:3)
        % 9. timeTag (frame number)
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

        infoAll(1+(i-1)*infoBaseSize:i*infoBaseSize, :) = infomat;
    end
    
    infomatRegionedNear = [];
    infomatRegionedFar = [];
    for k=1:size(thresholdLength,2)
        infomatRegionedNear = [infomatRegionedNear; infoAll(find(infoAll(:,4)<opt.th_near & infoAll(:,6) == k),:)];
        infomatRegionedFar = [infomatRegionedFar; infoAll(find(infoAll(:,4)>opt.th_far & infoAll(:,6) == k),:)];
    end
    
    %for regioni = 1:opt.n_region
        sampleInfo{1} = infomatRegionedNear(:,[2,3,6,8]);
        sampleInfo{2} = infomatRegionedFar(:,[2,3,6,8]);
        % 1. X, 2. Y, 3. Region number, 4. Angle(index)
    %end