function [xY,Y] = spm_voice_speak(q,p,r)
% Generates a continuous state space word discrete causes
% FORMAT [xY,Y] = spm_voice_speak(q,p,r)
%
% q      - lexcial index (1 x number of words)
% p      - prosody index (k x number of words)
% r      - prosody index (1 x number of words)
%
% requires the following in the global variable VOX:
% LEX    - lexical structure array
% PRO    - prodidy structure array
% WHO    - speaker structure array
%
% xY.Q  -  parameters - lexical
% xY.P  -  parameters - prosidy
% xY.R  -  parameters - speaker
%
% Y     -  corresponding timeseries
%
% This routine recomposes and plays a timeseries, specified as a sequence
% of words that can be articulated with a particular prosody.  This routine
% plays the same role as spm_voice_iff but uses the dictionaries supplied
% by the lexical and prosody structures to enable a categorical
% specification of a spoken phrase. In other words, it allows one to map
% from discrete state space of lexical content and prosody to continuous
% time outcomes.
%
% see also: spm_voice_iff.m
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_voice_speak.m 7589 2019-05-09 12:57:23Z karl $

% check for empty indices (that will invoke average lexical or prosody)
%--------------------------------------------------------------------------
global VOX
LEX = VOX.LEX;
PRO = VOX.PRO;
WHO = VOX.WHO;

if nargin < 1, q = zeros(0,1); end
if nargin < 2, p = zeros(0,1); end
if nargin < 3, r = zeros(0,1); end

n  = max([size(q,2),size(p,2),size(r,2)]);

if size(q,2) < n && size(q,1), q = repmat(q(:,1),1,n); end
if size(p,2) < n && size(p,1), p = repmat(p(:,1),1,n); end
if size(r,2) < n && size(r,1), q = repmat(r(:,1),1,n); end

% level of random fluctuations in formants
%--------------------------------------------------------------------------
if isfield(VOX,'RAND'), RAND = VOX.RAND; else RAND = 0; end

% assemble word structure arrays
%==========================================================================
for s = 1:n
    
    % lexical parameters
    %----------------------------------------------------------------------
    Q     = spm_vec(spm_zeros(VOX.Q));
    for i = 1:size(q,1)
        Q = Q + LEX(q(i,s),1).qE;
        E = sqrtm(LEX(q(i,s),1).qC)*randn(numel(VOX.Q),1)*RAND;
        Q = Q + E;
    end
    xY(s).Q = VOX.Q + reshape(Q,size(VOX.Q));

    
    % prosody parameters
    %----------------------------------------------------------------------
    P     = spm_vec(spm_zeros(VOX.P));
    for i = 1:size(p,1)
        P(i) = P(i) + PRO(i).pE(p(i,s));
    end
    xY(s).P  = spm_unvec(spm_vec(VOX.P) + P,VOX.P);
    
    % and identity
    %----------------------------------------------------------------------
    R      = spm_vec(spm_zeros(VOX.R));
    for i  = 1:size(r,1)
        R(i) = R(i) + WHO(i).pE(r(i,s));
    end
    xY(s).R  = spm_unvec(spm_vec(VOX.R) + R,VOX.R);
    
end

% assemble sequence
%==========================================================================

% convert into audio signal
%--------------------------------------------------------------------------
try, FS = VOX.FS; catch, FS  = 22050; end
for s = 1:n
    
    % increase volume and timbre for audio display
    %----------------------------------------------------------------------
    xY(s).P.amp = xY(s).P.amp + sqrt(2);
    xY(s).P.tim = xY(s).P.tim * sqrt(2);
    y{s}        = spm_voice_iff(xY(s));
    
end

% assemble into audio stream
%--------------------------------------------------------------------------
Y     = zeros(spm_length(y),1);
i0    = 0;
for s = 1:n
    ni    = numel(y{s});
    ii    = i0 + (1:ni)';
    Y(ii) = Y(ii) + y{s};
    i0    = ii(end) - round(ni/8);
end
Y     = Y(1:ii(end));

% send to speaker (at an accelerated sampling rate, depending upon F1)
%--------------------------------------------------------------------------
if ~nargout, sound(full(Y),FS); end

return


