function [y,w] = spm_csd_mtf(P,M,U)
% Spectral response of a NMM (transfer function x noise spectrum)
% FORMAT [G,w] = spm_csd_mtf(P,M,U)
%
% P - parameters
% M - neural mass model structure
% U - trial-specific effects
%
% G - {G(N,nc,nc}} - cross-spectral density for nc channels {trials}
%                  - for N frequencies in M.Hz [default 1:64Hz]
% w - frequencies
%
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_csd_mtf.m 4095 2010-10-22 19:37:51Z karl $


% compute log-spectral density
%==========================================================================

% frequencies of interest
%--------------------------------------------------------------------------
try
    dt = 1/(2*round(M.Hz(end)));
    N  = 1/dt;
    If = round(linspace(M.Hz(1),M.Hz(end),length(M.Hz)));
catch
    N  = 128;
    dt = 1/N;
    If = 1:N/2;
end
f    = [1:N/2]';
w    = f(If);

% exogenous (neuronal) inputs
%--------------------------------------------------------------------------
M.u  = sparse(M.m,1);

% solve for fixed point (i.e., 64ms burn in)
%--------------------------------------------------------------------------
S    = M;
S.g  = {};
V.u  = sparse(8,M.m);
V.dt = 8/1000;
x    = spm_int_L(P,S,V);
x    = spm_unvec(x(end,:),S.x);
M.x  = x;

% get delay operator
%--------------------------------------------------------------------------
try
    [fx dfdx D] = feval(M.f,M.x,M.u,P,M);
catch
    D = 1;
end

% spectrum of innovations (Gu)
%--------------------------------------------------------------------------
AR   = f.^-1;                                     % pink component
ID   = f.^0;                                      % white component
Gu   = AR*exp(P.a(1))   + ID*exp(P.a(2))/4;       % neuronal innovations
Gn   = AR*exp(P.b(1))   + ID*exp(P.b(2))/8;       % channel noise (non-specific)
Gs   = AR*exp(P.c(1,:)) + ID*exp(P.c(2,:))/8;     % channel noise (specific)



% trial-specific effects
%==========================================================================
try, X = U.X; catch, X = sparse(1,0); end


% cycle over trials
%--------------------------------------------------------------------------
GS     = 0;
for  c = 1:size(X,1)

    % basline parameters
    %----------------------------------------------------------------------
    Q  = P;

    % trial-specific effective connectivity
    %----------------------------------------------------------------------
    for i = 1:size(X,2)
        Q.A{1} = Q.A{1} + X(c,i)*P.B{i};         % forward   connections
        Q.A{2} = Q.A{2} + X(c,i)*P.B{i};         % backward  connections
        Q.A{3} = Q.A{3} + X(c,i)*P.B{i};         % lateral   connections
       try
            Q.H = Q.H + X(c,i)*diag(P.B{i});     % intrinsic connections
        catch
            Q.G = Q.G + X(c,i)*diag(P.B{i});
        end
    end

    % augment and bi-linearise (with delays)
    %----------------------------------------------------------------------
    [M0,M1,L] = spm_bireduce(M,Q,D);

    % project onto spatial modes
    %----------------------------------------------------------------------
    try
        L = M.U'*L;
    end

    % compute modulation transfer function using FFT of the kernels
    %----------------------------------------------------------------------
    [K0,K1]   = spm_kernels(M0,M1,L,N,dt);


    % [cross]-spectral density
    %----------------------------------------------------------------------
    [N,nc,nu] = size(K1);
    G     = zeros(N/2,nc,nc);
    for i = 1:nc
        for j = i:nc

            % cross-spectral density from neuronal interactions
            %--------------------------------------------------------------
            for k = 1:nu
                Si       = fft(K1(:,i,k));
                Sj       = fft(K1(:,j,k));
                Gij      = Si.*conj(Sj);
                Gij      = Gij([1:N/2] + 1).*Gu;
                G(:,i,j) = G(:,i,j) + Gij;
            end

        end        
    end

    % save trial-specific frequencies of interest
    %----------------------------------------------------------------------
    y{c} = G(If,:,:);

end

% and add channel noise
%--------------------------------------------------------------------------
for c = 1:length(y)
    G     = y{c};
    for i = 1:nc
        for j = i:nc

            % cross-spectral density from common channel noise
            %--------------------------------------------------------------
            G(:,i,j) = G(:,i,j) + Gn(If);
            
            % and channel specific noise
            %--------------------------------------------------------------
            if i == j
                try
                    G(:,i,i) = G(:,i,i) + Gs(If,i);
                catch
                    G(:,i,i) = G(:,i,i) + Gs(If,1);
                end
            else
                
                % fill in lower half of CSD matrix
                %----------------------------------------------------------
                G(:,j,i) = conj(G(:,i,j));
                
            end
        end
    end
    y{c} = G;
end
    


