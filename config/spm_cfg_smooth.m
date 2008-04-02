function smooth = spm_cfg_smooth
% SPM Configuration file
% automatically generated by the MATLABBATCH utility function GENCODE
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% $Id: spm_cfg_smooth.m 1295 2008-04-02 14:31:24Z volkmar $

rev = '$Rev: 1295 $';
% ---------------------------------------------------------------------
% data Images to Smooth
% ---------------------------------------------------------------------
data         = cfg_files;
data.tag     = 'data';
data.name    = 'Images to Smooth';
data.help    = {'Specify the images to smooth. The smoothed images are written to the same subdirectories as the original *.img and are prefixed with a ''s'' (i.e. s*.img). The prefix can be changed by an option setting.'};
data.filter = 'image';
data.ufilter = '.*';
data.num     = [0 Inf];
% ---------------------------------------------------------------------
% fwhm FWHM
% ---------------------------------------------------------------------
fwhm         = cfg_entry;
fwhm.tag     = 'fwhm';
fwhm.name    = 'FWHM';
fwhm.val{1} = double([8 8 8]);
fwhm.help    = {'Specify the full-width at half maximum (FWHM) of the Gaussian smoothing kernel in mm. Three values should be entered, denoting the FWHM in the x, y and z directions.'};
fwhm.strtype = 'e';
fwhm.num     = [1 3];
% ---------------------------------------------------------------------
% dtype Data Type
% ---------------------------------------------------------------------
dtype         = cfg_menu;
dtype.tag     = 'dtype';
dtype.name    = 'Data Type';
dtype.val{1} = double(0);
dtype.help    = {'Data-type of output images.  SAME indicates the same datatype as the original images.'};
dtype.labels = {
                'SAME'
                'UINT8  - unsigned char'
                'INT16 - signed short'
                'INT32 - signed int'
                'FLOAT - single prec. float'
                'DOUBLE - double prec. float'
}';
dtype.values{1} = double(0);
dtype.values{2} = double(2);
dtype.values{3} = double(4);
dtype.values{4} = double(8);
dtype.values{5} = double(16);
dtype.values{6} = double(64);
% ---------------------------------------------------------------------
% prefix Filename Prefix
% ---------------------------------------------------------------------
prefix         = cfg_entry;
prefix.tag     = 'prefix';
prefix.name    = 'Filename Prefix';
prefix.val = {'s'};
prefix.help    = {'Specify the string to be prepended to the filenames of the smoothed image file(s). Default prefix is ''s''.'};
prefix.strtype = 's';
prefix.num     = [1 Inf];
% ---------------------------------------------------------------------
% smooth Smooth
% ---------------------------------------------------------------------
smooth         = cfg_exbranch;
smooth.tag     = 'smooth';
smooth.name    = 'Smooth';
smooth.val     = {data fwhm dtype prefix };
smooth.help    = {'This is for smoothing (or convolving) image volumes with a Gaussian kernel of a specified width. It is used as a preprocessing step to suppress noise and effects due to residual differences in functional and gyral anatomy during inter-subject averaging.'};
smooth.prog = @spm_run_smooth;
smooth.vout = @vout;
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function dep = vout(varargin)
% Output file names will be saved in a struct with field .files
dep(1)            = cfg_dep;
dep(1).sname      = 'Smoothed Images';
dep(1).src_output = substruct('.','files');
dep(1).tgt_spec   = cfg_findspec({{'class','cfg_files','strtype','e'}});
