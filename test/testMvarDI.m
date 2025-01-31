
function testMvarDI
    % load signals
    load('test/testTrain-rand500-uniform.mat');
    siOrg = si;
    lags = 1;
    nodeNum = 8;
    exNum = 0;
    sigLen = 200;
    si = siOrg(1:nodeNum,1:sigLen);
    exSignal = [];
    % control is all positive input
    nodeControl = [];
    exControl = [];
    si(2,2:end) = si(6,1:sigLen-1);
    si(4,2:end) = si(6,1:sigLen-1); % caution! node 2 & 4 is Multicollinearity case (correlated)

    %% test pattern 1 
    netMVAR = initMvarNetwork(si, exSignal, [], exControl, lags);
    
    % show multivaliate VAR-DI
    figure; pDI = plotPvarDI(si, exSignal, [], exControl, lags, 0);
    figure; mDI = plotMvarDI(netMVAR, [], exControl, 0);
    figure; mMIV = plotMvarMIV(si, exSignal, [], exControl, netMVAR, 0);
    figure; mTV = plotMvarTVM(netMVAR, [], exControl);
    % compare to mvGC
    figure; GC = plotMultivariateGCI(si, exSignal, [], exControl, lags, 0);
    figure; GC = plotPairwiseGCI(si, exSignal, [], exControl, lags, 0);

    %% test pattern 2
    lags = 3;
    exNum = 2;
    exSignal = siOrg(nodeNum+1:nodeNum+exNum,1:sigLen);
    % control is all positive input
    exControl = ones(nodeNum,exNum);
    si(3,2:end) = exSignal(1,1:sigLen-1);

    % init MVAR network
    netMVAR = initMvarNetwork(si, exSignal, nodeControl, exControl, lags);
    
    % show multivaliate MVAR-DI
    figure; pDI = plotPvarDI(si, exSignal, nodeControl, exControl, lags, 0, 1);
    figure; mDI = plotMvarDI(netMVAR, nodeControl, exControl, 0, 1);
    figure; mMIV = plotMvarMIV(si, exSignal, nodeControl, exControl, netMVAR, 0, 1);
    figure; mTV = plotMvarTVM(netMVAR, nodeControl, exControl, 20, 1);
    % compare to mvGC
    figure; GC = plotMultivariateGCI(si, exSignal, nodeControl, exControl, lags, 0, 0, 1);
    figure; GC = plotPairwiseGCI(si, exSignal, nodeControl, exControl, lags, 0, 0, 1);

    %% test pattern 3
    lags = 3;
    exNum = 4;
    exSignal = siOrg(nodeNum+1:nodeNum+exNum,1:sigLen);
    % control is all positive input
    nodeControl = ones(nodeNum,nodeNum,lags);
    for k=1:nodeNum, nodeControl(k,k,2)=0; end
    exControl = ones(nodeNum,exNum,lags);
    si(3,2:end) = exSignal(1,1:sigLen-1);
    si(5,3:end) = si(1,1:sigLen-2); % lag=2, this will be blocked by nodeControl
    nodeControl(5,1,2) = 0; % <= comment out and check control effect
    si(7,3:end) = exSignal(2,1:sigLen-2); % lag=2, this will be blocked by exControl
    exControl(7,2,2) = 0; % <= comment out and check control effect

    % init MVAR network
    netMVAR = initMvarNetwork(si, exSignal, nodeControl, exControl, lags);
    
    % show multivaliate MVAR-DI
    figure; pDI = plotPvarDI(si, exSignal, nodeControl, exControl, lags, 0, 1);
    figure; mDI = plotMvarDI(netMVAR, nodeControl, exControl, 0, 1);
    figure; mMIV = plotMvarMIV(si, exSignal, nodeControl, exControl, netMVAR, 0, 1);
    figure; mTV = plotMvarTVM(netMVAR, nodeControl, exControl, 20, 1);
    % compare to mvGC
    figure; GC = plotMultivariateGCI(si, exSignal, nodeControl, exControl, lags, 0, 0, 1);
    figure; GC = plotPairwiseGCI(si, exSignal, nodeControl, exControl, lags, 0, 0, 1);
end

