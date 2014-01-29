function [thresholdLength, thresholdAngle, n_samples_each_region] = getThresholdLength(order_fromfirst, EXPALLFixations, opt)

tool = toolFunc(opt);

fprintf('Calculate thresholdLength ...'); tic

dis = zeros(100000,1);
c_sample_saccade=0;
for imgidx=1:450
    for subidx=1:length(EXPALLFixations{imgidx})
        fix_length = size(EXPALLFixations{imgidx}{subidx}.medianXY, 1);
        if(fix_length < 2)
            continue
        end

        for i=2:fix_length
            valid_flag = 1;
            %% delete gaze points where are out of range, and whose distance is less than a mininum value      
            if(EXPALLFixations{imgidx}{subidx}.medianXY(i, 1) < 0 || EXPALLFixations{imgidx}{subidx}.medianXY(i, 2) < 0 || ...
               EXPALLFixations{imgidx}{subidx}.medianXY(i, 1) >= opt.width || EXPALLFixations{imgidx}{subidx}.medianXY(i, 2) >= opt.height)
                valid_flag = 0;
            end
            t_px = EXPALLFixations{imgidx}{subidx}.medianXY(i-1, 1)/opt.minimize_scale;
            t_py = EXPALLFixations{imgidx}{subidx}.medianXY(i-1, 2)/opt.minimize_scale;
            t_nx = EXPALLFixations{imgidx}{subidx}.medianXY(i, 1)/opt.minimize_scale;
            t_ny = EXPALLFixations{imgidx}{subidx}.medianXY(i, 2)/opt.minimize_scale;
            t_dis = norm([t_px-t_nx t_py-t_ny]);

            if((opt.discard_short_saccade > 0) && (t_dis < opt.discard_short_saccade))
                valid_flag = 0;
            end
            
            if(valid_flag == 1)
                c_sample_saccade = c_sample_saccade + 1;
                dis(c_sample_saccade,:) = [t_dis];
            end

            clear t_px t_py t_nx t_ny t_dis valid_flag
            
            if(order_fromfirst == i-1)
                break
            end
        end

        clear fix_length
    end
end
dis = dis(1:c_sample_saccade,:);

[dis_sort,dis_sort_index] = sortrows(dis, 1);

thresholdLength = zeros(1, opt.n_region);
thresholdAngle = zeros(1, opt.n_region);
n_samples_each_region = zeros(1, opt.n_region);

c_sample_saccade
set_flag = 0;
% 's_uni': some certain number of sample 'l_uni': certain length 'input':
% thresholdAngle initialization
if(strcmp(opt.thresholdLengthType, 's_uni'))
    for i=1:opt.n_region
        if(i == opt.n_region)
            % thresholdLength(1, i) = dis_sort(fix(i*c_sample_saccade/opt.n_region),1);
            thresholdLength(1, i) = tool.get_distance(46);
        else
            thresholdLength(1, i) = (dis_sort(fix(i*c_sample_saccade/opt.n_region),1)+dis_sort(fix(i*c_sample_saccade/opt.n_region)+1,1))/2;
        end
        thresholdAngle(1, i) = tool.get_angle(thresholdLength(1, i));
    end
    set_flag = 1;
elseif (strcmp(opt.thresholdLengthType, 'input'))
    if(length(opt.thresholdAngleInit) == opt.n_region)
        for i=1:opt.n_region
            if(i == opt.n_region)
                % thresholdLength(1, i) = dis_sort(fix(i*c_sample_saccade/opt.n_region),1);
                thresholdLength(1, i) = tool.get_distance(57);
                thresholdAngle(1, i) = tool.get_angle(thresholdLength(1, i));
            else
                thresholdLength(1, i) = tool.get_distance(opt.thresholdAngleInit{i});
                thresholdAngle(1, i) = opt.thresholdAngleInit{i};
            end
        end
    end
end

if(set_flag==0)
    %'l_uni' or 'input'‚à¤§ƒGƒ‰[
    maxlength = dis_sort(end, 1);
    region_dif = maxlength/opt.n_region;
    region_base = 0;
    for i=1:opt.n_region
        region_base = region_base + region_dif;
        if(i == opt.n_region)
            thresholdLength(1, i) = tool.get_distance(57);
        else
            thresholdLength(1, i) = region_base;
        end
        thresholdAngle(1, i) = tool.get_angle(thresholdLength(1, i));
    end
end

for i=1:opt.n_region
    if(i == 1)
        start_dis = 0;
        end_dis = thresholdLength(1, i);
    else
        start_dis = thresholdLength(1, i-1);
        end_dis = thresholdLength(1, i);
    end
    n_samples_each_region(1, i) = length(find(dis_sort(:,1)>=start_dis&dis_sort(:,1)<end_dis));
end

%fclose(fid);
fprintf([num2str(toc), ' seconds \n']);
