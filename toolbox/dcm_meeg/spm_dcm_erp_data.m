function DCM = spm_dcm_erp_data(DCM,h)
% prepares structures for forward model(EEG, MEG and LFP)
% FORMAT DCM = spm_dcm_erp_data(DCM,h)
% DCM  - DCM structure
% h    - order of drift terms
%
% requires
%
%    DCM.xY.Dfile        - data file
%    DCM.options.trials  - trial codes
%    DCM.options.Tdcm    - Peri-stimulus time window
%    DCM.options.D       - Down-sampling
%    DCM.options.han     - hanning
%
% sets
%    DCM.xY.modality - 'MEG','EEG' or 'LFP'
%    DCM.xY.Time     - Time [ms] data
%    DCM.xY.pst      - Time [ms] of down-sampled data
%    DCM.xY.dt       - sampling in seconds (s)
%    DCM.xY.y        - response variable for DCM
%    DCM.xY.xy       - cell array of trial-specific response {[ns x nc]}
%    DCM.xY.It       - Indices of (ns) time bins
%    DCM.xY.Ic       - Indices of (nc) good channels
%    DCM.xY.name     - names of (nc) channels
 
%
%    DCM.xY.Hz       - Frequency bins (for Wavelet transform)
%    DCM.options.h
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Karl Friston
% $Id: spm_dcm_erp_data.m 2372 2008-10-21 18:26:04Z cc $
 
 
% Set defaults and Get D filename
%--------------------------------------------------------------------------
try
    Dfile = DCM.xY.Dfile;
catch
    errordlg('Please specify data and trials');
    error('')
end
 
% order of drift terms
%--------------------------------------------------------------------------
try, h; catch h = 0; end
 
% load D
%--------------------------------------------------------------------------
try
    D = spm_eeg_load(Dfile);
catch
    try
        [p,f]        = fileparts(Dfile);
        D            = spm_eeg_load(f);
        DCM.xY.Dfile = fullfile(pwd,f);
    catch
        try
            [f,p]        = uigetfile('*.mat','please select data file');
            name         = fullfile(p,f);
            D            = spm_eeg_load(name);
            DCM.xY.Dfile = fullfile(name);
        catch
            warndlg([Dfile ' could not be found'])
            return
        end
    end
end
 
% Check whether data type is evoked
%--------------------------------------------------------------------------
switch lower(D.type)
    case {'evoked','grandmean','single'}
        % these are the 'evoked' types of data
    otherwise
        warndlg('DCM is meant for evoked data!');
end
 
% indices of EEG channel (excluding bad channels) and peristimulus times
%--------------------------------------------------------------------------
if ~isfield(DCM.xY, 'modality')
    DCM.xY.modality = spm_eeg_modality_ui(D);
end
 
modality = DCM.xY.modality;
channels = D.chanlabels;
 
if ~isfield(DCM.xY, 'Ic')
    Ic        = strmatch(modality, D.chantype,'exact');
    Ic        = setdiff(Ic, D.badchannels);
    DCM.xY.Ic = Ic;
end
 
Ic            = DCM.xY.Ic;
Nc            = length(Ic);
DCM.xY.name   = channels(Ic);
DCM.xY.Ic     = Ic;
DCM.xY.Time   = 1000*D.time; % PST (ms)
DCM.xY.dt     = 1/D.fsample;
DCM.xY.xy     = {};
 
% options
%--------------------------------------------------------------------------
try
    DT   = DCM.options.D;
catch
    errordlg('Please specify down sampling');
    error('')
end
try
    han  = DCM.options.han;
catch
    han  = 0;
end
try
    trial = DCM.options.trials;
catch
    errordlg('please specify trials');
    error('')
end
try
 
    % time window and bins for modelling
    %----------------------------------------------------------------------
    T1          = DCM.options.Tdcm(1);
    T2          = DCM.options.Tdcm(2);
    [i, T1]     = min(abs(DCM.xY.Time - T1));
    [i, T2]     = min(abs(DCM.xY.Time - T2));
 
    % Time [ms] of down-sampled data
    %----------------------------------------------------------------------
    It          = [T1:DT:T2]';
    Ns          = length(It);                % number of samples
    DCM.xY.pst  = DCM.xY.Time(It);           % Down-sampled PST
    DCM.xY.dt   = DT/D.fsample;              % sampling in seconds
    DCM.xY.It   = It;                        % Indices of time bins
 
catch
    errordlg('Please specify time window');
    error('')
end
 
% get trial averages - ERP
%--------------------------------------------------------------------------
condlabels = D.condlist;
for i = 1:length(trial)
 
    % trial indices
    %----------------------------------------------------------------------
    c     = D.pickconditions(condlabels{trial(i)});
    Nt    = length(c);
 
    % ERP
    %----------------------------------------------------------------------
    Y     = zeros(Ns,Nc);
    for j = 1:Nt
        Y = Y + squeeze(D(Ic,It,c(j)))';
    end
    DCM.xY.xy{i} = Y/Nt;
end
 
 
% confounds - DCT:
%--------------------------------------------------------------------------
if h == 0
    X0 = sparse(Ns,1);
else
    X0 = spm_dctmtx(Ns,h);
end
R      = speye(Ns) - X0*X0';
 
% hanning
%--------------------------------------------------------------------------
if han
    R  = R*diag(hanning(Ns))*R;
end
 
% adjust data
%--------------------------------------------------------------------------
for i = 1:length(DCM.xY.xy);
    DCM.xY.xy{i} = R*DCM.xY.xy{i};
end
 
% condition units of measurement
%--------------------------------------------------------------------------
DCM.xY.y    = spm_cond_units(DCM.xY.xy,1);
DCM.xY.code = condlabels(trial);
