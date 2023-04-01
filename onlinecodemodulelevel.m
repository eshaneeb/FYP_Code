clearAllMemoizedCaches;
filename='onlinetesting.xlsx';
opts = detectImportOptions(filename,'NumHeaderLines',0);
Data = readtable(filename,opts);

%get data
demand=rmmissing(Data.Demand);
cost_para=rmmissing(Data.CostParameter)';
max_pow =rmmissing(Data.MaximumPower);
min_pow =rmmissing(Data.MinimumPower);
max_stor=rmmissing(Data.MaximumStorageCapacity);
max_pow_cap=rmmissing(Data.StoragePowerCapacity);
num_gen=numel(cost_para);
eff=rmmissing(Data.Efficiency);
tau=rmmissing(Data.Time);
initial_ener=rmmissing(Data.InitialStorage); 
%for 24 hours

num_gen=numel(cost_para);

time_input=60;

if time_input==double(5)
    granular=double(1/12);
    period=1440./5;
    step=1;
elseif time_input==double(15)
    granular=double(1/4);
    period=1440./15;
    step=3;
elseif time_input==double(30)
    granular=double(1/2);
    period=1440./30;
    step=6;
elseif time_input==double(60)
    granular=double(1);
    period=1440./60;
    step=12;
else
    error('Please enter a granularity of 1/12, 1/4, 1/2,or 1 for data with 5 minute resolution.')
end

%variables
pow=sdpvar(num_gen,288);
ener_lev=sdpvar(1,288+1); 
pow_char=sdpvar(1,288);
pow_discharge=sdpvar(1,288);

%non-decision variables
queue=zeros(1,288+1);
pi=zeros(1,288); %prices

if ~exist('v','var')
    v=(max_stor-2*granular*max_pow_cap)/(max(cost_para));
end

ener_lev(1)=initial_ener; %initialization of Eo,Qo, V;
queue(1)=ener_lev(1)-(granular*max_pow_cap+v* max(cost_para));

for i=1:step:288 %solve optimization for all periods, update of period (t=t+1); step 
    %for period i observe Qt, Et, and demand(i)
    %objective for period i
    objective=0;
    objective=objective+v*granular*cost_para*pow(:,i)+granular*queue(i)*(pow_char(i)*eff-pow_discharge(i)/eff)%need to change
    constraints=[ener_lev(end)==0];
    for j = 1:num_gen
        constraints= [constraints, (sum(pow(:,i))-pow_char(i)+pow_discharge(i)==demand(i))];
        constraints= [constraints, min_pow<=pow(:,i)<=max_pow];
        constraints= [constraints, 0<=pow_char(i)<=max_pow_cap];
        constraints= [constraints, 0<=pow_discharge(i)<=max_pow_cap];
    end
    options=sdpsettings('solver','gurobi+','gurobi.dualreductions',0,'gurobi.nonconvex',2,'gurobi.infunbdinfo',1) 
    optimize(constraints,objective,options) %solve the problem
    if isnan(double(pow(:,i)'))~=1
        p=double(pow(:,i)); %get power and costpara for period 
        cp_=cost_para';
        field=[];
        values=[];
        for j =1:num_gen %organize power output and cost for period if !=0
	        if p(j)~=0
        	    field(end+1)=p(j);
		        values(end+1)=cp_(j);
	        end
        end
        pi(i)=max(values); %get the LMP for period, max cost of active generators
        ener_lev(i+step)=ener_lev(i)+granular*(pow_char(i)*eff-pow_discharge(i)/eff);
        queue(i+step)=queue(i)+granular*(pow_char(i)*eff-pow_discharge(i)/eff);
    end
end

pow=pow(:,1:step:end);
ener_lev=ener_lev(:,1:step:end); 
pow_char=pow_char(:,1:step:end);
pow_discharge=pow_discharge(:,1:step:end);
pi=pi(:,1:step:end);
total_rev=0;
for i=1:period
    total_rev=total_rev+step*sum(pi(i)*pow(:,i));
end

ener_lev=double(ener_lev);
pow_char=double(pow_char);
pow_discharge=double(pow_discharge);
pow=double(pow);
pi=double(pi); 


demand=demand(1:step:end);

%Figure outputs
figure1=figure('Name','Demand');
plot(0:granularity:(24-granularity),demand);
set(gca,'xtick',0:4:24);
xlabel('Time');
ylabel('Demand (Mwh)');

figure2=figure('Name','Electricity Price');
plot(0:granularity:(24-granularity),price);
set(gca,'xtick',0:4:24);
ylim([0,max_cost_para]);
xlabel('Time');
ylabel('$/Mwh');

figure3=figure('Name','Generator Output')
for i=1:num_gen
    hold on
    plot(0:granularity:(24-granularity),pow(i,:));
end
xlabel('Time')
set(gca,'xtick',0:4:24);
ylabel('Power Output/mwh')
legend (text)

figure4=figure('Name','Energy Level Over Time')
hold on
plot(0:granularity:24, ener_lev, 'b');
plot(0:granularity:(24-granularity), pow_char,'--g');
plot(0:granularity:(24-granularity), pow_discharge,'--r');
title('Energy Level of Storage')
xlabel('Time')
ylabel('Energy Level/MWh')
set(gca,'xtick',0:4:24);
legend('Energy Level','Charged Power','Discharged Power')

