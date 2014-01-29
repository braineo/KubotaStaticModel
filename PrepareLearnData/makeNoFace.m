clear all
stimfolder = '../Resource/final_resize\';
files=dir(fullfile(stimfolder,'*.jpg'));
[filenames{1:size(files,1)}] = deal(files.name);

minimize_scale = 4;
width = 1366;
height = 768;
M = round(height/minimize_scale);
N = round(width/minimize_scale);

fprintf('readCSV...\n'); tic
data = readCSV('C:/hg/Master/code/python/201111face.com/result.csv');
fprintf([num2str(toc), ' seconds \n']);

for imgnum=1:400
    faces = data{imgnum};
    if(length(faces)==0)
        img = imresize(imread(strcat(stimfolder, filenames{imgnum})), [M N], 'bilinear');
        imshow(img);
        hold on;
        filename = sprintf('noface/%s.jpg', filenames{imgnum});
        print('-djpeg', filename);
        filename = sprintf('noface/%s.eps', filenames{imgnum});
        print('-depsc2', filename);
        close
        clear img
    end
end
