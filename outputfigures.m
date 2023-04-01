function [figure1,figure2,figure3,figure4]=outputfigures(demand,granularity,ener_lev,pow_char,pow_discharge,pow,max_stor,price,cost_para,text)
num_gen=numel(cost_para);
ener_lev=double(ener_lev);
pow_char=double(pow_char);
pow_discharge=double(pow_discharge);
pow=double(pow);
max_stor=double(max_stor);
price=double(price); 

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

demand=demand(1:step:end);

%Figure outputs
figure1=figure('Name','Demand');
plot(0:granularity:(24-granularity),demand);
set(gca,'xtick',0:4:24);
xlabel('Time');
ylabel('Demand (Mwh)');

max_cost_para=max(cost_para);
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
end