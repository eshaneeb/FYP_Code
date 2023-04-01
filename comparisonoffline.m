%comparison with offline LMP
%offline LP for multiple periods
offline_rev=0;
p=0;
granularity=double(1/12);
filenames=["onlinetesting.xlsx","data1.xlsx", "data2.xlsx", "data3.xlsx", "data4.xlsx", "data5.xlsx", "data6.xlsx", "data7.xlsx"]; %add filenames to test, each file with 288 periods
offline_revenues=zeros(1,numel(filenames));
periods=zeros(1,numel(filenames));

for i=1:numel(filenames) 
    clearAllMemoizedCaches;
    filename=char(filenames(1));
    opts = detectImportOptions(filename,'NumHeaderLines',0);
    data = readtable(filename,opts);
    [data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_num_gen,data_eff,~,text]=getdata(data);
    [total_rev,pow,pow_char,pow_discharge,ener_lev,prices]=offline(granularity,data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_eff);
    offline_rev=offline_rev+total_rev;
    offline_revenues(i)=offline_rev;
    p=p+288;
    periods(i)=p;
end


%online revenue for multiple periods
online_revenues=zeros(1,numel(filenames));
periods=zeros(1,numel(filenames));
online_rev=0;
p=0;
for i=1:numel(filenames)
    clearAllMemoizedCaches;
    filename=char(filenames(1));
    opts = detectImportOptions(filename,'NumHeaderLines',0);
    data = readtable(filename,opts);
    [data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_num_gen,data_eff,initial_ener,text]=getdata(data);
    [total_rev,pow,pow_char,pow_discharge,ener_lev,pi,v]=periodonlineoptimize(granularity,data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_num_gen,data_max_pow_cap,data_eff);
    online_rev=online_rev+total_rev;
    online_revenues(i)=online_rev;
    p=p+288;
    periods(i)=p;
end
