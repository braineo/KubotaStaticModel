function NSS_tune = testSaliencymap(opt, ALLFeatures, faceFeatures, thresholdLength, weight, testingdata, fromfirst, fortest)

if((nargin >= 8)&(fortest == 1))
    fortest_flag = 1;
else
    fortest_flag = 0;
end

% ------------------
tool = toolFunc(opt);
M = opt.M;
N = opt.N;
% ------------------

NSS_tune =[];
imagefiles = dir(fullfile(opt.IMGS, '*.jpg'));
[filenames{1:size(imagefiles,1)}] = deal(imagefiles.name);
numImgs = length(imagefiles);
fixsize = [M N];

%outputcsv = 'result.csv';
%fid = fopen(outputcsv, 'w');

fprintf('Creating infos_base...\n'); tic
infos_base = zeros(M*N, 8);
for tm=1:M
    for tn=1:N
        infos_base(N*(tm-1)+tn, :) = [tn tm 1 0 0 0 0 0]; % imgidx X Y P(NEXT)Ç‹Ç≈ÇÃãóó£ P(PREV)Ç©ÇÁÇÃãóó£ ãÊï™î‘çÜ P(PREV)äÓèÄÇÃäpìx äpìxãÊï™Åiç∂âE:1,è„:2,â∫:3Åj
    end
end
ones_ = ones(size(infos_base, 1),1);
fprintf([num2str(toc), ' seconds \n']);

fprintf('%d testing datas\n', length(testingdata));
fprintf('Start testing... '); tic
fprintf('\n');
index_ = 1;
pre_imgidx = 0;
for testidx=1:length(testingdata)
    if(mod(testidx,fix(length(testingdata)/10))==0)
        if(~fortest_flag)
            fprintf('*');
        end
    end

    imgidx = testingdata{testidx}.imgidx;
    num_feat = 10;

    if(pre_imgidx ~= imgidx)
        clear c1 c2 c3 i1 i2 i3 o1 o2 o3 color intensity orientation face org
        if(fortest_flag)
            org = imresize(imread(strcat(strcat(opt.IMGS, '\'), filenames{imgidx})), fixsize, 'bilinear');
        end
        c1 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{1}{1}, fixsize, 'bilinear');
        c2 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{1}{2}, fixsize, 'bilinear');
        c3 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{1}{3}, fixsize, 'bilinear');
        i1 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{2}{1}, fixsize, 'bilinear');
        i2 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{2}{2}, fixsize, 'bilinear');
        i3 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{2}{3}, fixsize, 'bilinear');
        o1 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{3}{1}, fixsize, 'bilinear');
        o2 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{3}{2}, fixsize, 'bilinear');
        o3 = imresize(ALLFeatures{imgidx}.graphbase.scale_maps{3}{3}, fixsize, 'bilinear');
        color = imresize(ALLFeatures{imgidx}.graphbase.top_level_feat_maps{1}, fixsize, 'bilinear');
        intensity = imresize(ALLFeatures{imgidx}.graphbase.top_level_feat_maps{2}, fixsize, 'bilinear');
        orientation = imresize(ALLFeatures{imgidx}.graphbase.top_level_feat_maps{3}, fixsize, 'bilinear');
        % face = faceFeatures{imgidx};
        face = imresize(faceFeatures{imgidx}, fixsize, 'bilinear');
        pre_imgidx = imgidx;
    end

    nss_t = [];
    nss_t1 = [];
    nss_t2 = [];
    for i=1:size(testingdata{testidx}.sacinfo)
        if((fromfirst>0)&&(i > fromfirst))
            break
        end

        if(testingdata{testidx}.sacinfo(i, 6) == 0)
            continue
        end

        t_px = round(testingdata{testidx}.sacinfo(i, 1)+0.5);
        t_py = round(testingdata{testidx}.sacinfo(i, 2)+0.5);
        t_nx = round(testingdata{testidx}.sacinfo(i, 3)+0.5);
        t_ny = round(testingdata{testidx}.sacinfo(i, 4)+0.5);
        %fprintf('IMG(%d),P(%f,%f),N(%f,%f)\n', imgidx, t_px, t_py, t_nx, t_ny);

        t_dis = testingdata{testidx}.sacinfo(i, 5);

        infos = infos_base;
        infos(:,3) = imgidx.*ones_;

        % íÜêSÇ©ÇÁÇÃãóó£ÇåvéZ
        infos(:,4) = sqrt((t_nx.*ones_-infos(:,1)).*(t_nx.*ones_-infos(:,1))+(t_ny.*ones_-infos(:,2)).*(t_ny.*ones_-infos(:,2)));
        infos(:,5) = sqrt((t_px.*ones_-infos(:,1)).*(t_px.*ones_-infos(:,1))+(t_py.*ones_-infos(:,2)).*(t_py.*ones_-infos(:,2)));

        if(opt.enable_angle)
            infos(:,7) = atan2(-(infos(:,2)-(t_py+0.5).*ones_), abs(infos(:,1)-(t_px+0.5).*ones_));

            infos(find(infos(:,7)>-pi/4&infos(:,7)<pi/4),8) = 1; % ç∂âE
            infos(find(infos(:,7)>=pi/4),8) = 2; % è„
            infos(find(infos(:,7)<=-pi/4),8) = 3; % â∫
        end

        calNp = 0;

        for k=1:size(thresholdLength, 2)
            if(t_dis < thresholdLength(1, k))
                calNp = k;
                break
            end
        end

        %infos(find(infos(:,5)<tool.get_distance(2)),6) = -1;
        for k=1:size(thresholdLength, 2)
            infos(find(infos(:,5)<thresholdLength(k)&infos(:,6)==0),6) = k;
        end
        %infos(find(infos(:,6)==-1),6) = 0;
        %imshow(double(reshape(infos(:,6), N, M))'./max(infos(:,6)));
        %hold on;
        %plot(t_px, t_py, 'g+');
        %plot(t_nx, t_ny, 'y+');

        regionIdxMat = reshape(infos(:,6), N, M)';
        angleIdxMat = reshape(infos(:,8), N, M)';

        result_tune = zeros(fixsize);
        for k=1:length(thresholdLength)
            %if(calNp ~= k)
            %    continue
            %end
            if(opt.enable_angle)
                for ai=1:3
                    calIdx = find(regionIdxMat(:,:)==k&angleIdxMat(:,:)==ai);
                    baseIdx = num_feat*3*(k-1)+(ai-1)*num_feat;
                    result_tune(calIdx) = ...
                        weight(baseIdx+1).*c1(calIdx) + weight(baseIdx+2).*c3(calIdx) + weight(baseIdx+3).*c3(calIdx) + ...
                        weight(baseIdx+4).*i1(calIdx) + weight(baseIdx+5).*i2(calIdx) + weight(baseIdx+6).*i3(calIdx) + ...
                        weight(baseIdx+7).*o1(calIdx) + weight(baseIdx+8).*o2(calIdx) + weight(baseIdx+9).*o3(calIdx) + weight(baseIdx+10).*face(calIdx);
                end
            else
                calIdx = find(regionIdxMat(:,:)==k);

                result_tune(calIdx) = ...
                    weight(num_feat*(k-1)+1).*c1(calIdx) + weight(num_feat*(k-1)+2).*c3(calIdx) + weight(num_feat*(k-1)+3).*c3(calIdx) + ...
                    weight(num_feat*(k-1)+4).*i1(calIdx) + weight(num_feat*(k-1)+5).*i2(calIdx) + weight(num_feat*(k-1)+6).*i3(calIdx) + ...
                    weight(num_feat*(k-1)+7).*o1(calIdx) + weight(num_feat*(k-1)+8).*o2(calIdx) + weight(num_feat*(k-1)+9).*o3(calIdx) + weight(num_feat*(k-1)+10).*face(calIdx);
            end
        end

        %imshow(result_tune./max(max(result_tune)));
        %hold on;
        %plot(t_px, t_py, 'g+');
        %plot(t_nx, t_ny, 'y+');

        result_tune_copy = result_tune;
        [result_tune, meanVec_tune, stdVec_tune] = convert4NSS(result_tune, find(regionIdxMat(:,:)>0));
        nss_t = [nss_t result_tune(t_ny, t_nx)];
        %fprintf('invlid: %d, val:%f\n', length(find(regionIdxMat(:,:)==0)), result_tune(t_ny, t_nx));
        %break

        if(fortest_flag)
            %å¯â Å|
            %if((index_ == 2604)|(index_ == 1021)|(index_ ==2600)|(index_ ==1091)|(index_ ==2568)|(index_ == 186)|(index_ ==2611)|(index_ ==2717)|(index_ ==2623)|(index_ ==2838))
            %å¯â Å{
            %if((index_ == 2777)|(index_ ==1949)|(index_ ==2030)|(index_ ==1104)|(index_ == 1279)|(index_ ==1950)|(index_ ==2849)|(index_ ==2810)|(index_ ==1911)|(index_ ==2606))
            %èCò_óp
            %if((index_ == 1100)|(index_ == 405)|(index_ == 2151))
            if((index_ == 1100))
                fprintf('index:%d,img:%d,sacorder:%d,dis:%f,val:%f,P(%d,%d),N(%d,%d)\n', index_, imgidx, i, t_dis, result_tune(t_ny, t_nx), t_px, t_py, t_nx, t_ny);
                imshow(result_tune_copy./max(max(result_tune_copy)));
                hold on;
                plot(t_px, t_py, 'g+');
                plot(t_nx, t_ny, 'y+');
                filename = sprintf('eps/%d_%d_%d_%d.eps', index_, imgidx, opt.enable_angle, i);
                print('-depsc2', filename);
                %filename = sprintf('jpg/%d_%d_%d_%d.jpg', index_, imgidx, opt.enable_angle, i);
                %print('-djpeg', filename);
                close
                imshow(org);
                hold on;
                plot(t_px, t_py, 'g+');
                plot(t_nx, t_ny, 'y+');
                filename = sprintf('eps/%d_%d_org_%d.eps', index_, imgidx, i);
                print('-depsc2', filename);
                filename = sprintf('jpg/%d_%d_org_%d.jpg', index_, imgidx, i);
                print('-djpeg', filename);
                close
                imshow(heatmap_overlay(org, result_tune_copy./max(max(result_tune_copy))));
                hold on;
                plot(t_px, t_py, 'g+');
                plot(t_nx, t_ny, 'y+');
                filename = sprintf('eps/%d_%d_%d_overlay_%d.eps', index_, imgidx, opt.enable_angle, i);
                print('-depsc2', filename);
                filename = sprintf('jpg/%d_%d_%d_overlay_%d.jpg', index_, imgidx, opt.enable_angle, i);
                print('-djpeg', filename);
                close

                gbvsf_ = color + intensity + orientation + face;
                gbvs_ = color + intensity + orientation;
                imshow(heatmap_overlay(org, gbvs_./max(max(gbvs_))));
                hold on;
                plot(t_px, t_py, 'g+');
                plot(t_nx, t_ny, 'y+');
                filename = sprintf('eps/%d_%d_%d_gbvs_%d.eps', index_, imgidx, opt.enable_angle, i);
                print('-depsc2', filename);
                filename = sprintf('jpg/%d_%d_%d_gbvs_%d.jpg', index_, imgidx, opt.enable_angle, i);
                print('-djpeg', filename);
                close
                imshow(heatmap_overlay(org, gbvsf_./max(max(gbvsf_))));
                hold on;
                plot(t_px, t_py, 'g+');
                plot(t_nx, t_ny, 'y+');
                filename = sprintf('eps/%d_%d_%d_gbvsf_%d.eps', index_, imgidx, opt.enable_angle, i);
                print('-depsc2', filename);
                filename = sprintf('jpg/%d_%d_%d_gbvsf_%d.jpg', index_, imgidx, opt.enable_angle, i);
                print('-djpeg', filename);
                close

                if(i==1)
                    imshow(c1./max(max(c1)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_c1.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_c1.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(c3./max(max(c3)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_c2.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_c2.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(c3./max(max(c3)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_c3.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_c3.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(i1./max(max(i1)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_i1.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_i1.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(i3./max(max(i3)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_i2.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_i2.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(i3./max(max(i3)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_i3.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_i3.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(o1./max(max(o1)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_o1.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_o1.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(o3./max(max(o3)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_o2.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_o2.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(o3./max(max(o3)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_o3.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_o3.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                    imshow(face./max(max(face)));
                    hold on;
                    filename = sprintf('eps/%d_%d_%d_face.eps', index_, imgidx, opt.enable_angle);
                    print('-depsc2', filename);
                    filename = sprintf('jpg/%d_%d_%d_face.jpg', index_, imgidx, opt.enable_angle);
                    print('-djpeg', filename);
                    close
                end
                gbvs_copy = gbvs_;
                [gbvs_copy] = convert4NSS(gbvs_copy, find(regionIdxMat(:,:)>0));
                nss_t1 = [nss_t1 gbvs_copy(t_ny, t_nx)];
                gbvsf_copy = gbvsf_;
                [gbvs_copy] = convert4NSS(gbvsf_copy, find(regionIdxMat(:,:)>0));
                nss_t2 = [nss_t2 gbvsf_copy(t_ny, t_nx)];
            end
        end

        clear result_tune result_tune_copy

    end

    if(length(nss_t)>0)
        if((index_ == 1100)&&fortest_flag)
            mean(nss_t1)
            mean(nss_t2)
            mean(nss_t)
        end
        NSS_tune =[NSS_tune mean(nss_t)];
        index_ = index_ + 1;
    else
        % fprintf('invlid_testidx: %d\n', testidx);
    end
    %break
end

%fclose(fid);
fprintf([num2str(toc), ' seconds \n']);