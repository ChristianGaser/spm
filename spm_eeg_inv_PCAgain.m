function varargout = PCAgain(varargin)

%=======================================================================
% Compute the PCA and the normalisation of the gain matrix.
% This step is a prerequisite to Multivariate Source Prelocalisation
%
% FORMAT [Gnorm,VectP,ValP] = spm_eeg_inv_meshing(G)
% Input:
% G		    - gain matrix (Nsens x Nsour)
% Output:
% Gnorm		- gain matrix with normalized columns
%             (each lead-field has been normalized to one)
% VectP     - matrix containing the eigenvectors of Gnorm
% ValP      - diagonal matrix containing the eigenvalues of Gnorm
%             (Gnorm = VectP * ValP * U' ; U contains the eigenimages)
%
% FORMAT [fname_out] = spm_eeg_inv_meshing(fname_in)
% Input:
% fname_in  - .mat file containing the gain matrix
% Output:
% fname_out - .mat file containing the output variables (Gnorm, VectP, ValP)
%
% FORMAT spm_eeg_inv_meshing(fname_in)
% Input:
% fname_in  - .mat file containing the gain matrix
% Output:
% the output variables are saved in a .mat file whose name is derived from the input file
%=======================================================================
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

% Jeremie Mattout
% $Id: spm_eeg_inv_PCAgain.m 308 2005-11-23 19:21:56Z jeremie $


% Input
if nargin == 1
    variabl = varargin{1};
else
    disp('Wrong input arguments');
    return
end

if isnumeric(variabl)
    G = variabl;
    clear variabl
elseif ischar(variabl)
    [pth,nam,ext] = spm_fileparts(variabl);
    varmat = load(variabl);
    varname = fieldnames(varmat);
    G = getfield(varmat,varname{1});
    clear varmat varname variabl
else
    disp('Wrong input format');
    return
end


% Lead-field normalization
NCG = sqrt(sum(G.*G));
Gsize = size(G,1);
P = ones(Gsize,1);
Lc = P*NCG;
Gnorm = G./Lc;
clear NCG Gsize P Lc; 


% SVD
[OrtoP MatVP VectP] = svd(Gnorm',0);
ValP = diag(MatVP);
clear OrtoP MatVP;


% Output
if nargout == 3
    varargout{1} = Gnorm;
    varargout{2} = VectP;
    varargout{3} = ValP;
elseif nargout == 1
    save(varargout{1},'Gnorm','VectP','ValP');
else
    fname_out = fullfile(pth,[nam '_pca.mat']);
    save(fname_out,'Gnorm','VectP','ValP');
    if nargout ~= 0
        disp('Wrong output format');
        return
    end
end

return