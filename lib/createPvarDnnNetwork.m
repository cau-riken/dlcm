%%
% Create pairwise VAR DNN network
% input:
%  nodeNum         node number
%  exNum           exogenous input number
%  hiddenNums      hidden layer (next of input) neuron numbers of single unit (vector)
%  lags            number of lags for autoregression (default:3)
%  nodeControl     node control matrix (node x node) (default:[])
%  exControl       exogenous input control matrix (node x exogenous input) (default:[])
%  initWeightFunc  initializing weight function for hidden1 layer (default:[])
%  initWeightParam parameters for initializing weight function (default:[])
%  initBias        initializing bias value for hidden1 layer (default:0)
%             For uniform distribution, bias = 0 and empty initial weight is better
%             For fMRI BOLD signal, bias = 0.5 and rough initial weight is better

function net = createPvarDnnNetwork(nodeNum, exNum, hiddenNums, lags, nodeControl, exControl, initWeightFunc, initWeightParam, initBias)
    if nargin < 9, initBias = zeros(hiddenNums(1),1); end
    if nargin < 8, initWeightParam = []; end
    if nargin < 7, initWeightFunc = []; end
    if nargin < 6, exControl = []; end
    if nargin < 5, nodeControl = []; end
    if nargin < 4, lags = 3; end

    % set control 3D matrix (node x node x lags)
    [nodeControl,exControl,~] = getControl3DMatrix(nodeControl, exControl, nodeNum, exNum, lags);

    nodeMax = nodeNum + exNum;
    nodeLayers = cell(nodeNum,nodeMax);
    for i=1:nodeNum
        selfNum = sum(nodeControl(i,i,:),'all');
        for j=1:nodeMax
            if i==j, continue; end
            if j<=nodeNum && ~any(nodeControl(i,j,:),'all'), continue; end
            if j>nodeNum && ~any(exControl(i,j-nodeNum,:),'all'), continue; end
            
            if j<=nodeNum
                inputNums = selfNum + sum(nodeControl(i,j,:),'all');
            else
                inputNums = selfNum + sum(exControl(i,j-nodeNum,:),'all');
            end
            nodeLayers{i,j} = createPvarDnnLayers(inputNums, hiddenNums, initWeightFunc, initWeightParam, initBias);
        end
    end
    net.version = 1.1;
    net.nodeNum = nodeNum;
    net.exNum = exNum;
    net.lags = lags;
    net.nodeLayers = nodeLayers;
    net.nodeNetwork = cell(nodeNum,nodeMax);
    net.trainInfo = cell(nodeNum,nodeMax);
    net.initWeights = cell(nodeNum,nodeMax);
    net.trainTime = 0;
    net.recoverTrainTime = 0;
end