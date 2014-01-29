function [sample_saccade, testingsamles] = getTTsamples(rand_param, EXPALLFixations, opt, fortest)

fprintf('Selecting training & testingsamles ...'); tic

%outputcsv = 'saccade.csv';
%fid = fopen(outputcsv, 'w');
rand('state',rand_param);
sample_saccade = zeros(100000,8);
testingsamles = {};
c_sample_saccade=0;
for imgidx=1:400
    for subidx=1:length(EXPALLFixations{imgidx})
        fix_length = size(EXPALLFixations{imgidx}{subidx}.medianXY, 1);
        if(fix_length < 2)
            continue
        end
        
        training_flag = 0;
        
        if(rand >.5)
            training_flag = 1;
        end
        
        if((nargin >= 4)&(fortest == 1))
            training_flag = 0;
        end
        
        testing = {};
        testing.imgidx = imgidx;
        testing.sacinfo = zeros(fix_length-1, 6);

        for i=2:fix_length
            valid_flag = 1;
        
            if(EXPALLFixations{imgidx}{subidx}.medianXY(i, 1) < 0 || EXPALLFixations{imgidx}{subidx}.medianXY(i, 2) < 0 || ...
               EXPALLFixations{imgidx}{subidx}.medianXY(i, 1) >= opt.width || EXPALLFixations{imgidx}{subidx}.medianXY(i, 2) >= opt.height)
                valid_flag = 0;
            end
            t_px = EXPALLFixations{imgidx}{subidx}.medianXY(i-1, 1)/opt.minimize_scale;
            t_py = EXPALLFixations{imgidx}{subidx}.medianXY(i-1, 2)/opt.minimize_scale;
            t_nx = EXPALLFixations{imgidx}{subidx}.medianXY(i, 1)/opt.minimize_scale;
            t_ny = EXPALLFixations{imgidx}{subidx}.medianXY(i, 2)/opt.minimize_scale;
            t_dis = norm([t_px-t_nx t_py-t_ny]);

            if((opt.discard_short_saccade > 0) & (t_dis < opt.discard_short_saccade))
                valid_flag = 0;
            end
            
            if(training_flag == 1)
                c_sample_saccade = c_sample_saccade + 1;
                sample_saccade(c_sample_saccade,:) = [imgidx i-1 t_px t_py t_nx t_ny t_dis valid_flag];
            end
            
            testing.sacinfo(i-1, :) = [t_px t_py t_nx t_ny t_dis valid_flag];

            %fprintf(fid, '%f,%d,%d,%f\n', valid_flag, imgidx, i-1, tool.get_angle(t_dis));
            clear t_px t_py t_nx t_ny t_dis
        end

        if(training_flag == 0)
            testingsamles{length(testingsamles) + 1} = testing;
        end

        clear testing fix_length sacinfo_c
    end
end
sample_saccade = sample_saccade(1:c_sample_saccade,:);

%fclose(fid);
fprintf([num2str(toc), ' seconds \n']);

fprintf('trainingsample: %d, testingsample: %d\n', c_sample_saccade, length(testingsamles));
