%% MPC_builder_GP.m

addpath('C:\Users\Krisztian\Documents\GitHub\LB-GP-based_WWnetwork_control\CasAdi') 
import casadi.*
opti = casadi.Opti();                                       

% Nominal dynamics
% Tank dynamics
At = [eye(Nxt), zeros(Nxp,Nxp)]; 
Bt = -diag([dt_MPC/P_sim(4), dt_MPC/P_sim(4)]); 
%Et = diag([dt_MPC/P_sim(5), dt_MPC/P_sim(5)]);
Et = zeros(Nxt,ND);

% Pipe dynamics
a33 = 0;    a43 = 0;    a44 = 0;                            % not used: single flow to level mapping
Ap = [a33, 0, 0, 0; 
      a43, a44, 0, 0];
Bp = [b31, 0; b41, 0];
Ep = zeros(Nxt,ND);

A = [At; Ap];
B = [Bt; Bp];
E = [Et; Ep];

Bd = eye(Nx);

%% ============================================ Constraint bounds =============================
U_ub = [u1_on ; u2_on];                                     % Input bounds
U_lb = [u1_off ; u2_off];

Xt_ub = [max_t1 ; max_t2];                                  % Tank state bounds
Xt_lb = [min_t1 ; min_t2];

Xt_ub_op = [max_t1_op; max_t2_op];                          % Tank operating region
Xt_lb_op = [min_t1_op; min_t2_op];

Xp_ub = h_p_max*ones(Nxp,1);                                % pipe state bounds
Xp_lb = h_p_min*ones(Nxp,1);

H_x = [eye(Nx); -eye(Nx)];                                  % state polytope
b_x = [Xt_ub; Xp_ub; -Xt_lb; -Xp_lb];

H_u = [eye(Nu); -eye(Nu)];                                  % input polytope
b_u = [U_ub; -U_lb];

H_XI = blkdiag(eye(Nxt),eye(Nxt));                         % polytope with bound slack 
H_EPS = blkdiag(eye(Nx),eye(Nx));                         % polytope with bound slack 

H_s = [eye(Nxt); -eye(Nxt)]; 
b_s = [Xt_ub_op; -Xt_lb_op];
%% ============================================ Opti variables ===============================
dU    = opti.variable(Nxt,Hp);                                                                   
XI  = opti.variable(2*Nxt,Hp);                              % safety slack
EPS  = opti.variable(2*Nx,Hp);                             % overflow slack

%% ============================================ Opti parameters ==============================
D = opti.parameter(ND,Hp);                                  % disturbance trajectory [d1,d2,d3]

mu_X0 = opti.parameter(Nx,1);                               % initial mu_x  
u0 = opti.parameter(Nxt,1);                                 % previous input
sigma_X0 = opti.parameter(Nx,Nx);                           % initial sigma

Z_train  = opti.parameter(Nz,M);                            % Z state-input training input
Y_train  = opti.parameter(Nx,M);                            % Y residual training output
GP_sigma_F  = opti.parameter(Nx,1);                         % GP - sigma_f hyper parameter

inv_K_xx = opti.parameter(M,M*Nx);                          % Covariance matrices for each 'a' output dimension

T = opti.parameter(1,Hp);                               % time as the last dimension

%% ============================================ Casadi MX variables ===============================
mu_X = opti.variable(Nx,Hp+1);
opti.subject_to(mu_X(:,1) == mu_X0);   
sigma_X = opti.variable(Nx, (Hp+1)*Nx);
opti.subject_to(sigma_X(:,1:1*Nx) == sigma_X0);

%% ============================================== GP setup ====================================
% Build GP prior: K_xx - Gram matrix of data points 
%                    z - testing point                         
K_xz = casadi.MX(M,Nx);                           
K_zz = casadi.MX(1,Nx);
U = cumsum(dU,2) + u0;                                        % integral action 
for k = 1:Hp
    Z = [mu_X(:,k); U(:,k); D(:,k); T(:,k)];
    % Build K_xz and K_zz matrices
    for a = 1:Nx
        temp_K_xz = casadi.MX(M,1);
        Z_C = GP.C{a}*(Z - Z_train);                          % pick testing, training dimensions
        for i = 1:M
            temp_K_xz(i) =(GP_sigma_F(a)^2)*exp(-0.5*Z_C(:,i)' * (GP.inv_sigma_L{a}.^2) * Z_C(:,i));
        end
        K_xz(:,a) = temp_K_xz;
        K_zz(:,a) = GP_sigma_F(a)^2;
    end
    % Build mu_d and sigma_d (GP)
    mu_d = casadi.MX(Nx,1);
    sigma_d = casadi.MX(Nx,1);
    for i = 1:Nx
        mu_d(i) = K_xz(:,i)' * inv_K_xx(:,(i-1)*M+1:i*M) * Y_train(i,:)';
        sigma_d(i) = K_zz(:,i) - K_xz(:,i)' * inv_K_xx(:,(i-1)*M+1:i*M) * K_xz(:,i);
    end
    % Mean gradient 
    grad_mu = casadi.MX(Nz,Nx);
    alpha = opti.parameter(M,Nx);
    for a = 1:Nx
        alpha(:,a) = inv_K_xx(:,(a-1)*M+1:a*M) * Y_train(a,:)';  
        grad_mu(:,a) = (-(GP.C{a}' * (GP.inv_sigma_L{a}.^2)*GP.C{a}) * (Z - Z_train)*(K_xz(:,a).*alpha(:,a)))';
    end
    grad_mu = grad_mu(1:Nx,1:Nx);
    % Mean and covariance dynamics - uncertainty propagation
    %mu_X(:,k+1) = A*mu_X(:,k) + B*U(:,k) + E*D(:,k) + Bd*mu_d + [0;0;c3;c4];
    %sigma_X(:,((k-1)*Nx+1)+Nx:(k*Nx)+Nx) = Bd*diag(sigma_d + GP.sigma'.^2)*Bd' + (A + Bd*grad_mu)*sigma_X(:,((k-1)*Nx+1):(k*Nx))*(A + Bd*grad_mu)';
                            
    opti.subject_to(mu_X(:,k+1) == A*mu_X(:,k) + B*U(:,k) + E*D(:,k) + Bd*mu_d + [0;0;c3;c4]);  
    opti.subject_to(sigma_X(:,((k-1)*Nx+1)+Nx:(k*Nx)+Nx) == Bd*diag(sigma_d  + GP.sigma'.^2)*Bd' + (A + Bd*grad_mu)*sigma_X(:,((k-1)*Nx+1):(k*Nx))*(A + Bd*grad_mu)');  
progressbar(k/Hp) 
end

%% =========================================== Objective function ==============================
hV = Kt/dt_MPC;
W_x = 10;
W_u = [8,0; 0,4];
%W_s = [20,0,0,0; 0,50,0,0; 0,0,4,0; 0,0,0,10];  
W_s = [20,0,0,0; 0,40,0,0; 0,0,20,0; 0,0,0,40];  
W_o = 1000;%100;

objective_sigma = 0;
for i = 1:Hp
    objective_sigma = objective_sigma + trace(sigma_X(1:Nx,((i-1)*Nx+1):(i*Nx))); %trace(sigma_X(1:Nxt,((i-1)*Nx+1):(i*Nx)-Nxp));
end

objective_all = W_x*hV*(0.0005*sumsqr(mu_X(1:Nxt,2:end)) + 0.0000001*objective_sigma) + sumsqr(W_u*dU) + hV*sumsqr(W_s*XI) + W_o*hV*sumsqr(EPS);    
opti.minimize(objective_all); 
%W_x*hV*(0.0005*sumsqr(mu_X(:,2:end)) + objective_sigma)

%% ============================================== Constraints ==================================
for k = 2:Hp
    % physical bounds
    opti.subject_to(H_x*mu_X(:,k) <= (b_x) + H_EPS*EPS(:,k));  
    opti.subject_to(EPS(:,k) >= 0);
    % - norminv(0.8)*H_x*sqrt(diag(sigma_X(:,((k-1)*Nx+1):(k*Nx))))
    
    % safety bounds
    opti.subject_to(H_s*mu_X(1:Nxt,k) <= (b_s) + H_XI*XI(:,k));
    opti.subject_to(XI(:,k) >= 0);
end

%%
for k = 1:Hp
    opti.subject_to(H_u*U(:,k) <= b_u);                                               
end

%% Optimization setup 
opts = struct;
opts.ipopt.print_level = 0;                                                    % print enabler to command line
opts.print_time = false;                                                       % instead of using ipopt, use Casadi's KKT condition to calc. lam_x
opts.expand = true;                                                            % makes function evaluations faster
opts.calc_lam_x = true;   
opts.ipopt.max_iter = 100;                                                     % max solver iteration
opti.solver('ipopt',opts); 

%% Setup OCP
tic
OCP = opti.to_function('OCP',{mu_X0, D, sigma_X0, Z_train, Y_train, GP_sigma_F, opti.lam_g, opti.x, inv_K_xx, u0, T},...
    {U, mu_X(:,1:Hp), sigma_X(:,1:Nx*Hp), opti.lam_g, opti.x, mu_d(:,1), XI, EPS, dU},...
    {'mu_x0','d','sigma_x0','z_train','y_train','GP_sigma_f','lam_g','init_x','inv_K_xx','u0','t'},...
    {'u_opt','mu_x_opt','sigma_x_opt','lam_g','init_x','mu_d','xi','eps','du'});
toc
