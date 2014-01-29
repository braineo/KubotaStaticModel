function [trainingdata, T_pos, T_neg, testingdata] = makeSample(EXPALLFixations)

% ------------------
%ディスプレイと目との距離(m)
set_length_d2e = 1.33;
%解像度(pixel)とそれに対応する実寸(m)
set_kaizodo = 768.0;
set_nagasa = 0.802;
get_angle = @(d) (atan(d*set_nagasa/set_kaizodo/set_length_d2e)*180.0/pi);
get_distance = @(a) (tan(a*pi/180.0)*set_length_d2e*set_kaizodo/set_nagasa);
% ------------------

% Inputs
IMGS = 'C:\hg\Master\data\exp\EXP201109\images\final_resize'; %Change this to the path on your local computer
imagefiles = dir(fullfile(IMGS, '*.jpg'));
numImgs = length(imagefiles);

% サンプルを取得
fprintf('Parsing EXPALLFixations...'); tic
%load('../storage/EXPALLFixations.mat'); % EXPALLFixations

trainingdata = {};
testingdata = {};

minimize_scale = 3;
width = 1366;
height = 768;
M = round(height/minimize_scale);
N = round(width/minimize_scale);

for imgidx=1:400
    for sub=1:length(EXPALLFixations{imgidx})
        if(size(EXPALLFixations{imgidx}{sub}.medianXY, 1) < 2)
            continue;
        end
    
        if rand < 0.1
            testinfo = {};
            testinfo.medianXY = EXPALLFixations{imgidx}{sub}.medianXY;
            testinfo.imgidx = imgidx;
            testingdata{length(testingdata)+1} = testinfo;
            continue;
        end
    
        for i=2:size(EXPALLFixations{imgidx}{sub}.medianXY, 1)
            if(i > 4)
                break
            end
            if(EXPALLFixations{imgidx}{sub}.medianXY(i, 1) < 0 || EXPALLFixations{imgidx}{sub}.medianXY(i, 2) < 0 || ...
               EXPALLFixations{imgidx}{sub}.medianXY(i, 1) >= width || EXPALLFixations{imgidx}{sub}.medianXY(i, 2) >= height)
                continue
            end
            dt = {};
            dt.PX = EXPALLFixations{imgidx}{sub}.medianXY(i-1, 1)/minimize_scale;
            dt.PY = EXPALLFixations{imgidx}{sub}.medianXY(i-1, 2)/minimize_scale;
            dt.NX = EXPALLFixations{imgidx}{sub}.medianXY(i, 1)/minimize_scale;
            dt.NY = EXPALLFixations{imgidx}{sub}.medianXY(i, 2)/minimize_scale;
            dt.imgidx = imgidx;
            trainingdata{length(trainingdata)+1} = dt;
            % fprintf('img:%d, sub:%d, i:%d\n', imgidx, sub, i);
        end
    end
end

fprintf([num2str(toc), ' seconds \n']);

posPtsPerImg=100;
negPtsPerImg=100;

kyokai = {get_distance(6), get_distance(9), get_distance(12), get_distance(16), get_distance(22), get_distance(80)};
tneg = {};
tpos = {};
for k=1:length(kyokai)
    tneg{k} = [];
    tpos{k} = [];
end

fprintf('Creating infos_base...\n'); tic
infos_base = zeros(M*N, 4);
for tm=1:M
    for tn=1:N
        infos_base(N*(tm-1)+tn, :) = [tn tm 1 0];
    end
end
ones_ = ones(size(infos_base, 1),1);
fprintf([num2str(toc), ' seconds \n']);

fprintf('Selecting Traing and Testing Datas...\n'); tic

fprintf('%d training datas\n', length(trainingdata));

th1 = get_distance(1.0)/minimize_scale;
th2 = get_distance(4.0)/minimize_scale;

for i=1:length(trainingdata)
    if(mod(i,20)==0)
        fprintf('%d|', i);
    end
    
    infos = infos_base;
    infos(:,3) = trainingdata{i}.imgidx.*ones_;
    nx_ = trainingdata{i}.NX;
    ny_ = trainingdata{i}.NY;
    px_ = trainingdata{i}.PX;
    py_ = trainingdata{i}.PY;

    infos(:,4) = sqrt(((nx_+0.5).*ones_-infos(:,1)).*((nx_+0.5).*ones_-infos(:,1))+((ny_+0.5).*ones_-infos(:,2)).*((ny_+0.5).*ones_-infos(:,2)));
    infos_near = infos(find(infos(:,4)<th1.*ones_),:);
    infos_far = infos(find(infos(:,4)>th2.*ones_),:);

    sel_near = randperm(size(infos_near, 1));
    sel_far = randperm(size(infos_far, 1));
    
    if(size(infos_near, 1) < 100)
        fprintf('(error: IMAGE(%d)P(%f,%f)N(%f,%f))', trainingdata{i}.imgidx, px_, py_, nx_, ny_);
        continue
    end
    
    for j=1:100
        koho = zeros(1,3);
        koho = infos_near(sel_near(j), 1:3);
        dis = norm([((px_+0.5)-koho(1)) ((py_+0.5)-koho(2))]);
        for k=1:length(kyokai)
            if(dis < kyokai{k}/minimize_scale)
                tpos{k} = [tpos{k}; koho];
                break
            end
        end
    end
    
    for j=1:100
        koho = zeros(1,3);
        koho = infos_far(sel_far(j), 1:3);
        dis = norm([((px_+0.5)-koho(1)) ((py_+0.5)-koho(2))]);
        for k=1:length(kyokai)
            if(dis < kyokai{k}/minimize_scale)
                tneg{k} = [tneg{k}; koho];
                break
            end
        end
    end
    
    if(mod(i,400)==0)
        fprintf('\n')
    end
    
    %if(i == 500)
    %    break;
    %end
end
fprintf('\n')

fprintf([num2str(toc), ' seconds \n']);

fprintf('...\n'); tic

T_neg = {};
T_pos = {};
for k=1:length(kyokai)
    T_neg{k} = [];
    T_pos{k} = [];
end

for imgidx=1:400
    for k=1:length(kyokai)
        tt = tneg{k}(find(tneg{k}(:,3)==imgidx.*ones(length(tneg{k}),1)),:);
        pl = size(tt,1);
        p = randperm(pl);
        tt2 = [];
        tt2 = tt(p(1:min(negPtsPerImg,pl)),:);
        T_neg{k} = [T_neg{k};tt2];
        
        tt = tpos{k}(find(tpos{k}(:,3)==imgidx.*ones(length(tpos{k}),1)),:);
        pl = size(tt,1);
        p = randperm(pl);
        tt2 = [];
        tt2 = tt(p(1:min(posPtsPerImg,pl)),:);
        T_pos{k} = [T_pos{k};tt2];
    end
end

fprintf([num2str(toc), ' seconds \n']);

%savefile = '../storage/EXPSamples.mat'
%save(savefile, 'tpos','tneg','T_pos', 'T_neg','trainingdata','testingdata', '-v7.3');

