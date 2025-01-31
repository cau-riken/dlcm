
function performanceCheckRoiSignal
    subjects = { ...
        'data/marmoset-aneth-sample1-roi52.mat', ...
        'data/marmoset-aneth-sample2-roi52.mat',...;
        'data/marmoset-aneth-sample3-roi52.mat'};

    % training params
    prefix = 'ms-l01-roi52';
    l2 = 0.1;
    weightFunc = @estimateInitWeightRoughHe;
    weightParam = [10];
    bias = 0.5;
    winLen = 200;

    for i=1:length(subjects)
        % load signals
        load(subjects{i});
        siOrg = bold2dnnSignal(si, 0.2);
        load('test/testTrain-rand500-uniform.mat');
        uuOrg = si;

        nodeNum = size(siOrg,1);
        exNum = 10;
        sigLen = 350;

        si = siOrg(:,1:sigLen);
        exSignal = uuOrg(nodeNum+1:nodeNum+exNum,1:sigLen);
        % control is all positive input
        exControl = logical(ones(nodeNum,exNum));

        % training and simulation
        checkingPattern(si, exSignal, exControl, winLen, i, prefix, l2, weightFunc, weightParam, bias);
    end
end

function checkingPattern(si, exSignal, exControl, winLen, idx, prefix, l2, weightFunc, weightParam, bias)
    % traial number
    maxTrain = 6;
    maxWin = 10;
    % init
    nodeNum = size(si,1);
    exNum = size(exSignal,1);
    sigLen = size(si,2);
    allErr = []; allrS = []; allrSi = []; allTime = []; % all trained result
    eachMae = []; eachR = []; eachFCcos = []; eachGCcos = []; % each trained result
    ph = []; ch = [];

    for k = 1:maxTrain
        % do training or load VARDNN network
        netFile = ['results/' prefix '-' num2str(idx) '_' num2str(k) '.mat'];
        if exist(netFile, 'file')
            load(netFile);
        else
            % init VARDNN network
            netDLCM = initMvarDnnNetwork(si, exSignal, [], exControl, 1, @reluLayer, weightFunc, weightParam, bias);

            % set training options
            maxEpochs = 1000;
            sigLen = size(si,2);
            miniBatchSize = ceil(sigLen / 3);

            options = trainingOptions('adam', ...
                'ExecutionEnvironment','cpu', ...
                'MaxEpochs',maxEpochs, ...
                'MiniBatchSize',miniBatchSize, ...
                'Shuffle','every-epoch', ...
                'GradientThreshold',5,...
                'L2Regularization',l2, ...
                'Verbose',false);
        %            'Plots','training-progress');

            % training VARDNN network
            netDLCM = trainMvarDnnNetwork(si, exSignal, [], exControl, netDLCM, options);
            % recover training 
            [netDLCM, time] = recoveryTrainMvarDnnNetwork(si, exSignal, [], exControl, netDLCM, options);
            [time, loss, rsme] = getMvarDnnTrainingResult(netDLCM);
            disp(['train result time=' num2str(time) ', loss=' num2str(loss) ', rsme=' num2str(rsme)]);
            %plotMvarDnnWeight(netDLCM);
            save(netFile, 'netDLCM');
        end

        % simulate VARDNN network with 1st frame & exogenous input signal
        netFile = ['results/' prefix '-' num2str(idx) '_' num2str(k) 'sim.mat'];
        if exist(netFile, 'file')
            load(netFile);
        else
            allS = cell(maxWin,1);
            simTime = zeros(maxWin,1);
        end
        winSi=[]; winS=[]; winFCcos=[]; winGCcos=[];
        for i=1:maxWin
            st = floor(1 + (i-1)*(size(si,2)-winLen)/maxWin);
            en = st + winLen - 1;
            wSi = si(:,st:en);
            sExSignal = exSignal(:,st:en);
            % do simulation
            if isempty(allS{i})
                [S, time] = simulateMvarDnnNetwork(wSi, sExSignal, [], exControl, netDLCM);
                allS{i,1} = S; simTime(i) = time;
            else
                S = allS{i,1}; time = simTime(i);
            end

            % keep for correlation
            winSi = [winSi; wSi]; winS = [winS; S];
            allrSi = [allrSi; wSi]; allrS = [allrS; S];
            % error of each window in one training
            [mae, maeerr, errs] = getTwoSignalsError(wSi, S);
            allErr = [allErr; errs];
            allTime = [allTime; time];
            % cosine similarity between FC and simulated FC
            FC = calcFunctionalConnectivity(wSi);
            sFC = calcFunctionalConnectivity(S);
            cs = getCosSimilarity(FC,sFC);
            winFCcos = [winFCcos; cs];
            % cosine similarity between GC and simulated GC
            gcI  = calcPairwiseGCI(wSi, sExSignal, [], exControl, 3);
            sgcI = calcPairwiseGCI(S, sExSignal, [], exControl, 3);
            nidx = find(isnan(gcI)); gcI(nidx) = 0; % remove NaN
            nidx = find(isnan(sgcI)); sgcI(nidx) = 0; % remove NaN
            cs = getCosSimilarity(gcI,sgcI);
            winGCcos = [winGCcos; cs];
            disp(['simulation time=' num2str(time) ', mae=' num2str(mae)]);
        end
        save(netFile, 'allS', 'simTime');
        % show error line graph
        Y = mean(abs(errs),1);
        if isempty(ph)
            ph = figure;
        else
            figure(ph);
        end
        hold on;
        plot(Y, 'Color', [0.7,0.7,0.7]);
        ylim([0 0.5]);
        hold off;

        % show correlation line graph
        Y = zeros(1,winLen);
        for i=1:winLen
            Y(i) = corr2(winSi(:,i),winS(:,i));
        end
        if isempty(ch)
            ch = figure;
        else
            figure(ch);
        end
        hold on;
        plot(Y, 'Color', [0.7,0.7,0.7]);
        ylim([0 1]);
        hold off;

        % show correlation graph of each training
        figure;
        R = plotTwoSignalsCorrelation(winSi, winS) % show R result
        eachR = [eachR; R];
        % error of each training
        [mae, maeerr, errs] = getTwoSignalsError(winSi, winS);
        eachMae = [eachMae; mae];
        % cos similarity of FC of each training
        eachFCcos = [eachFCcos; mean(winFCcos)];
        % cos similarity of GC of each training
        eachGCcos = [eachGCcos; mean(winGCcos)];
    end
    % show mean all error line graph
    Y = mean(abs(allErr),1);
    figure(ph);
    hold on;
    plot(Y, 'Color', [0.2,0.2,1], 'LineWidth', 1);
    hold off;
    
    % show all correlation line graph
    Y = zeros(1,winLen);
    for i=1:winLen
        Y(i) = corr2(allrSi(:,i),allrS(:,i));
    end
    figure(ch);
    hold on;
    plot(Y, 'Color', [0.2,0.2,1], 'LineWidth', 1);
    hold off;
    drawnow;

    netFile = ['results/' prefix '-' num2str(idx) '_' num2str(k) 'result.mat'];
    save(netFile, 'allErr', 'allrSi', 'allrS', 'allTime', 'eachMae', 'eachR', 'eachFCcos', 'eachGCcos');
end

