function SaDAE_Matlab_Python
clear all;clc
addpath(genpath(cd));
warning off

InputPar.runName = 'CK_SaDAE';

%% Parameter Setting
InputPar.SampleRate  =16000;        
InputPar.FFT_SIZE    =512;
InputPar.FrameSize   =512; 
InputPar.FrameRate   =256;
InputPar.FeaDim      =InputPar.FrameSize/2+1;
InputPar.Ws = 5;

InputPar.TrRefList ='./data/list/training_clean.list';
InputPar.TrInpList ='./data/list/training_noisy.list';
InputPar.TsInpList ='./data/list/testing_noisy.list'; 

InputPar.RsOutPth = './data/enhanced';
%% add noise
add_noise_main(InputPar)

%% Pre-Proc.
Train_Feature_Extraction(InputPar);
Labeling(InputPar)
Test_concat(InputPar)

%% Train
concat_data_dir = './data/concat';
spk_eps = 40;
spe_eps = 300;
CmdName=sprintf("python ./SaDAE_MatPy.py --MdName=%s --data_dir=%s --spk_eps=%d --spe_eps=%d",InputPar.runName,concat_data_dir,spk_eps,spe_eps);
system(CmdName);

% SaDAE ���G
% CmdName=sprintf("python ./SaDAE_MatPy.py --MdName=%s --retest",InputPar.runName);
% system(CmdName);

%% Test
Test_Matlab_Python(InputPar);

%% 
EVA_per_file(InputPar);

