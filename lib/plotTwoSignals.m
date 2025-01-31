%%
% Prot two signals
% input:
%  X          multivariate time series matrix (node x time series)
%  Y          multivariate time series matrix (node x time series)
%  showEach   showSubplot (0) or show each graph (1) (default:0)
%  yRange     ylim range (default:[-0.2 1])

function [mae, maeerr, errs] = plotTwoSignals(X, Y, showEach, yRange)
    if nargin < 4, yRange = [-0.2 1]; end
    if nargin < 3, showEach = 0; end

    nodeNum = size(X,1);
    % show figure;
    if showEach~=0, figure; end
    d=0; e=0; errs=[];
    for i=1:nodeNum
        Xi = X(i,:);
        Yi = Y(i,:);
        mat = [Xi.', Yi.'];
        if showEach~=0
            figure;
        else
            subplot(nodeNum,1,i);
        end
        plot(mat); ylim(yRange);
        if i~=nodeNum, xticklabels({}); end

        d = d + sqrt(immse(Yi, Xi));
        e = e + mean(abs(Yi - Xi));
        A = single(Yi - Xi);
        errs = [errs; A];
    end
    mae = e / nodeNum;
    maeerr = std(errs(:)) / sqrt(length(errs(:)));
end
