function Labeling(InputPar)
%=================
%2019.1.12
%=================
% 建立 label -> for every frame
% Training Data: 3696, 462  person
% Testing Data: 192, 24 perason
%vsn是有沒有聲音的index，長度跟data01一樣，0表示沒語音，1則是有語音的位置
%=========================================
% SpecPersonLabel, 給予每個語者標籤, Train(1~462), Test(1~24)
% SpecSilenceLabel, 標出每個音檔有聲(1)語無聲(0)的地方
% SpecFrameCounter, 紀錄每個音檔的Frame數量
%=========================================
Tr_label(InputPar)
% Ts_label(InputPar)

end

function Tr_label(InputPar)
pp.pr=0.999; % Speech probability threshold
ZeroLabel=zeros(512,1);

MyListTr = InputPar.TrRefList;
% MyListTs = InputPar.TsRefList;
MyTrainCleanList=GetFileNames(MyListTr);

filenum=length(MyTrainCleanList);
SpecFrameCounter=zeros(filenum,1);
SpecSilenceLabel = [];
CounterNum =[];
SpecPersonLabel =[];
LabelNum = 1;

for i = 1:filenum
    [x,fs] = audioread(MyTrainCleanList{i});
    [vsn,~] = v_vadsohn([x;ZeroLabel],fs,'a',pp); 
    vsn = v_patch(vsn(1:size(x,1),1));
    Spec_vsn = sum(FeatureExtract(vsn,InputPar))'; 
    Spec_vsn(Spec_vsn>0) = 1; 
    SpecFrameCounter(i)=size(Spec_vsn,1);
    
    if isempty(SpecSilenceLabel)      
        SpecSilenceLabel = Spec_vsn;
        
        CounterNum = sum(SpecFrameCounter);
        SpecPersonLabel(1:CounterNum,1) = LabelNum;
    else
        SpecSilenceLabel = [SpecSilenceLabel;Spec_vsn];    
        
        FrontCounterNum = sum(SpecFrameCounter(1:i-1));
        CounterNum = sum(SpecFrameCounter(1:i));
        SpecPersonLabel(FrontCounterNum+1 : CounterNum,1) = LabelNum;
    end
    
    if mod(i,8) == 0, LabelNum=LabelNum+1;end 
end
ZeroLocation = find(~SpecSilenceLabel);
SpecPersonLabel(ZeroLocation,1) = 0; %silence -> 0
% save('./data/concat/SpecSilenceLabel.mat','SpecSilenceLabel','-v7.3');
% save('./data/concat/SpecFrameCounter.mat','SpecFrameCounter','-v7.3');
save('./data/concat/SpecPersonLabel.mat','SpecPersonLabel','-v7.3');
end

function Ts_label(InputPar)
% 1-192 files, total frames 36321
pp.pr=0.999; % Speech probability threshold
ZeroLabel=zeros(512,1);

% MyListTr = InputPar.TrRefList;
MyListTs = InputPar.TsRefList;
MyTsCleanList=GetFileNames(MyListTs);

filenum=length(MyTsCleanList);
TsSpecFrameCounter=zeros(filenum,1);
TsSpecSilenceLabel = [];TsCounterNum =[];TsSpecPersonLabel =[];
TsLabelNum = 1;

for i = 1:filenum
    [x,fs] = audioread(MyTsCleanList{i});
    [vsn,~] = v_vadsohn([x;ZeroLabel],fs,'a',pp); 
    vsn = VADPatch(vsn(1:size(x,1),1)); 
    Spec_vsn = sum(FeatureExtract(vsn,InputPar))'; 
    Spec_vsn(Spec_vsn>0) = 1;   
    TsSpecFrameCounter(i)=size(Spec_vsn,1);

    if isempty(TsSpecSilenceLabel)      
        TsSpecSilenceLabel = Spec_vsn;
        
        TsCounterNum = sum(TsSpecFrameCounter);
        TsSpecPersonLabel(1:TsCounterNum,1) = TsLabelNum;
    else
        TsSpecSilenceLabel = [TsSpecSilenceLabel;Spec_vsn];    
        
        FrontCounterNum = sum(TsSpecFrameCounter(1:i-1));
        TsCounterNum = sum(TsSpecFrameCounter(1:i));
        TsSpecPersonLabel(FrontCounterNum+1 : TsCounterNum,1) = TsLabelNum;
    end   
    
    if mod(i,8) == 0, TsLabelNum=TsLabelNum+1;end    
end
ZeroLocation = find(~TsSpecSilenceLabel);
TsSpecPersonLabel(ZeroLocation,1) = 0;

%192 testing data, 3 noises, 4 SNRs -> 12 times
TsSpecPersonLabel12Times =[];
for i=1:12
    TsSpecPersonLabel12Times =[TsSpecPersonLabel12Times ; TsSpecPersonLabel];
end
% save('./data/concat/SpecSilenceLabel.mat','SpecSilenceLabel','-v7.3');
% save('./data/concat/SpecFrameCounter.mat','SpecFrameCounter','-v7.3');
save('./data/concat/TsSpecPersonLabel12Times.mat','TsSpecPersonLabel12Times','-v7.3');
end

