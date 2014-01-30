% retrieve postive sample and negative from feature maps,
% accroding to fixation location.

function [featurePixelValueNear, featurePixelValueFar] = getFeatureSample(opt, sampleinfo, featureMaps,faceFeatures, imagei)
    positiveSample = sampleinfo{1};
    negativeSample = datasample(sampleinfo{2}, size(positiveSample,1)*opt.negaPosRatio);
    
    % 1. imagei, 2.X, 3. Y, 4. Region number, 5. Angle(index) 6. timeTag (frame number)
    num_feat_A = opt.featNumber;
    % Allocate storage
    if(opt.enable_angle)
        featurePixelValueNear = zeros(size(positiveSample, 1), 3*num_feat_A*opt.n_region); % 3 directions, feature numbers, n regions
        featurePixelValueFar = zeros(size(negativeSample, 1),3*num_feat_A*opt.n_region);
    else
        featurePixelValueNear = zeros(size(positiveSample, 1), num_feat_A*opt.n_region);
        featurePixelValueFar = zeros(size(negativeSample,1),num_feat_A*opt.n_region);
    end
    
    M = opt.M;
    N = opt.N;
    countNearAll = 0;
    countFarAll = 0;
    for framei = timeTag'
        
        if(framei > opt.allFrameNumber)
            continue;
        else
            % reading feature map values
            c = cell(1,3);
            i = cell(1,3);
            o = cell(1,3);
            
            % fprintf('fetching feature map of frame#%03d\n', framei);
            for scaleLeveli = 1: 3
                c{scaleLeveli} = imresize(featureMaps{imagei}.graphbase.scale_maps{1}{scaleLeveli}, [M N], 'bilinear');
                i{scaleLeveli} = imresize(featureMaps{imagei}.graphbase.scale_maps{3}{scaleLeveli}, [M N], 'bilinear');
                o{scaleLeveli} = imresize(featureMaps{imagei}.graphbase.scale_maps{5}{scaleLeveli}, [M N], 'bilinear');
            end
            
            face = imresize(faceFeatures{imgIdx}, [M N], 'bilinear');
            
            posIdx = find(positiveSample(:,5) == imagei)';
            negIdx = find(negativeSample(:,5) == imagei)';
            %% Postive Sample values
            for j = posIdx
                singleSample = positiveSample(j,:);
                angleIndex = singleSample(4);
                regioni = singleSample(3);
                countNearAll = countNearAll + 1;

                tmpX = singleSample(2); % actually is Y
                tmpY = singleSample(1); % acutally is X
                singleFeature = [c{1}(tmpX,tmpY) c{2}(tmpX,tmpY) c{3}(tmpX,tmpY)...
                                 i{1}(tmpX,tmpY) i{2}(tmpX,tmpY) i{3}(tmpX,tmpY)...
                                 o{1}(tmpX,tmpY) o{2}(tmpX,tmpY) o{3}(tmpX,tmpY)...
                                 face(tmpX,tmpY)];
                if(opt.enable_angle)
                    featurePixelValueNear(countNearAll,num_feat_A*3*(regioni-1)+(angleIndex-1)*num_feat_A+1:num_feat_A*3*(regioni-1)+angleIndex*num_feat_A)=singleFeature(:);
                else
                    featurePixelValueNear(countNearAll,num_feat_A*(regioni-1)+1:num_feat_A*regioni)=singleFeature(:);
                end
            end
            
            clear tmpX tmpY
            %% Negative Samples
            for j = negIdx
                singleSample = negativeSample(j,:);
                angleIndex = singleSample(4);
                regioni = singleSample(3);
                countFarAll = countFarAll + 1;
                
                tmpX = singleSample(2);
                tmpY = singleSample(1);
                singleFeature = [c{1}(tmpX,tmpY) c{2}(tmpX,tmpY) c{3}(tmpX,tmpY)...
                                 i{1}(tmpX,tmpY) i{2}(tmpX,tmpY) i{3}(tmpX,tmpY)...
                                 o{1}(tmpX,tmpY) o{2}(tmpX,tmpY) o{3}(tmpX,tmpY)...
                                 face(tmpX,tmpY)];
                if(opt.enable_angle)
                    featurePixelValueFar(countFarAll,num_feat_A*3*(regioni-1)+(angleIndex-1)*num_feat_A+1:num_feat_A*3*(regioni-1)+angleIndex*num_feat_A)=singleFeature(:);
                else
                    featurePixelValueFar(countFarAll,num_feat_A*(regioni-1)+1:num_feat_A*regioni)=singleFeature(:);
                end
                
            end
        end
    end
    fprintf('pos: %d, neg: %d\n', countNearAll, countFarAll)