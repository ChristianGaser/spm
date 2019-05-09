function [Y,W,U,V] = spm_voice_iff(xY)
% inverse decomposition at fundamental frequency
% FORMAT [Y,W,U,V] = spm_voice_iff(xY)
%
% xY    -  cell array of word structures
% xY.Q  -  parameters - lexical
% xY.P  -  parameters - prosidy
% xY.R  -  parameters - speaker
% 
% xY.P.amp - log amplitude
% xY.P.dur - log duration (seconds)
% xY.P.lat - log latency (sec)
% xY.P.tim - log timbre (a.u.)
% xY.P.inf - inflection (a.u.)

% xY.R.F0  - fundamental frequency (Hz)
% xY.R.F1  - format frequency (Hz
%
% Y     - reconstructed timeseries
% W     - formants (time-frequency representation): W = U*xY.Q*V'
% U     - DCT over frequency
% V     - DCT over intervals
%      
%
% This routine recomposes a timeseries from temporal basis sets at the
% fundamental frequency. In other words, it applies the reverse sequence
% of inverse transforms implemented by spm_voice_ff.m
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_voice_iff.m 7589 2019-05-09 12:57:23Z karl $

% defaults
%--------------------------------------------------------------------------
global VOX
if VOX.mute && ~nargout && ~VOX.graphics
    return
end
try, FS = VOX.FS; catch, FS  = 22050; end    % sampling frequency
try, Tu = VOX.Tu; catch, Tu  = 4;     end    % log scaling (formants)
try, Tv = VOX.Tv; catch, Tv  = 1;     end    % log scaling (interval)


% recompose and play
%--------------------------------------------------------------------------
if numel(xY) > 1
    for s = 1:numel(xY)
        spm_voice_iff(xY(s));
    end
    return
end

% reconstitute sample points
%--------------------------------------------------------------------------
M  = exp(xY.P.amp);                          % amplitude
L  = exp(xY.P.lat);                          % latency (sec)
T  = exp(xY.P.dur);                          % duration (seconds)
S  = exp(xY.P.tim);                          % timbre
P  = xY.P.inf;                               % inflection

F0 = exp(xY.R.F0);                           % fundamental frequency (Hz)
F1 = exp(xY.R.F1);                           % formant frequency (Hz)

% reconstitute intervals
%--------------------------------------------------------------------------
nI = fix(T*F0);                              % number of intervals
D  = spm_dctmtx(nI - 1,numel(P));            % basis set for inflection
dI = D*P(:)*sqrt(nI)/F0;                     % fluctuations
I  = fix([1; FS*cumsum(dI)]);                % cumulative intervals

% reconstitute format coefficients
%--------------------------------------------------------------------------
Ni = 256;                                    % number of formant bins
ni = numel(I) - 1;                           % number of intervals
nj = round(FS/F1);                           % interval length

Nu = size(xY.Q,1);
Nv = size(xY.Q,2);
nu = exp(-Tu*(0:(Ni - 1))/Ni);               % log spacing
nv = exp(-Tv*(0:(ni - 1))/ni);               % log spacing
nu = nu - min(nu); nu = Ni - (Ni - 1)*nu/max(nu);
nv = nv - min(nv); nv = ni - (ni - 1)*nv/max(nv);
U  = spm_dctmtx(Ni,Nu,nu);                   % DCT over formants
V  = spm_dctmtx(ni,Nv,nv);                   % DCT over intervals
W  = U*xY.Q*V';                              % formants
Q  = exp(S*W/std(W(:)));                     % timbre

% reconstitute timeseries
%--------------------------------------------------------------------------
jj = 0:(2*nj);
D  = spm_dctmtx(numel(jj),Ni*4);
D  = D*kron(speye(Ni,Ni),[1 0 -1 0]');
Y  = zeros(I(end) + 2*nj,1);
for j = 1:ni
    ii    = I(j)  + jj;
    Y(ii) = Y(ii) + D*Q(:,j);
end

% scale amplitude
%--------------------------------------------------------------------------
Y  = 4*M*Y/sum(std(Q));

% add latency
%--------------------------------------------------------------------------
Y  = [zeros(fix(L*FS),1); Y];

% play timeseries if requested
%--------------------------------------------------------------------------
if ~ VOX.mute && ~ nargout
    sound(Y,FS);
end

% graphics  if requested
%--------------------------------------------------------------------------
if ~ isfield(VOX,'graphics'), return, end

if VOX.graphics
    
    % figure
    %----------------------------------------------------------------------
    spm_figure('GetWin','Voice (graphics)'); clf;
    
    % peristimulus time (seconds) and plot
    %----------------------------------------------------------------------
    pst = (1:numel(Y))/FS;
    subplot(2,2,1), plot(pst,Y,[L,L],[-M M],':')
    xlabel('time (sec)'), ylabel('amplitude')
    title('Timeseries','FontSize',16), axis square, spm_axis tight
    
    subplot(2,2,2), imagesc((1:ni)/F0,1000*[-nj,nj]/FS,D*Q)
    axis square, xlabel('time (seconds)'), ylabel('time (ms)')
    title('Transients','FontSize',16), set(gca,'YLim',[-8 8])
    
    subplot(4,2,5), imagesc(xY.Q), axis square
    xlabel('coefficients'), ylabel('coefficients')
    title('Parameters','FontSize',16)

    subplot(4,2,6), imagesc((1:ni)/F0,(1:Ni)*F1,Q)
    xlabel('time (seconds)'), ylabel('Formants (Hz)')
    title('Spectral (log) energy','FontSize',16), drawnow

    subplot(4,2,7), plot(1./dI), axis square, spm_axis tight
    xlabel('time (intervals)'), ylabel('fundamental frequency')
    title('Inflection','FontSize',16)
    
    subplot(4,2,8), imagesc((1:ni)/F0,(1:Ni)*F1,W)
    xlabel('time (seconds)'), ylabel('Formants (Hz)')
    title('Spectral decomposition','FontSize',16), drawnow
    
end





