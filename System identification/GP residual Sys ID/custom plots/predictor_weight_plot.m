% Find the predictor weights by taking the exponential of the negative learned length scales. Normalize the weights.

for i = 1:Nx 
    weights{i} = exp(-gps{i}.KernelInformation.KernelParameters(1:end-1));      % Predictor weights
    weights{i} = weights{i}/sum(weights{i});                                    % normalized predictor weights
end

figure
for i = 1:Nx
    subplot(2,2,i)
    %plot(weights{i},'ro','LineWidth',2)
    bar(weights{i},'FaceColor',[0,0.5,0])
    ylim([0,1])
    ylabel('Relevance')
    xlabel('Num. of regressor')
    grid on
    title(['Predictor relevance for y',num2str(i)],'interpreter','latex')
end

%%

for i = 1:Nx 
    weights{i} = exp(-gps{i}.KernelInformation.KernelParameters(1:end-1));      % Predictor weights
    weights{i} = weights{i}/sum(weights{i});                                    % normalized predictor weights
end

%% Find the predictor weights by taking the exponential of the negative learned length scales. Normalize the weights.

figure

i = 1;
ax(i) = subplot(2,2,1);
ax(i).TickLabelInterpreter='latex';
b(i) = bar(weights{i},'FaceColor',[0,0.5,0]);
ylim([0,1])
ylabel('Predictor weight')
xlabel('Predictor index')
grid on
title(['Predictor relevance for y',num2str(i)],'interpreter','latex')
ax(i).XTickLabel={'Q_{t1}', 't'};
xtips = b(i).XEndPoints;
ytips = b(i).YEndPoints;
labels = string(b(i).YData);
text(xtips,ytips,labels,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom')
