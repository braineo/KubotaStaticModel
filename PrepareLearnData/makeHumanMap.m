% ------------------
%ディスプレイと目との距離(m)
set_length_d2e = 1.33;
%解像度(pixel)とそれに対応する実寸(m)
set_kaizodo = 768.0;
set_nagasa = 0.802;
get_angle = @(d) (atan(d*set_nagasa/set_kaizodo/set_length_d2e)*180.0/pi);
get_distance = @(a) (tan(a*pi/180.0)*set_length_d2e*set_kaizodo/set_nagasa);
% ------------------


load('../storage/EXPALLFixations.mat'); % EXPALLFixations

EXPFIXATIONPERIMG = {};

fprintf('Making gaussian: %d ...', i); tic

height = 768/2;
width = 1366/2;

sigma = get_distance(2)/2;
gw = 500;
gh = 500;
gfilter = zeros(gh+1, gw+1);
gcx = gw/2+1;
gcy = gh/2+1;
for tj=1:gh+1
  for ti=1:gw+1
    gfilter(tj, ti) = gfilter(tj, ti) + 1/(2*pi*sigma^2)*exp(-(((double(gcx-ti))^2+(double(gcy-tj)^2))/(2*sigma^2)));
  end
end

fprintf([num2str(toc), ' seconds \n']);

for i=1:400
    fprintf('Making: %d ...', i); tic

    sigma = get_distance(2)/2;
    filter = zeros(height, width);
    % ws = 5.0 * sigma;
    for subject=1:length(EXPALLFixations{i})
        for idx=2:size(EXPALLFixations{i}{subject}.medianXY, 1)
            % idx==1は中心なので無視
            x = fix(EXPALLFixations{i}{subject}.medianXY(idx, 1)/2+0.5);%四捨五入
            y = fix(EXPALLFixations{i}{subject}.medianXY(idx, 2)/2+0.5);%四捨五入
            
            for tj=max(1, y-gh/2):min(height, y+gh/2)
              for ti=max(1, x-gw/2):min(width, x+gw/2)
                filter(tj, ti) = filter(tj, ti) + gfilter(gcy-(y-tj),gcx-(x-ti));
              end
            end
        end
    end
    % filter = imresize(filter, [200 200]);
    map = filter/max(max(filter));
    map = uint8(map*255);
    
    idx = length(EXPFIXATIONPERIMG) + 1;
    EXPFIXATIONPERIMG{i} = map;
    
    fprintf([num2str(toc), ' seconds \n']);
    
    % break;
end

savefile = '../storage/EXPFIXATIONPERIMG.mat'
save(savefile, 'EXPFIXATIONPERIMG', '-v7.3');
