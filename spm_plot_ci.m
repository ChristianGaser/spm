function spm_plot_ci(E,C,x,j,s)
% plots mean and conditional confidence intervals
% FORMAT spm_plot_ci(E,C,x,j,s)
% E - expectation
% C - variance or covariance
% x - domain
% j - rows of E to plot
% s - string to specify plot type:e.g. '--r' or 'exp'
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_plot_ci.m 4987 2012-10-05 19:21:44Z karl $

% unpack
%--------------------------------------------------------------------------
if iscell(E),         E = spm_cat(E(:)); end
if isstruct(E),       E = spm_vec(E);    end
if isstruct(C),       C = spm_vec(C);    end

if ~exist('x','var'), x = 1:size(E,2);   end
if ~exist('j','var'), j = 1:size(E,1);   end
if ~exist('s','var'), s = '';            end

if isempty(x),        x = 1:size(E,2);   end
if isempty(j),        j = 1:size(E,1);   end


% order and length of sequence
%--------------------------------------------------------------------------
E     = E(j,:);
[n N] = size(E);

% unpack conditional covariances
%--------------------------------------------------------------------------
ci    = spm_invNcdf(1 - 0.05);

if iscell(C)
    for i = 1:N
        c(:,i) = ci*sqrt(diag(C{i}(j,j)));
    end
else
    if all(size(C) == size(E))
        c = ci*sqrt(C(j,:));
    else
        C = diag(C);
        c = ci*sqrt(C(j,:));
    end
end

% set plot parameters
%--------------------------------------------------------------------------
switch get(gca,'NextPlot')
    case{lower('add')}
        col   = [1 1/4 1/4];
        width = .9;
    otherwise
        col   = [1 3/4 3/4];
        width = .8;
end

% conditional covariances
%--------------------------------------------------------------------------
if N >= 8
    
    % time-series plot
    %======================================================================
    if strcmpi(s,'exp')
        fill([x fliplr(x)],exp([full(E + c) fliplr(full(E - c))]),...
            [1 1 1]*.8,'EdgeColor',[1 1 1]*.5),hold on
        plot(x,exp(E))
        
    else
        fill([x fliplr(x)],[full(E + c) fliplr(full(E - c))],...
            [1 1 1]*.8,'EdgeColor',[1 1 1]*.5),hold on
        plot(x,E,s)
    end
    
    
elseif n == 2
    
    % plot in state-space
    %======================================================================    try,  C = C{1};  end
    [x y] = ellipsoid(E(1),E(2),1,c(1),c(2),0,32);
    fill(x(16,:)',y(16,:)',[1 1 1]*.9,'EdgeColor',[1 1 1]*.8),hold on
    plot(E(1,1),E(2,1),'.','MarkerSize',16)
    
    
else
    
    
    % bar
    %======================================================================
    if N == 1
        
        % conditional means
        %------------------------------------------------------------------
        bar(E,width,'Edgecolor',[1 1 1]/2,'Facecolor',[1 1 1]*.8), hold on
        box off
        set(gca,'XLim',[0 n + 1])
        
        % conditional variances
        %------------------------------------------------------------------
        for k = 1:n
            line([k k],[-1 1]*c(k) + E(k),'LineWidth',4,'Color',col);
        end
        
    else
        
        % conditional means
        %------------------------------------------------------------------
        h = bar(E);
        
        % conditional variances
        %------------------------------------------------------------------
        for m = 1:N
            x = mean(get(get(h(m),'Children'),'Xdata'));
            for k = 1:n
                line([x(k) x(k)],[-1 1]*c(k,m) + E(k,m),'LineWidth',4,'Color',col);
            end
        end
    end
    
end
hold off
drawnow
