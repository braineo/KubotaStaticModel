%% Output the result of individualDiff_angle0_region6 to CSV
% Output 15 files for 15 subjects

clear vals_tune
% loadfile = '../Output/storage/individualDifference/indiviDiff_20130313_angle0_region6_trial30/individualDiff_angle0_region6_201303141930.mat'
% load(loadfile);

regioni = 6;
time_stamp = datestr(now,'yyyymmddHHMM');


%% Output Average and standard deviation for all individual weights
for outputi = 1:2
    if outputi == 1
        outputType = 'average';
    else
        outputType = 'deviation';
    end

    outputcsv = sprintf('EXP_angle_0_region_%d_%s.csv',regioni, outputType);
    fid = fopen(outputcsv, 'w');

    n_order_fromfirst_up = 1;
    n_region = 6;
    fprintf(fid, 'n_region,%d\n', n_region);
    if outputi == 1
        fprintf(fid, 'mean\n');
    else
        fprintf(fid, 'std\n');
    end

    vals_tune = zeros(info.opt_base.n_trial,size(EXP1_REGION_NOANGLE_ms6{regioni}.mInfo_tune{1}{1}.weight,1));
   
        for n_order_fromfirst=1:n_order_fromfirst_up
            n_trial = info.opt_base.n_trial;
            for trial=1:n_trial
                vals_tune(trial,:) = EXP1_REGION_NOANGLE_ms6{regioni}.mInfo_tune{trial}{n_order_fromfirst}.weight';
            end
        end

    % fprintf(fid, '%f, %f\n', mean(vals_tune), std(vals_tune));
    fprintf(fid, ',C1,C2,C3,I1,I2,I3,O1,O2,O3,F\n');
    if outputi == 1
        fprintf(fid, ',%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n', mean(vals_tune));
    else
        fprintf(fid, ',%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n', std(vals_tune));
    end
    fclose(fid);
end