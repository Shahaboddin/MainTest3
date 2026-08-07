bhvfile = '260806_Sky3_MainTest3_userloop.bhv2';
data = mlread(bhvfile);

% Pick a few trials to inspect
trials_to_plot = [1 20 37 55];

figure;
for k = 1:numel(trials_to_plot)
    i = trials_to_plot(k);
    G = data(i).AnalogData.General;

    subplot(numel(trials_to_plot),1,k);
    if isfield(G,'Gen1') && ~isempty(G.Gen1)
        plot(G.Gen1, 'b'); hold on;
    end
    if isfield(G,'Gen2') && ~isempty(G.Gen2)
        plot(G.Gen2, 'r');
    end
    title(sprintf('Trial %d: General Input (Gen1=blue, Gen2=red)', i));
    xlabel('Sample');
    ylabel('Value');
    legend('Gen1','Gen2');
end