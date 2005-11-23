function D = spm_eeg_inv_datareg_ui(S)

%=======================================================================
% Data registration user-interface routine
% commands the EEG/MEG data co-registration within original sMRI space
%
% FORMAT D = spm_eeg_inv_mesh_ui(S)
% Input:
% S		    - input data struct (optional)
% Output:
% D			- same data struct including the new required files and variables
%=======================================================================
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

% Jeremie Mattout
% $Id: spm_eeg_inv_datareg_ui.m 308 2005-11-23 19:21:56Z jeremie $

spm_defaults

try
    D = S; 
    clear S
catch
    D = spm_select(1, '.mat', 'Select EEG/MEG mat file');
	D = spm_eeg_ldata(D);
end

val = length(D.inv);
if val > 1
    D = spm_eeg_inv_copyfields(D,[0 1 0 0]);
end

Rflag = spm_input('Registration type','+1','Landmarks|Surface',[1 2]);

D = spm_eeg_inv_datareg(Rflag,D);

spm_eeg_inv_checkdatareg(D);

return