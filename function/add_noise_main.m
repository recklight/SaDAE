function add_noise_main(InputPar)
BuildFilePth = './data/list';
if exist(BuildFilePth,'dir')==0
    mkdir(BuildFilePth);
end

BuildFileNameTr = 'training.txt';
BuildFileNameTs = 'testing.txt';
lib = dir('.\data\clean\**\*.wav');

fid_tr = fopen(fullfile(BuildFilePth,BuildFileNameTr),'wb');
fid_ts = fopen(fullfile(BuildFilePth,BuildFileNameTs),'wb');
for i = 1:length(lib)
    if ~or(strcmp(lib(i).name,'sa1.wav'), strcmp(lib(i).name,'sa2.wav'))
        lib_split = split(fullfile(lib(i).folder,lib(i).name),'clean\');
        if strfind(lib(i).folder,'train')
            fprintf(fid_tr,'%s\r\n',char(lib_split(2)));
        else
            fprintf(fid_ts,'%s\r\n',char(lib_split(2)));
        end
    end
end
fclose(fid_tr);
fclose(fid_ts);
%% training data
TrClnRoot='./data/clean/';
TrNoyRoot='./data/training/';
TrMxNRoot='./data/training/mixednoise/';
TrListPth='./data/list/training.txt';

PtListPth=GetFileNames(TrListPth);
TrClLiPth=cell(length(PtListPth),1);
TrNyLiPth=cell(length(PtListPth),1);
TrNsLiPth=cell(length(PtListPth),1);
NoiseInfo=cell(length(PtListPth),2);

for ListInd=1:length(PtListPth)
    TrClLiPth{ListInd,1}=[TrClnRoot,PtListPth{ListInd}];
    spli_train=split(PtListPth{ListInd},'train');
    TrNyLiPth{ListInd,1}=fullfile(TrNoyRoot,'noisy',spli_train{2});
    TrNsLiPth{ListInd,1}=fullfile(TrMxNRoot,spli_train{2});
    
    if exist(fileparts(TrNyLiPth{ListInd,1}),'dir') ~=7
        mkdir(fileparts(TrNyLiPth{ListInd,1}));
        mkdir(fileparts(TrNsLiPth{ListInd,1}));
    end
end

TrNosRoot='./data/training/noise/';
TrNosSNRi=20:-1:-10;
NosName=dir([TrNosRoot,'**/*.wav']);
for FilNum=1:length(PtListPth)
    NoiseInfo{FilNum,1}=[TrNosRoot,NosName(mod(FilNum-1,length(NosName)-2)+3).name];
    NoiseInfo{FilNum,2}=TrNosSNRi(mod(FilNum-1,length(TrNosSNRi))+1);
end

parfor FilNum=1:length(PtListPth)
    add_noise(TrClLiPth{FilNum,1},NoiseInfo{FilNum,1},TrNyLiPth{FilNum,1},TrNsLiPth{FilNum,1},NoiseInfo{FilNum,2},'tr');
end

%% testing data
TsClnRoot='./data/clean/';
TsNoyRoot='./data/testing/';
TsMxNRoot='./data/testing/mixednoise/';
TsListPth='./data/list/testing.txt';

TsPtListPth=GetFileNames(TsListPth);
TsClLiPth=cell(length(TsPtListPth),1);
TsNyLiPth=cell(length(TsPtListPth),1);
TsNsLiPth=cell(length(TsPtListPth),1);

for ListInd=1:length(TsPtListPth)
    TsClLiPth{ListInd,1}=[TsClnRoot,TsPtListPth{ListInd}];
end

TsNosRoot='./data/testing/noise/';
TsNosSNRi=-5:5:5;
TsNosName=dir(TsNosRoot);
for j=3:length(TsNosName)
    for i=1:length(TsNosSNRi)
        for ListInd=1:length(TsClLiPth)
            spli_test=split(TsPtListPth{ListInd},'test');
            if TsNosSNRi(i) >= 0
                TsnoiySNRAbbr=fullfile(TsNoyRoot,'noisy',lower(TsNosName(j).name(1:end-4)),[num2str(abs(TsNosSNRi(i))),'dB'],spli_test{2});
                TsmxnySNRAbbr=fullfile(TsMxNRoot,lower(TsNosName(j).name(1:end-4)),[num2str(abs(TsNosSNRi(i))),'dB'],spli_test{2});                
            else
                TsnoiySNRAbbr=fullfile(TsNoyRoot,'noisy',lower(TsNosName(j).name(1:end-4)),['n',num2str(abs(TsNosSNRi(i))),'dB'],spli_test{2});
                TsmxnySNRAbbr=fullfile(TsMxNRoot,lower(TsNosName(j).name(1:end-4)),['n',num2str(abs(TsNosSNRi(i))),'dB'],spli_test{2});
            end
            mkdir(fileparts(TsnoiySNRAbbr));mkdir(fileparts(TsmxnySNRAbbr));
            TsNoisePath=sprintf('%s%s',TsNosRoot,TsNosName(j).name);
            
            add_noise(TsClLiPth{ListInd,1},TsNoisePath,TsnoiySNRAbbr,TsmxnySNRAbbr,TsNosSNRi(i),'ts');
        end
    end
end

%% Listing (.txt) 
write_txt(InputPar.TrInpList, dir('.\data\training\noisy\**\*.wav'));
write_txt(InputPar.TsInpList, dir('.\data\testing\noisy\**\*.wav'));
write_txt(InputPar.TrRefList, dir('.\data\clean\train\**\*.wav'));

end

function write_txt(BuileFileName,list)

fid = fopen(BuileFileName,'wb');
for i = 1:length(list)
     if ~or(strcmp(list(i).name,'sa1.wav'), strcmp(list(i).name,'sa2.wav'))
         fprintf(fid,'%s\r\n',fullfile(list(i).folder,list(i).name));
     end
end
fclose(fid);

end