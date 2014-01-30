%%%%%%%%%%%%%%%%%%%% Change Parameter here %%%%%%%%%%%%%%%%%%%%%%%%%%%
datafolder = '../Data/prefDataCSV/';
savefile = '..Data/EXPALLFixationsPref.mat';
datasetSize = 450;
testSubjectNumber = 25;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

EXPALLFixations = {};
for imgidx = 1:datasetSize
    Fixations = {};
    EXPALLFixations{imgidx} = Fixations;
end

for imgidx = 1:datasetSize
    for subject = 1:testSubjectNumber
        datafile = sprintf('%s%02d%03d.csv', datafolder, subject, imgidx);
        if(~exist(datafile))
            continue
        else
            eyedata = load(datafile);
            [data,Fix,Sac] = getFixations(eyedata);
            EXPALLFixations{imgidx}{length(EXPALLFixations{imgidx})+1}=Fix;
        end
    end
end

save(savefile, 'EXPALLFixations', '-v7.3');
