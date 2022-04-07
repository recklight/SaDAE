function OutVadVector=v_patch(InpVadVector)
sr=16000;
thres=0.1;

len=length(InpVadVector);
OutVadVector=zeros(size(InpVadVector));

TransCount=1;
Rec=InpVadVector(1);
for i=2:len
    if InpVadVector(i) ~= Rec
        TransCount=TransCount+1;
        Rec=InpVadVector(i);
    end
end

TransVec=ones(1,TransCount);
Label=zeros(1,TransCount);
Rec=InpVadVector(1);
Label(1)=Rec;
TransCount=1;
for i=2:len
    if InpVadVector(i) ~= Rec         
        Rec=InpVadVector(i);        
        TransCount=TransCount+1;
        Label(TransCount)=Rec;
    else
        TransVec(TransCount)=TransVec(TransCount)+1;
    end
end

NewLabel=(TransVec >= thres*sr).*Label;

OutVadVector(1:TransVec(1))=NewLabel(1);
for i=2:length(TransVec)
    OutVadVector(sum(TransVec(1:i-1))+1:sum(TransVec(1:i)))=NewLabel(i);
end


