function M = spm_get_space(P,M)
% Get/set the voxel-to-world mapping of an image
% FORMAT M = spm_get_space(P)
%            spm_get_space(P,M)
% M - voxel-to-world mapping
% P - image filename
%_______________________________________________________________________
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

% John Ashburner
% $Id: spm_get_space.m 166 2005-05-18 15:46:13Z john $


[pth,nam,ext] = fileparts(P);
t = find(ext==',');
n = [1 1];
if ~isempty(t),
    n   = str2num(ext((t(1)+1):end));
    ext = ext(1:(t-1));
    P   = fullfile(pth,[nam ext]);
end;

N = nifti(P);
if nargin==2,
    N.mat_intent = 'Aligned';
    if n(1)==1,
        N.mat        = M;
        if strcmp(N.mat0_intent,'Aligned'), N.mat0 = M; end;
        if ~isempty(N.extras) && isstruct(N.extras) && isfield(N.extras,'mat') &&...
            size(N.extras.mat,3)>=1,
            N.extras.mat(:,:,n(1)) = M;
        end;
    else
        N.extras.mat(:,:,n(1)) = M;
    end;
    create(N);
else
    if ~isempty(N.extras) && isstruct(N.extras) && isfield(N.extras,'mat') &&...
        size(N.extras.mat,3)>=n(1) && sum(sum(N.extras.mat(:,:,n(1)))),
        M = N.extras.mat(:,:,n(1));
    else
        M = N.mat;
    end;
end;

