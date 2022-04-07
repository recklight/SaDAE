function Test_Matlab_Python(InputPar)
InpSorceList = InputPar.TsInpList;

Ws   = InputPar.Ws;
FeaDim = InputPar.FeaDim;
load('./data/concat/NormParm.mat'); %Load FeatureExtraction正規化後儲存之參數

InpSorceListX=GetFileNames(InpSorceList)';
filenum=length(InpSorceListX);
FrameCounter=zeros(1,filenum);
StrInd=1;

load '.\data\concat\TsSpecNoisy.mat'
load '.\data\concat\TsSpecNoisyFrameCounter.mat'
load '.\data\concat\TsSpecNoisyParPhase.mat'
load '.\ReconSpectrumPatch.mat'; 

EnhancedData=double(ReconSpectrumPatch);

EnhancedDataFinal = EnhancedData; % output:S
% EnhancedDataFinal = EnhancedData+NoisyData;% output: S/Y

FinalStepSaveData(InpSorceListX,[StrInd;filenum],EnhancedDataFinal',NoyParPhase,FrameCounter,FeaDim,InputPar);

end

function FinalStepSaveData(OutWavFile,FilInd,EnhancedData,NoyPar,FrameCounter,FeaDim,InputPar)

OutFilePth = InputPar.RsOutPth;
FirInd=FilInd(1);LstInd=FilInd(2);
fs=InputPar.SampleRate;
for i=FirInd:LstInd
    EnhData=[];EnhFeat=[];    
    if FirInd ~= i
        StrPt=sum(FrameCounter(1,FirInd:i-1))+1;
    else
        StrPt=1;
    end
    FinPt=StrPt+FrameCounter(1,i)-1;
    EnhData=EnhancedData(:,StrPt:FinPt);
    EnhFeat=SpectrumRecoverFromPatch(EnhData,FeaDim);

    EnhFeat=power(10,EnhFeat);
    NoyParameter=[];NoyParameter=NoyPar(:,StrPt:FinPt);    
    siga=Feature2Wave(EnhFeat,NoyParameter,InputPar);
    SplitList = split(OutWavFile{i},'noisy');
    
    FileOutPath=fullfile(OutFilePth,InputPar.runName,SplitList{2});
    if exist(fileparts(FileOutPath),'dir') ~= 7
        mkdir(fileparts(FileOutPath));
    end
   audiowrite(FileOutPath,siga,fs);
   siga=[];
    
end
end
