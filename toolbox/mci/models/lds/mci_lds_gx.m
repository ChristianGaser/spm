function [y,L] = mci_lds_gx (x,u,P,M)
% Observation function for LDS
% FORMAT [y,L] = mci_lds_gx (x,u,P,M)
%__________________________________________________________________________
% Copyright (C) 2015 Wellcome Trust Centre for Neuroimaging

% Will Penny
% $Id$

L=eye(M.n);
y=L*x;