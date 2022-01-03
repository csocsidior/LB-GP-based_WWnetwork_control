function [output]  = simulink_GP_MPC(X0,time)

% define persistent variables
eml.extrinsic('evalin');
persistent x_init;           persistent lam_g;               persistent period
persistent OCP;              persistent D_sim_rain;          persistent sigma_X0_init; 
persistent GP;               persistent inv_K_xx_val;        persistent u_prev;
persistent Hp;               persistent Z_train_subset;      persistent Y_train_subset;
persistent M;                persistent Nx 

if isempty(lam_g)                % get persistent values from workspace
    lam_g = evalin('base','lam_g');
    x_init = evalin('base','x_init');
    OCP = evalin('base','OCP'); 
    D_sim_rain = evalin('base','D_sim_rain');
    sigma_X0_init = evalin('base','sigma_X0_init');
    GP = evalin('base','GP');
    inv_K_xx_val = evalin('base','inv_K_xx_val');
    Hp = evalin('base','Hp');
    Z_train_subset = evalin('base','z_train_subset');
    Y_train_subset = evalin('base','y_train_subset');
    M = evalin('base','M');
    u_prev = [0;0];
    Nx = evalin('base','Nx');
    period = evalin('base','period');
end

dT = 1/6;                        % Sample time in minutes             
simulink_frequency = 2;          % Sampling frequency in seconds
time = int64(round(time));       % average time
disturbance = zeros(3,Hp);       % preallocation

% Disturbance forecast
for i=0:1:Hp-1
    start_index = time+1 + i*dT*60*simulink_frequency;
    end_index = start_index + dT*60*simulink_frequency-1;
    disturbance(:,i+1) = mean(D_sim_rain(:,start_index:end_index),2);
end

% Time GP
time_GP = mod(time-13,period)./period;

% State measure 
X0 = X0/100;

tic
% openloop GP-MPC
%     [U_opt_Hp,mu_X_opt,sigma_X_opt,lam_g,x_init] = ...
%      OCP(X0,disturbance,sigma_X0,Z_train_subset,Y_train_subset,GP.sigma_f,GP.sigma_L,lam_g,x_init,reference,inv_K_xx_val,u_prev);
 
[U_opt_Hp, mu_X_opt_Hp, sigma_X_opt_Hp, lam_g, x_init, mu_p_opt, XI_opt_Hp, EPS_opt_Hp, dU_opt_Hp] = ...
    OCP(X0, disturbance, sigma_X0_init, Z_train_subset, Y_train_subset, GP.sigma_f, lam_g, x_init, inv_K_xx_val, u_prev, time_GP)
toc

% Solution
u_sol = full(U_opt_Hp(:,1));
u_prev = u_sol;
Z_pred = [full(mu_X_opt_Hp); full(U_opt_Hp); disturbance];
eps_sol = full(EPS_opt_Hp(:,1));

% Subset of Data (SoD) point selection 
[Z_train_subset, Y_train_subset] = reduce_M(Z_pred,GP.z_train,GP.y_train,Hp,M);

% Pre-calculate K_xx and inv_K_xx
inv_K_xx_val = K_xx_builder(Z_train_subset,GP,Nx,M);

output = [u_sol];

end
