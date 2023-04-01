clearAllMemoizedCaches;
filename='data1.xlsx';
opts = detectImportOptions(filename,'NumHeaderLines',0);
data = readtable(filename,opts);

%run model for 24 hour data and output figures
[data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_num_gen,data_eff,initial_energy,text]=getdata(data);
num_gen=numel(data_cost_para);
max_cost_para=max(cost_para);
[total_rev,pow,pow_char,pow_discharge,ener_lev,pi,v,granularity]=periodonlineoptimize(time_input,data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_eff,initial_energy)
[a,b,c,d]=outputfigures(data_demand,granularity,ener_lev,pow_char,pow_discharge,pow,data_max_stor,pi,data_cost_para,text)

%combined effect of granularity and Eo
time_input= [5,15,30,60];


%model analysis
% effect of granularity on energy storage charge and discharge?
[test_granular,reve_,vmax]=impact_granular(data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_num_gen,data_eff,initial_energy)
[sensi,rev]=impact_weight(data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_num_gen,data_eff,initial_energy)
[pow_char,pow_discharge,ener,pri]=effect_Eo(time_input, data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_eff)

%functions for model analysis
%analyse impact of granularity
function [g,revenues,weight]=impact_granular(data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_num_gen,data_eff,initial_energy)
g=[double(5),double(15),double(30),double(60)];
revenues=zeros(1,numel(g));
weight=zeros(1,numel(g));
for j=1:numel(g)
    granularity=g(j);
    [total_revenue,~,~,~,~,~,v]=periodonlineoptimize(granularity,data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_num_gen,data_eff,initial_energy);
    revenues(j)=total_revenue;
    weight(j)=v;
end
end

%analyse impact of Vmax
function [beta,revenues]=impact_weight(data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_eff,initial_ener)
beta=0.5:0.1:1.2;
granularity=double(5);
vmax=(data_max_stor-2*granularity*data_max_pow_cap)/(max(data_cost_para));
revenues=zeros(1,numel(beta));
v_values=zeros(1,numel(beta));
for k=1:numel(beta)
    v=0;
    v=v+beta(k)*vmax;
    v_values(k)=v;
    [total_revenue]=periodonlineoptimize(granularity,data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_eff,initial_ener,v);
    revenues(k)=total_revenue;
end
end

%impact of initial energy level --> granularity must be set to 5 minutes
%for the function to work
function [pow_char,pow_discharge,ener,pri]=effect_Eo(time_input,data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_eff)
i=double(data_max_stor./6);                         %time_input,data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_eff
v=0:i:data_max_stor;
k=numel(data_demand)-1;
if time_input==double(5)
    step=1;
elseif time_input==double(15)
    step=3;
elseif time_input==double(30)
    step=6;
elseif time_input==double(60)
    step=12;
end
x=(1:step:k);
y=numel(x);
p=numel(data_cost_para);
ener=cell(p,y+1);
pri=cell(p,y);
pow_char=cell(p,y);
pow_discharge=cell(p,y); %time_input,demand,cost_para,max_pow,min_pow,max_stor,max_pow_cap,eff,initial_ener,v
for l=1:numel(v)
    ener_o=v(l);
    [~,~,z,x,s,t,~]=periodonlineoptimize(time_input,data_demand,data_cost_para,data_max_pow,data_min_pow,data_max_stor,data_max_pow_cap,data_eff,ener_o);
    ener(l,:)=num2cell(double(s));
    pri(l,:)=num2cell(double(t));
    pow_char(l,:)=num2cell(double(z));
    pow_discharge(l,:)=num2cell(double(x));
end
end

%impact of cost parameter proximity (run after optimization has been run)
function [ma,mi,avg_para,stdev]=cost_prox(data_cost_para,total_revenue,ener_level)
ma=max(data_cost_para);
mi=min(data_cost_para);
avg_para=mean(cost_para);
stdev=std(cost_para);
x=plot(data_cost_para,total_revenue);
y=plot(data_cost_para,ener_level);
end