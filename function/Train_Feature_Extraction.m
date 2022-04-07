function Train_Feature_Extraction(InputPar)
Ws   = InputPar.Ws;
CleanData=[];NoisyData=[];CleanS=[];NoisyS=[];NoiseS=[];

MyCleanList=GetFileNames(InputPar.TrRefList);
MyNoisyList=GetFileNames(InputPar.TrInpList);
% MyNoiseList=GetFileNames(MyTrainNoiseList);

for i=1:length(MyNoisyList)   
    x=audioread(MyCleanList{i});x=(x-mean(x));
    TmpFea=[];TmpFea=FeatureExtract(x,InputPar);
    ClnPowSpec=[];ClnPowSpec=log10(TmpFea+1e-13);
    
%     x=audioread(MyNoiseList{i});x=(x-mean(x));
%     TmpFea=[];TmpFea=FeatureExtract(x,InputPar);    
%     NoisePowSpec=[];NoisePowSpec=log10(TmpFea+1e-13);  
    
    x=audioread(MyNoisyList{i});x=(x-mean(x));
    TmpFea=[];TmpFea=FeatureExtract(x,InputPar);
    NoyPowSpec=[];NoyPowSpec=log10(TmpFea+1e-13);
    
    CleanS=[CleanS;ClnPowSpec'];    
%     NoiseS=[NoiseS;NoisePowSpec'];    
    NoisyS=[NoisyS;NoyPowSpec'];    
end

%% Clean (output)
outdata=[];outdata=CleanS;
save('./data/concat/TrainData_clean.mat','outdata','-v7.3');
clear outdata 
%% ksi, gamma 
% ksi=[];ksi=2*(CleanS-NoiseS);
% gamma=[];gamma=2*(NoisyS-NoiseS);
% save('./data/concat/ksi.mat','ksi','-v7.3');
% save('./data/concat/gamma.mat','gamma','-v7.3');
% clear NoiseS
%% ksi+gamma
% outdata=[];outdata=[ksi,gamma];
% save('./data/concat/TrainData_XG.mat','outdata','-v7.3');
% clear outdata 
%% ksi+gamma+Clean
% outdata=[];outdata=[ksi,gamma,CleanS];
% save('./data/concat/TrainData_XGC.mat','outdata','-v7.3');
% clear outdata 
%% S/Y
outdata=[];outdata=CleanS-NoisyS;
save('./data/concat/TrainData_snr.mat','outdata','-v7.3');
clear outdata 
clear CleanS
%% Noisy (input)
NoisySX=(MakePatchesFromX(NoisyS',Ws))';
indata=[];indata=MVNormalized(NoisySX);        
save('./data/concat/TrainData_noisy.mat','indata','-v7.3');
clear indata
%%
NoyInfo=RenewedMV(NoisySX);
NoyMVInfo.Mean=NoyInfo.Mean;    %Average data Info
NoyMVInfo.Vari=NoyInfo.Vari;    %Std of data Info
save('./data/concat/NormParm.mat','NoyMVInfo','-v7.3');
clear NoyMVInfo NoisySX

end

function OutMat=MVNormalized(InpMat)
%Then normalize by the standard deviation.
OutMat=zeros(size(InpMat));
Avrg=mean(InpMat);
Vari=std(InpMat);
OutMat=bsxfun(@rdivide, bsxfun(@minus, InpMat,Avrg), Vari);

end

function MVInfo=RenewedMV(InpMat)
MVInfo.Mean=mean(InpMat);
MVInfo.Vari=std(InpMat);

end
