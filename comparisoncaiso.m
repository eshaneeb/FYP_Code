%comparison with CAISO supply data
clearAllMemoizedCaches;
filename='caisolmpdata.xlsx';
opts = detectImportOptions(filename,'NumHeaderLines',0);
data = readtable(filename,opts);

%average LMP for all CAISO Nodes over 24h period, 2213 nodes for 24h=53112
%total data elements

avg_lmp=zeros(1,24);
y=1;
for t=1:24
        o=double(t);
        x=t*2213;
        sumlmp=0;
        count=0;
        for i=y:x
            if data.Hour(i)==o & data.LMP(i)~=0
                sumlmp=sumlmp+data.LMP(i);
                count=count+1;
            end
        end
        y=y+2213;
        avg_lmp(t)=sumlmp/count;
end




