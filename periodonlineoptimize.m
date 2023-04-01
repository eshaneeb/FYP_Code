%inputs=[demand,cost_para,max_pow,min_pow,max_stor,max_pow_cap,num_gen,eff,tau,period]
%outputs=[total_rev,pow,pow_char,pow_discharge,ener_lev,pi]

function [total_rev,pow,pow_char,pow_discharge,ener_lev,pi,v,granularity]=periodonlineoptimize(time_input,demand,cost_para,max_pow,min_pow,max_stor,max_pow_cap,eff,initial_ener,v)
num_gen=numel(cost_para);

if time_input==double(5)
    granularity=double(1/12);
    period=1440./5;
    step=1;
elseif time_input==double(15)
    granularity=double(1/4);
    period=1440./15;
    step=3;
elseif time_input==double(30)
    granularity=double(1/2);
    period=1440./30;
    step=6;
elseif time_input==double(60)
    granularity=double(1);
    period=1440./60;
    step=12;
else
    error('Please enter a granularity of 5, 15, 30 or 60 minutes for data with 5 minute resolution.')
end

k=numel(demand)-1;

%variables
pow=sdpvar(num_gen,k);
ener_lev=sdpvar(1,k+1); 
pow_char=sdpvar(1,k);
pow_discharge=sdpvar(1,k);

%non-decision variables
queue=zeros(1,k+1);
pi=zeros(1,k); %prices

if ~exist('v','var')
    v=(max_stor-2*granularity*max_pow_cap)/(max(cost_para));
end

ener_lev(1)=initial_ener; %initialization of Eo,Qo, V;
queue(1)=ener_lev(1)-(granularity*max_pow_cap+v* max(cost_para));
for i=1:step:k %solve optimization for all periods, update of period (t=t+1); step 
    %for period i observe Qt, Et, and demand(i)
    %objective for period i
    objective=0;
    objective=objective+v*granularity*cost_para*pow(:,i)+granularity*queue(i)*(pow_char(i)*eff-pow_discharge(i)/eff)%need to change
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
        ener_lev(i+step)=ener_lev(i)+granularity*(pow_char(i)*eff-pow_discharge(i)/eff);
        queue(i+step)=queue(i)+granularity*(pow_char(i)*eff-pow_discharge(i)/eff);
    end
end

pow=pow(:,1:step:end);
ener_lev=ener_lev(:,1:step:end); 
pow_char=pow_char(:,1:step:end);
pow_discharge=pow_discharge(:,1:step:end);
pi=pi(:,1:step:end);
total_rev=0;
for i=1:numel(pi)
    total_rev=total_rev+step*sum(pi(i)*pow(:,i));
end

ener_lev=double(ener_lev);
pow_char=double(pow_char);
pow_discharge=double(pow_discharge);
pow=double(pow);
pi=double(pi); 
end