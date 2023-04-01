function [total_rev,pow,pow_char,pow_discharge,ener_lev,prices]=offline(granularity,demand,cost_para,max_pow,min_pow,max_stor,max_pow_cap,eff)
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
demand=demand';
demand=demand(:,1:step:end);
num_trans=numel(demand);
num_gen=numel(cost_para);

%variables 
pow=sdpvar(num_gen,num_trans);
ener_lev=sdpvar(1,num_trans+1); %because we'll have e(t+1) term
pow_char=sdpvar(1,num_trans);
pow_discharge=sdpvar(1,num_trans);
%s=double(cost_para*pow(:,1));
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
prices=zeros(1,num_trans);
constraints=constraints('shadow'); %retrieve tagged constraint
total_rev=0;
for i=1:num_trans
    prices(i)=-dual(constraints(i));
    total_rev=total_rev+prices(i)*pow(:,i);
end
total_rev=sum(total_rev);
pow=double(pow);
ener_lev=double(ener_lev); %because we'll have e(t+1) term
pow_char=double(pow_char);
pow_discharge=double(pow_discharge);
end