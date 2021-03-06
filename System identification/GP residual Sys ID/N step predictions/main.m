clear residual_N
clear x_hat
clear x0
clear pred_N_save
clear conf_N_save
clear residual_ci_N_full
clear residual_ci_N

%% Np long prediction

num_x = [0,1,1,2];                                                              % number of state regressor in residuals
N_pred = 20;
k = 1;
bias = [0;0;c3;c4];

start_n = 1;%7900;
stop_n = 1000;%8600;
   
for n = start_n:stop_n

    x0 = z(1:Nx,n);
    x_hat = zeros(Nx,N_pred);
    x_hat(:,1) = x0;
    residual_ci_N = zeros(1,2);

    for i = 1:N_pred
        %pred_N = zeros(Nx,1);

        for j = 1:Nx
           %[pred_N,~,ress_ci_np] = predict(gps{j}, [C{j}(1:num_x(j),1:Nx)*x_hat(:,i); C{j}(num_x(j)+1:end,:)*z(:,n+i-1)]');
           [residual_N,residual_ci_N] = GP_predict(i,j,n,gps,C,x_hat,z,num_x,Nx);
           %x_hat(j,i+1)= residual_N;
           x_hat(j,i+1)= A(j,j)*x_hat(j,i) + B(j,:)*u(:,n+i-1) + residual_N + bias(j);
           residual_ci_N_full{j}(i,:) = residual_ci_N + x_hat(j,i+1);
        end
        
        if sum(isnan(residual_N)) > 0
            return
        end

        %x_hat(:,i+1)= pred_N ;
    end

%     figure
%     subplot(2,1,1)
%     plot(r)
%     subplot(2,1,2)
%     plot(z(j,n:n+N_pred))
%     hold on
%     plot(x_hat(j,:))

    pred_N_save(:,k) = x_hat(:,end);
    for l = 1:Nx
    conf_N_save{l}(k,:) = residual_ci_N_full{l}(end,:);
    end
    k = k + 1;
    k

end
%% Plot N-step prediction for all states
figure
for select = 1:Nx
subplot(2,2,select)
plot(z(select,start_n + N_pred : stop_n + N_pred))
hold on
plot((pred_N_save(select,:)))
%hold on
%ciplot(conf_N_save{select}(:,1) ,conf_N_save{select}(:,2)) 
title('N-step prediction - validation data','interpreter','latex')
leg = legend('Experiment','Model');
set(leg,'Interpreter','latex');
grid on
ylabel('Level [$dm$]','interpreter','latex')
xlabel('Time [10 s]','interpreter','latex')
end



