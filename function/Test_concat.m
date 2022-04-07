function Test_concat(InputPar)
InpSorceList = InputPar.TsInpList;
Ws   = InputPar.Ws;
load('./data/concat/NormParm.mat');

InpSorceListX=GetFileNames(InpSorceList)';
FrameCounter=zeros(1,length(InpSorceListX));
NoisyData=[];NoisyDataX=[];NoyParPhase=[];

for i=1:length(InpSorceListX)
    TmpFea=[];NoyParmeterPhase=[];
    x=audioread(InpSorceListX{i});x=(x-mean(x));
    [TmpFea,NoyParmeterPhase]=FeatureExtract(x,InputPar);
    TmpFea=log10(TmpFea+1e-14);
    NoyParPhase=[NoyParPhase,NoyParmeterPhase];
    FrameCounter(i)=size(TmpFea,2);
    NoisyData=[NoisyData,TmpFea];
end
NoisyDataX=MakePatchesFromX(NoisyData,Ws);
TsNorNoisyData=bsxfun(@rdivide,bsxfun(@minus,NoisyDataX,NoyMVInfo.Mean'), NoyMVInfo.Vari');
TsNorNoisyData=TsNorNoisyData';
NoisyData=NoisyData';

save '.\data\concat\TsSpecNoisy.mat' NoisyData -v7.3
save '.\data\concat\TsSpecNoisyParPhase.mat' NoyParPhase -v7.3
save '.\data\concat\TsSpecNoisyFrameCounter.mat' FrameCounter -v7.3
save '.\data\concat\TsNorNoisyData.mat' TsNorNoisyData -v7.3

clear NoisyData NoyParPhase FrameCounter TsNorNoisyData

end

