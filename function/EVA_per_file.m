function EVA_per_file(InputPar)
% 計算量大時，請參考parfor
% 按噪聲數量作平行運算

txt_outdir = 'eva_result';
if exist(txt_outdir,'dir') ~=7, mkdir(txt_outdir);end

enh_dir = dir(fullfile('data\enhanced',InputPar.runName,'**\*.wav'));

fid = fopen(sprintf('%s%s%s.txt',txt_outdir,filesep,InputPar.runName),'wb');
fprintf(fid,'%21:\t%11s\t%10s\t%10s\t%10s\n','EVALUATED METHODS','PESQ','SDI','STOI','SSNRI');

for i = 1:length(enh_dir)
    split_enh_reuName = split(enh_dir(i).folder,InputPar.runName);
    split_enh_dB = split(enh_dir(i).folder,'dB');
    
    EnhadDataFile=fullfile(enh_dir(i).folder, enh_dir(i).name);    
    NoisyDataFile=fullfile('data\testing\noisy',split_enh_reuName{2},enh_dir(i).name);    
    CleanDataFile=fullfile('data\clean\test',split_enh_dB{2},enh_dir(i).name);
    
    [TCleanData,~]=audioread(CleanDataFile);
    [TNoisyData,~]=audioread(NoisyDataFile);
    [TEnhadData,fe]=audioread(EnhadDataFile);
    
    minimum_points=min([length(TCleanData),length(TNoisyData),length(TEnhadData)]);
    Idx=1:minimum_points;    
    
    CleanData=TCleanData(Idx);
    NoisyData=TNoisyData(Idx);
    EnhadData=TEnhadData(Idx);
    len=256;
    stoi_scor = stoi(CleanData, EnhadData, fe); 
    sdi=compute_sdi(CleanData,EnhadData);
    ssnr_dB=ssnr(EnhadData,NoisyData,CleanData,256);
    
    [~,strout]=system(['function\pesq.exe +16000 ',CleanDataFile,' ',EnhadDataFile]);
    c=strfind(strout,'Prediction : PESQ_MOS = ');
    pesq_mos=str2double(strout(c+23:c+28));
    
    InFileName = fullfile(split_enh_reuName{2},enh_dir(i).name);
    fprintf(fid,'%20s:\t%f\t%f\t%f\t%f\n',InFileName, pesq_mos,sdi,stoi_scor,ssnr_dB);

end
fclose(fid);

delete '_pesq_results.txt'
delete '_pesq_itu_results.txt'
end

