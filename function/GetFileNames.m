function FileName=GetFileNames(TestList)
Fid1=fopen(TestList,'r');
if Fid1==-1
    sprintf('%s','Can not open to Read');
    error(['cannot open to Read ',TestList]);   
end

Count1=0;
while 1
    Count1=Count1+1;
    tempFileName{Count1}=fgetl(Fid1);
    if tempFileName{Count1}==-1
        break;
    end
end
fclose(Fid1);
FileName=tempFileName(1:Count1-1);

return;