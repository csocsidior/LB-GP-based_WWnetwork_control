function [inv_K_xx_val,K_xx]= K_xx_builder(Z_train_subset,GP,Nx,M)

%% Build K_xx prior
K_xx = cell(Nx,1);
for a = 1:Nx
    K_xx{a} = (GP.sigma_f(a)^2) * exp(-0.5*(squareform(pdist(((GP.inv_sigma_L{a}.^2)*GP.C{a}*Z_train_subset)','squaredeuclidean'))));
end

%% Pre-calculate inv(K_xx + sigma^2) 

for a = 1:Nx
    inv_K_xx_temp{a} = ((K_xx{a} + eye(M)*GP.sigma(a)^2)\eye(M));
end

% make matrix instead of cell array
    inv_K_xx_val = [inv_K_xx_temp{1}, inv_K_xx_temp{2}, inv_K_xx_temp{3}, inv_K_xx_temp{4}];
end

