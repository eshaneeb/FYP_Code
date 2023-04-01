clearAllMemoizedCaches;
filename='onlinetesting.xlsx'; %insert your file name
Data = readtable(filename);

%parameters to be taken
cost_para=rmmissing(Data.CostParameter)';
demand =rmmissing(Data.Demand)';
max_pow =rmmissing(Data.MaximumPower);
min_pow =rmmissing(Data.MinimumPower);
max_stor=rmmissing(Data.MaximumStorageCapacity);
max_pow_cap=rmmissing(Data.StoragePowerCapacity);
eff=rmmissing(Data.Efficiency);

granularity=double(1/12);

if granularity==double(1/12)
    period=1440./5;
    step=1;
elseif granularity==double(1/4)
    period=1440./15;
    step=3;
elseif granularity==double(1/2)
    period=1440./30;
    step=6;
elseif granularity==double(1)
    period=1440./60;
    step=12;
end

demand=demand(:,1:step:end);
num_trans=numel(demand);
num_gen=numel(cost_para);

%variables 
pow=sdpvar(num_gen,num_trans);
ener_lev=sdpvar(1,num_trans+1); %because we'll have e(t+1) term
pow_char=sdpvar(1,num_trans);
pow_discharge=sdpvar(1,num_trans);

%objective 
objective=0;
for i = 1:num_trans
    objective=objective+cost_para*pow(:,i);
end

%constraints
constraints=[ener_lev(1)==0, ener_lev(end)==0];
for i = 1:num_trans
    constraints= [constraints, (sum(pow(:,i))-pow_char(i)+pow_discharge(i)==demand(i)):'shadow'];
    constraints= [constraints, ener_lev(i+1)==ener_lev(i)+pow_char(i)*eff-pow_discharge(i)/eff];
    constraints= [constraints, min_pow<=pow(:,i)<=max_pow];
    constraints= [constraints, 0<=ener_lev(i)<=max_stor];
    constraints= [constraints, 0<=pow_char(i)<=max_pow_cap];
    constraints= [constraints, 0<=pow_discharge(i)<=max_pow_cap]; 
end

%optimize 
options=sdpsettings('solver','gurobi+')
optimize(constraints,objective,options)

%finding the LMP from dual variable
prices=rand(1,num_trans);
constraints=constraints('shadow'); %retrieve tagged constraint
total_rev=0;
for i=1:num_trans
    prices(i)=-dual(constraints(i));
    total_rev=total_rev+prices(i)*pow(:,i);
end

%finding the LMP from dual variable
prices=rand(1,num_trans);
total_rev=sum(total_rev);
pow=pow(:,1:step:num_trans);
ener_lev=ener_lev(:,1:step:num_trans+1); %because we'll have e(t+1) term
pow_char=pow_char(:,1:step:num_trans);
pow_discharge=pow_discharge(:,1:step:num_trans);

%figures for price, demand supply curve, energy level over time
figure('Name','Price of Electricity')
hold on
plot(1:num_trans, prices);
title('Price of Electricity')
xlabel('Period')
ylabel('Price/mwh')

ener_lev=double(ener_lev);
pow_char=double(pow_char);
pow_discharge=double(pow_discharge);
pow=double(pow);
max_stor=double(max_stor);

figure('Name','Energy Level Over Time')
hold on
plot(1:num_trans+1, ener_lev, 'b');
plot(1:num_trans, pow_char,'--g');
plot(1:num_trans, pow_discharge,'--r');
title('Energy Level of Storage')
xlabel('Period')
ylabel('Energy Level/MWh')
legend('Energy Level','Charged Power','Discharged Power')

figure('Name','Generator Output')
text=rand(1,num_gen);
for i=1:num_gen
    hold on
    text=['Output of Generator', num2str(i)];
    plot(1:num_trans,pow(i,:),'DisplayName',text);
end
xlabel('Period')
ylabel('Power Output/mwh')
legend show

figure('Name','Demand Plot')
plot(1:num_trans, demand)
xlabel('Period')
ylabel('Consumption/mwh')

figure('Name','Demand Curve')
demand=sort(demand);
plot(demand,prices);
xlabel('Energy/mwh')
ylabel('Price per unit')

figure('Name','Supply Curve')
max_pow=max_pow';
supply=dictionary(max_pow,cost_para);
clear keys;
clear values; 
[sortedcost, sorted_pow]=sort(values(supply));
sorted_pow=sorted_pow';
ener=rand(1,num_gen);
for i=1:num_gen
    ener(i)=max_pow(sorted_pow(i));
end
tot_pow=rand(1,num_gen);
for i=1:num_gen
    tot_pow(i)=sum(ener(1:i));
end
hold on
plot(tot_pow,sortedcost)
xlabel('Capacity/mwh')
ylabel('Price per unit')
