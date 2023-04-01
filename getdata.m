function [demand,cost_para,max_pow,min_pow,max_stor,max_pow_cap,num_gen,eff,initial_ener,text]=getdata(Data)
demand=rmmissing(Data.Demand);
cost_para=rmmissing(Data.CostParameter)';
max_pow =rmmissing(Data.MaximumPower);
min_pow =rmmissing(Data.MinimumPower);
max_stor=rmmissing(Data.MaximumStorageCapacity);
max_pow_cap=rmmissing(Data.StoragePowerCapacity);
num_gen=numel(cost_para);
eff=rmmissing(Data.Efficiency);
initial_ener=rmmissing(Data.InitialStorage);
text=rmmissing(Data.GenerationSource);
end