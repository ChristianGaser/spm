function [cor,cov] = spm_ccf2cor(ccf)
% Converts  cross covariance function to correlation and covariance
% FORMAT [cor,cov] = spm_ccf2cor(ccf)
%
% ccf  (N,n,n) - cross covariance function
%
% cor  (n,n)   - correlation
% cov  (n,n)   - covariance
%
% See also: 
%  spm_ccf2csd.m, spm_ccf2mar, spm_csd2ccf.m, spm_csd2mar.m, spm_mar2csd.m,
%  spm_csd2coh.m, spm_Q.m, spm_mar.m and spm_mar_spectral.m
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_ccf2cor.m 7774 2020-01-25 18:07:03Z karl $

% convert via cross spectral density
%==========================================================================
i   = (size(ccf,1) + 1)/2; 
cov = squeeze(ccf(fix(i),:,:));

% correlations from covariance
%--------------------------------------------------------------------------
cor = spm_cov2corr(cov);