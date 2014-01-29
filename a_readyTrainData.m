%% Script to generate Kubota et al.'s model
% add GBVS to path by executing gbvs_install under ~/toolbox/gbvs
%%
addpath(genpath('./PrepareLearnData'));
addpath(genpath('./Dependence'));
addpath(genpath('./makeModel'));
addpath(genpath('../Toolbox/JuddSaliencyModel'));
addpath(genpath('../Toolbox/SaliencyToolbox'));

% 1. generate GBVS saliency map
makeALLFeatures; %% remember to change the parameters of the path to stimuli and savefile

% 2. generate fixation location
makeALLFixation; %% remember to change the parameters

% 3. generate face location
makeFaceFeature; %% remember to change the parameters

