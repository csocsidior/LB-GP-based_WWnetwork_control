% function [inv_K_xx_val,K_xx]= K_xx_builder(Z_train_subset,GP,Nx,M)
% 
% %% Build K_xx prior
% K_xx = cell(Nx,1);
% for a = 1:Nx
%     K_xx{a} = (GP.sigma_f(a)^2) * exp(-0.5*(squareform(pdist(((GP.inv_sigma_L{a}.^2)*GP.C{a}*Z_train_subset)','squaredeuclidean'))));
% end
% 
% %% Pre-calculate inv(K_xx + sigma^2) 
% 
% for a = 1:Nx
%     inv_K_xx_temp{a} = ((K_xx{a} + eye(M)*GP.sigma(a)^2)\eye(M));
% end
% 
% % make matrix instead of cell array
%     inv_K_xx_val = [inv_K_xx_temp{1}, inv_K_xx_temp{2}, inv_K_xx_temp{3}, inv_K_xx_temp{4}];
% end

%%%%%%%%%%%%

function [inv_K_xx_val,K_xx]= K_xx_builder(Z_train_subset,GP,Nx,M)

%% Build K_xx prior
K_xx = cell(Nx,1);

for a = 1:Nx
        kernel_Z_train_subset = zeros(M,M);
        Z_train_subset_temp = GP.C{a}*Z_train_subset;
    for ii = 1:size(GP.C{a}*Z_train_subset,2)
        for jj = 1:size(GP.C{a}*Z_train_subset,2)
            kernel_Z_train_subset(ii,jj) = (GP.sigma_f(a)^2)*exp(-0.5*(Z_train_subset_temp(:,ii) - Z_train_subset_temp(:,jj))'*(GP.inv_sigma_L{a}.^2)*(Z_train_subset_temp(:,ii) - Z_train_subset_temp(:,jj)));
        end
    end
    K_xx{a} = kernel_Z_train_subset;
end

%% Pre-calculate inv(K_xx + sigma^2) 
for a = 1:Nx
    inv_K_xx_temp{a} = ((K_xx{a} + eye(M)*GP.sigma(a)^2)\eye(M));
end

% make matrix instead of cell array
inv_K_xx_val = [inv_K_xx_temp{1}, inv_K_xx_temp{2}, inv_K_xx_temp{3}, inv_K_xx_temp{4}];


end