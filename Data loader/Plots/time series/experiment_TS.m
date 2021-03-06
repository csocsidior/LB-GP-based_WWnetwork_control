clear all; clc;

%% Load variables

load('x_GP')
load('u_GP')
load('u_ref_GP')
load('d_GP')
load('d_r_full')
load('x_o_GP','x_o_GP')

load('x_onoff')
load('u_onoff')
load('u_ref_onoff')
%load('d_onoff')
load('x_o_onoff','x_o_onoff')

%% Constraints

% Input constraints                 % UNIT:[l/min]  
u1_on  = 6.5;                       % 6.5                                          
u1_off = 3.5;                       % 3.5  
u2_on  = 14;                        % 14  
u2_off = 5.4;                       % 5.4       
% Tank constraints                  % UNIT:[dm] 
max_t1 = 6.8;                       % 6.9    
min_t1 = 4.2;% + 0.15;             
max_t2 = 6.05;%5.95;     
min_t2 = 4.3; %+ 0.15 ;
% Tank safety region
max_t1_op = 5.6 + 0.15;                    % UNIT:[dm] 
min_t1_op = 4.4; %+ 0.15;
max_t2_op = 5.2;
min_t2_op = 4.5;% + 0.15;

%%
startPlot = 50;
endPlot = 2200;%1600;

max_t1_op_line = max_t1_op*ones(1,length(startPlot:endPlot));
min_t1_op_line = min_t1_op*ones(1,length(startPlot:endPlot));

max_t2_op_line = max_t2_op*ones(1,length(startPlot:endPlot));
min_t2_op_line = min_t2_op*ones(1,length(startPlot:endPlot));

%%
max_t1_line = max_t1*ones(1,length(startPlot:endPlot));
min_t1_line = min_t1*ones(1,length(startPlot:endPlot));
max_t2_line = max_t2*ones(1,length(startPlot:endPlot));
min_t2_line = min_t2*ones(1,length(startPlot:endPlot));
u1_on_line = u1_on*ones(1,length(startPlot:endPlot));
u1_off_line = u1_off*ones(1,length(startPlot:endPlot));
u2_on_line = u2_on*ones(1,length(startPlot:endPlot));
u2_off_line = u2_off*ones(1,length(startPlot:endPlot));

%% Correct sensor fails

d_GP(1,150:300) = filloutliers(d_GP(1,150:300),'nearest','mean');
d_GP(1,900:1150) = filloutliers(d_GP(1,900:1150),'nearest','mean');
d_GP(1,1600:1800) = filloutliers(d_GP(1,1600:1800),'nearest','mean');


d_GP(3,400:600) = filloutliers(d_GP(3,400:600),'nearest','mean');
d_GP(3,800:1000) = filloutliers(d_GP(3,800:1000),'nearest','mean');
d_GP(3,1250:1300) = filloutliers(d_GP(3,1250:1300),'nearest','mean');
d_GP(3,1672:1720) = smooth(d_GP(3,1672:1720));

d_GP(3,1271:1281) = randn(1,11)*0.1 + 8.1;

%%
u_GP(2,1716:1747) = filloutliers(u_GP(2,1716:1747),'previous','mean');
u_GP(2,1815:1865) = filloutliers(u_GP(2,1815:1865),'previous','mean');
u_GP(2,2022:2069) = filloutliers(u_GP(2,2022:2069),'previous','mean');
u_ref_GP(2,1716:1747) = filloutliers(u_ref_GP(2,1716:1747),'previous','mean');
u_ref_GP(2,1815:1865) = filloutliers(u_ref_GP(2,1815:1865),'previous','mean');
u_ref_GP(2,2022:2069) = filloutliers(u_ref_GP(2,2022:2069),'previous','mean');
u_ref_GP(2,2022:2069) = filloutliers(u_ref_GP(2,2022:2069),'previous','mean');

%%
% forecast
d_r(:,1:115) = [];
d_r(:,1:200) = [];

%%
T_limit_up = 100;


figure
ax(1) = subplot(5,2,1);
h1 = gca;
yyaxis right
bar(d_r(1,startPlot+5:endPlot),'FaceColor',[0.9290 0.6940 0.1250])
ylim([0,9])
ylabel('Flow ($\frac{\textrm{dm}^3}{\textrm{min}}$)','interpreter','latex');
set(h1, 'YDir', 'reverse')
yyaxis left
plot(d_GP(1,startPlot:endPlot)','Color',[0.9500 0.1250 0.0980],'LineWidth',0.7)
ylabel('Flow ($\frac{\textrm{dm}^3}{\textrm{min}}$)','interpreter','latex');
title('(a) Inflow ($q_{t1}$) and rain forecast ($d$)','interpreter','latex')
grid on
ylim([3,10])
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('Inflow','Rain forecast');
set(leg,'Interpreter','latex');
h1.YAxis(1).Color = [0.9500 0.1250 0.0980];
h1.YAxis(2).Color = [0.9290 0.6940 0.1250];
set(gca,'xticklabel',[])

ax(2) = subplot(5,2,2);
plot(d_GP(3,startPlot:endPlot)','Color',[0.9500 0.1250 0.0980],'LineWidth',0.7)
ylabel('Flow ($\frac{\textrm{dm}^3}{\textrm{min}}$)','interpreter','latex');
title('(b) Inflow ($q_p$)','interpreter','latex')
grid on
ylim([4,11])
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('Inflow');
set(leg,'Interpreter','latex');
set(gca,'xticklabel',[])

ax(3) = subplot(5,2,3);
ciplot(min_t1_op_line,max_t1_op_line)
hold on
p1 = plot(x_onoff(1,startPlot:endPlot)','black','LineWidth',0.8);
p1.Color(4) = 0.5;
hold on
plot(x_GP(1,startPlot:endPlot)','color',[0 0.5 0],'LineWidth',1)
hold on
plot(startPlot:T_limit_up:endPlot,max_t1_line(1:T_limit_up:end),'red--')
hold on
plot(startPlot:T_limit_up:endPlot,min_t1_line(1:T_limit_up:end),'red--')
ylabel('Level (\textrm{dm})','interpreter','latex');
title('(c) Tank level ($h_{t1}$)','interpreter','latex')
grid on
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('Safety region','On/off','GP-MPC','Physical limits');
set(leg,'Interpreter','latex','NumColumns',4);
set(gca,'xticklabel',[])

ax(4) = subplot(5,2,4);
ciplot(min_t2_op_line,max_t2_op_line)
hold on
p2 = plot(x_onoff(2,startPlot:endPlot)','black','LineWidth',0.8);
p2.Color(4) = 0.5;
hold on
plot(x_GP(2,startPlot:endPlot)','color',[0 0.5 0],'LineWidth',1)
hold on
plot(startPlot:T_limit_up:endPlot,min_t2_line(1:T_limit_up:end),'red--')
hold on
plot(startPlot:T_limit_up:endPlot,max_t2_line(1:T_limit_up:end),'red--')
ylabel('Level (\textrm{dm})','interpreter','latex');
title('(d) Tank level ($h_{t2}$)','interpreter','latex')
grid on
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('Safety region','On/off','GP-MPC','Physical limits');
set(leg,'Interpreter','latex','NumColumns',4);
set(gca,'xticklabel',[])

ax(5) = subplot(5,2,5);
plot(x_o_onoff(1,startPlot:endPlot)','color',[0.9500 0.1250 0.0980],'LineWidth',1)
hold on
plot(x_o_GP(1,startPlot:endPlot)','color',[0 0.5 0],'LineWidth',1)
ylabel('Volume (\textrm{dm}$^3$)','interpreter','latex');
title('(e) Overflow volume ($V_{t1}$)','interpreter','latex')
grid on
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
ylim([0,6])
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('On/off','GP-MPC');
set(leg,'Interpreter','latex');
set(gca,'xticklabel',[])

ax(6) = subplot(5,2,6);
plot(x_o_onoff(2,startPlot:endPlot)','color',[0.9500 0.1250 0.0980],'LineWidth',1)
hold on
plot(x_o_GP(2,startPlot:endPlot)','color',[0 0.5 0],'LineWidth',1)
ylabel('Volume (\textrm{dm}$^3$)','interpreter','latex');
title('(f) Overflow volume ($V_{t1}$)','interpreter','latex')
grid on
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('On/off','GP-MPC');
set(leg,'Interpreter','latex');
set(gca,'xticklabel',[])

ax(7) = subplot(5,2,7);
plot(u_GP(1,startPlot:endPlot)','Color',[0 0.2470 0.7410],'LineWidth',1)
hold on
plot(u_ref_GP(1,startPlot:endPlot)','red','LineWidth',0.8)
hold on
plot(startPlot:T_limit_up:endPlot,u1_on_line(1:T_limit_up:end),'red--')
hold on
plot(startPlot:T_limit_up:endPlot,u1_off_line(1:T_limit_up:end),'red--')
ylabel('Flow ($\frac{\textrm{dm}^3}{\textrm{min}}$)','interpreter','latex');
%xlabel('Time','interpreter','latex');
title('(g) Pump flow: GP-MPC ($Q_{t1}$)','interpreter','latex')
grid on
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('Measurement','Reference','Actuator limits');
set(leg,'Interpreter','latex');
set(gca,'xticklabel',[])

ax(8) = subplot(5,2,8);
plot((u_GP(2,startPlot:endPlot))','Color',[0 0.2470 0.7410],'LineWidth',1)
hold on
plot((u_ref_GP(2,startPlot:endPlot))','red','LineWidth',0.8)
hold on
plot(startPlot:T_limit_up:endPlot,u2_on_line(1:T_limit_up:end),'red--')
hold on
plot(startPlot:T_limit_up:endPlot,u2_off_line(1:T_limit_up:end),'red--')
ylabel('Flow ($\frac{\textrm{dm}^3}{\textrm{min}}$)','interpreter','latex');
%xlabel('Time','interpreter','latex');
title('(h) Pump flow: GP-MPC ($Q_{t1}$)','interpreter','latex')
grid on
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('Measurement','Reference','Actuator limits');
set(leg,'Interpreter','latex');
set(gca,'xticklabel',[])

ax(9) = subplot(5,2,9);
plot((u_onoff(1,startPlot:endPlot))','Color',[0 0.2470 0.7410],'LineWidth',1)
hold on
plot(startPlot:T_limit_up:endPlot,u1_on_line(1:T_limit_up:end),'red--')
hold on
plot(startPlot:T_limit_up:endPlot,u1_off_line(1:T_limit_up:end),'red--')
ylabel('Flow ($\frac{\textrm{dm}^3}{\textrm{min}}$)','interpreter','latex');
xlabel('Time (10s)','interpreter','latex');
title('(i) Pump flow: On/off ($Q_{t1}$)','interpreter','latex')
grid on
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('Measurement','Actuator limits');
set(leg,'Interpreter','latex');

ax(10) = subplot(5,2,10);
plot((u_onoff(2,startPlot:endPlot))','Color',[0 0.2470 0.7410],'LineWidth',1)
hold on
plot(startPlot:T_limit_up:endPlot,u2_on_line(1:T_limit_up:end),'red--')
hold on
plot(startPlot:T_limit_up:endPlot,u2_off_line(1:T_limit_up:end),'red--')
ylabel('Flow ($\frac{\textrm{dm}^3}{\textrm{min}}$)','interpreter','latex');
xlabel('Time (10s)','interpreter','latex');
title('(j) Pump flow: On/off ($Q_{t2}$)','interpreter','latex')
grid on
xlim([startPlot, length(d_GP(:,startPlot:endPlot))]);
xticks(103:115:length(d_GP(:,startPlot:endPlot)))
leg = legend('Measurement','Actuator limits');
set(leg,'Interpreter','latex');

linkaxes(ax,'x');
