%%
% calculate linear multivariate Vector Auto-Regression weights and Create mVAR network
% input:
%  X               multivariate time series matrix (node x time series)
%  exSignal        multivariate time series matrix (exogenous input x time series) (default:[])
%  nodeControl     node control matrix (node x node) (default:[])
%  exControl       exogenous input control matrix for each node (node x exogenous input) (default:[])
%  lags            number of lags for autoregression (default:3)

function net = initMvarNetwork(X, exSignal, nodeControl, exControl, lags)
    if nargin < 4, exControl = []; end
    if nargin < 3, nodeControl = []; end
    if nargin < 2, exSignal = []; end
    nodeNum = size(X,1);
    sigLen = size(X,2);
    exNum = size(exSignal,1);

    % set node input
    Y = [X; exSignal];
    inputNum = nodeNum + exNum;
    
    % set control 3D matrix (node x node x lags)
    [~,~,control] = getControl3DMatrix(nodeControl, exControl, nodeNum, exNum, lags);

    b = cell(nodeNum,1);
    bint = cell(nodeNum,1);
    r = cell(nodeNum,1);
    rint = cell(nodeNum,1);
    stats = cell(nodeNum,1);

    Y = flipud(Y.'); % need to flip signal

    % first, calculate vector auto-regression (VAR) without target
    Yj = zeros(sigLen-lags, lags*inputNum);
    for k=1:lags
        Yj(:,1+inputNum*(k-1):inputNum*k) = Y(1+k:sigLen-lags+k,:);
    end
    for i=1:nodeNum
        [~,idx] = find(control(i,:,:)==1);
        
        % vector auto-regression (VAR)
        Xt = Y(1:sigLen-lags,i);
        Xti = [Yj(:,idx), ones(sigLen-lags,1)]; % might not be good to add bias
        % apply the regress function
        [b{i},bint{i},r{i},rint{i},stats{i}] = regress(Xt,Xti);
    end
    net.nodeNum = nodeNum;
    net.exNum = exNum;
    net.lags = lags;
    net.bvec = b;
    net.bint = bint;
    net.rvec = r;
    net.rint = rint;
    net.stats = stats;
end