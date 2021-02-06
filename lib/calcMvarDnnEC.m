%%
% Caluclate multivariate VAR DNN effective connectivity matrix (EC) and impaired node signals (ECsub)
% returns mVAR DNN EC matrix (EC) and impaired node signals (ECsub)
% input:
%  net          trained multivariate VAR DNN network
%  nodeControl  node control matrix (node x node) (optional)
%  exControl    exogenous input control matrix for each node (node x exogenous input) (optional)
%  isFullNode   return both node & exogenous causality matrix (default:0)

function [EC, ECsub] = calcMvarDnnEC(net, nodeControl, exControl, isFullNode)
    if nargin < 4, isFullNode = 0; end

    if isfield(net, 'nodeNum'), nodeNum = net.nodeNum; else nodeNum = length(net.nodeNetwork); end % for compatibility
    if isfield(net, 'exNum'), exNum = net.exNum; else exNum = size(net.nodeNetwork{1, 1}.Layers(2, 1).Weights, 2) - nodeNum; end % for compatibility
    if isfield(net, 'lags'), lags = net.lags; else lags = 1; end
    if isFullNode==0, nodeMax = nodeNum; else nodeMax = nodeNum + exNum; end

    % calc multivariate VAR DNN EC
    EC = nan(nodeNum,nodeMax);
    ECsub = nan(nodeNum,nodeMax+1);
    for i=1:nodeNum
        nodeInput = ones((nodeNum + exNum)*lags, 1);
        if ~isempty(nodeControl)
            filter = repmat(nodeControl(i,:).', lags, 1);
            nodeInput(1:nodeNum*lags,:) = nodeInput(1:nodeNum*lags,:) .* filter;
        end
        if ~isempty(exControl)
            filter = repmat(exControl(i,:).', lags, 1);
            nodeInput(nodeNum*lags+1:end,:) = nodeInput(nodeNum*lags+1:end,:) .* filter;
        end
        % predict 
        ECsub(i,1)  = predict(net.nodeNetwork{i}, nodeInput);

        % imparement node signals
        for j=1:nodeMax
            if i==j, continue; end
            if j<=nodeNum && ~isempty(nodeControl) && nodeControl(i,j) == 0, continue; end
            if j>nodeNum && ~isempty(exControl) && exControl(i,j-nodeNum) == 0, continue; end

            impInput = nodeInput;
            if j<=nodeNum
                for p=1:lags, impInput(j+nodeNum*(p-1),:) = 0; end
            else
                for p=1:lags, impInput(nodeNum*lags+(j-nodeNum)+exNum*(p-1),:) = 0; end
            end

            % predict 
            ECsub(i,j+1) = predict(net.nodeNetwork{i}, impInput);
            EC(i,j) = abs(ECsub(i,1) - ECsub(i,j+1));
        end
    end
end

