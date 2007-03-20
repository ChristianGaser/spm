function job = spm_config_dartel
% Configuration file for DARTEL jobs
%_______________________________________________________________________
% Copyright (C) 2006 Wellcome Department of Imaging Neuroscience

% John Ashburner
% $Id$

if spm_matlab_version_chk('7') < 0,
    job = struct('type','const',...
                 'name','Need MATLAB 7 onwards',...
                 'tag','old_matlab',...
                 'val',...
          {{['This toolbox needs MATLAB 7 or greater.  '...
            'More recent MATLAB functionality has been used by this toolbox.']}});
    return;
end;

addpath(fullfile(spm('dir'),'toolbox','DARTEL'));
%_______________________________________________________________________

entry = inline(['struct(''type'',''entry'',''name'',name,'...
        '''tag'',tag,''strtype'',strtype,''num'',num)'],...
        'name','tag','strtype','num');

files = inline(['struct(''type'',''files'',''name'',name,'...
        '''tag'',tag,''filter'',fltr,''num'',num)'],...
        'name','tag','fltr','num');

mnu = inline(['struct(''type'',''menu'',''name'',name,'...
        '''tag'',tag,''labels'',{labels},''values'',{values})'],...
        'name','tag','labels','values');

branch = inline(['struct(''type'',''branch'',''name'',name,'...
        '''tag'',tag,''val'',{val})'],...
        'name','tag','val');

repeat = inline(['struct(''type'',''repeat'',''name'',name,''tag'',tag,'...
         '''values'',{values})'],'name','tag','values');
%_______________________________________________________________________

matname = files('Parameter Files','matnames','mat',[1 Inf]);
matname.ufilter = '.*seg_sn\.mat$';
matname.help = {...
['Select ''_sn.mat'' files containing the spatial transformation ',...
 'and segmentation parameters. '...
 'Rigidly aligned versions of the image that was segmented will '...
 'be generated. '...
 'The files may have moved, so if they have, then ensure that they are '...
 'either in the output directory, or the current working directory.']};
%------------------------------------------------------------------------
odir = files('Output Directory','odir','dir',[1 1]);
odir.val = {'.'};
odir.help = {...
['Select the directory where the resliced files should be written.']};
%------------------------------------------------------------------------
bb      = entry('Bounding box','bb','e',[2 3]);
bb.val  = {ones(2,3)*NaN};
bb.help = {[...
'The bounding box (in mm) of the volume which is to be written ',...
'(relative to the anterior commissure). '...
'Non-finite values will be replaced by the bounding box of the tissue '...
'probability maps used in the segmentation.']};
%------------------------------------------------------------------------
vox      = entry('Voxel size','vox','e',[1 1]);
vox.val  = {1.5};
vox.help = {...
['The (isotropic) voxel sizes of the written images. '...
 'A non-finite value will be replaced by the average voxel size of '...
 'the tissue probability maps used by the segmentation.']};
%------------------------------------------------------------------------
orig = mnu('Image option','image',...
    {'Original','Bias Corrected','Skull-Stripped','Bias Corrected and Skull-stripped','None'},...
    {1,3,5,7,0});
orig.val  = {7};
orig.help = {...
['A resliced version of the original image can be produced, which may have '...
 'various procedures applied to it.  All procedures rescale the images so '...
 'that the mean white matter intensity is one. '...
 'The "skull stripped" versions are the images simply scaled by the sum '...
 'of the grey and white matter probabilities.']};
%------------------------------------------------------------------------
grey = mnu('Grey Matter','GM',{'Yes','No'},{1,0});
grey.val = {1};
grey.help = {'Produce a resliced version of this tissue class?'};
%------------------------------------------------------------------------
white = mnu('White Matter','WM',{'Yes','No'},{1,0});
white.val = {1};
white.help = grey.help;
%------------------------------------------------------------------------
csf = mnu('CSF','CSF',{'Yes','No'}, {1,0});
csf.val = {0};
csf.help = grey.help;
%------------------------------------------------------------------------
initial = branch('Initial Import','initial',{matname,odir,bb,vox,orig,grey,white,csf});
initial.prog   = @spm_dartel_import;
initial.vfiles = @vfiles_initial_import;
%------------------------------------------------------------------------

%------------------------------------------------------------------------
iits = mnu('Inner Iterations','its',...
    {'1','2','3','4','5','6','7','8','9','10'},...
    {1,2,3,4,5,6,7,8,9,10});
iits.val = {3};
iits.help = {[...
'The number of Gauss-Newton iterations to be done within this '...
'outer iteration. After this, new average(s) are created, '...
'which the individual images are warped to match.']};
%------------------------------------------------------------------------
form  = mnu('Form','form',...
    {'Linear Elastic Energy','Membrane Energy','Bending Energy'},{0,1,2});
form.val = {0};
form.help = {...
'Three different forms of regularisation can currently be used.'};
%------------------------------------------------------------------------
param = entry('Reg params','param','e',[1 3]);
param.val = {[0.1 0.01 0.001]};
param.help = {...
['For linear elasticity, the parameters are mu, lambda and id.',...
 'For membrane and bending energy, the parameters are lambda, unused and id.',...
 'id is a term for penalising absolute displacements, '...
 'and should therefore be small.'],...
['Use more regularisation for the early iterations so that the deformations '...
 'are smooth, and then use less for the later ones so that the details can '...
 'be better matched.']};
%------------------------------------------------------------------------
reg   = branch('Regularisation','reg',{form,param});
reg.help = {[...
'The registration is penalised by some ``energy'''' term.  Here, the form '...
'of this energy term is specified.']};
%------------------------------------------------------------------------
K = mnu('Time Steps','K',{'1','2','4','8','16','32','64','128','256','512'},...
    {0,1,2,3,4,5,6,7,8,9});
K.val = {4};
K.help = {...
['The number of time points used for solving the '...
 'partial differential equations.  A single time point would be '...
 'equivalent to a small deformation model. '...
 'Smaller values allow faster computations, but are less accurate in terms '...
 'of inverse consistancy and may result in the one-to-one mapping '...
 'breaking down.  Earlier iteration could use fewer time points, '...
 'but later ones should use about 64 '...
 '(or fewer if the deformations are very smooth).']};
%------------------------------------------------------------------------
sym = mnu('Symmetry','sym',{'Asymetric','Symetric'},{0,1});
sym.val = {0};
sym.help = {...
['Should the deformations be inverse consistant? '...
 'For warping to a smooth average template, this is probably not necessary.']};
%------------------------------------------------------------------------
lmreg = entry('LM Regularisation','lmreg','e',[1 1]);
lmreg.val = {0.01};
lmreg.help = {...
['Levenberg-Marquardt regularisation.  Larger values increase the '...
 'the stability of the optimisation, but slow it down.  A value of '...
 'zero results in a Gauss-Newton strategy, but this does not necessarily '...
 'ensure convergence because the gradients of the images may not be smooth.']};
%------------------------------------------------------------------------
cycles = mnu('Cycles','cyc',{'1','2','3','4','5','6','7','8'},...
    {1,2,3,4,5,6,7,8});
cycles.val = {3};
cycles.help = {[...
'Number of cycles used by the full multigrid matrix solver.'...
'See Numerical Recipes for more information on multigrid methods.']};
%------------------------------------------------------------------------
its = mnu('Iterations','its',{'1','2','3','4','5','6','7','8'},...
    {1,2,3,4,5,6,7,8});
its.val = {3};
its.help = {[...
'Number of relaxation iterations performed in each cycle. '...
'See the chapter on solving partial differential equations in '...
'Numerical Recipes for more information about relaxation methods.']};
%------------------------------------------------------------------------
fmg = branch('Multigrid Solver','fmg',{cycles,its});
fmg.help = {[...
'Parameters for the Full Multigrid solver for obtaining the '...
'matrix solution at each Gauss-Newton iteration. FMG is described in '...
'Numerical Recipes (2nd edition).']};
%------------------------------------------------------------------------
params = branch('Outer Iteration','param',{iits,reg,K,sym,lmreg,fmg});
params.help = {...
['Different parameters can be specified for each '...
 'outer iteration. '...
 'Each of them warps the images to the template, and then regenerates '...
 'the template from the average of the warped images. '...
 'Multiple outer iterations should be used for more accurate results, '...
 'beginning with a more coarse registration (more regularisation) '...
 'then ending with the more detailed registration (less regularisation).']};
%------------------------------------------------------------------------
params = repeat('Outer Iterations','param',{params});
params.help = {[...
'The images are averaged, and each individual image is warped to '...
'match this average.  This is done for each outer iteration. '...
'Within each of these, are a number of inner iterations, which don''t'...
'involve updatuing the average(s).']};
params.num = [1 Inf];
%------------------------------------------------------------------------
data = files('Images','images','image',[1 Inf]);
data.help = {...
['Select images of the same modality to be registered by minimising the '...
 'sum of squares difference from their average.']};
%------------------------------------------------------------------------
data = repeat('Images','images',{data});
data.num = [1 Inf];
data.help = {...
['Select the images to be warped together. '...
 'Multiple sets of images can be simultaneously registered. '...
 'For example, the first set may be a bunch of grey matter images, '...
 'and the second set may be the white matter images of the same subjects.']};
%------------------------------------------------------------------------
template = files('Template','template','nifti',[0 1]);
template.val = {{}};
template.help = {...
['Select template.  If empty, then a template will be iteratively generated.']};
%------------------------------------------------------------------------
warp = branch('Run DARTEL','warp',{data,template,params});
warp.prog = @run_dartel;
warp.help = {'Run the DARTEL nonlinear image registration procedure.'};
%------------------------------------------------------------------------

%------------------------------------------------------------------------
ffields = files('Flow fields','flowfields','nifti',[1 Inf]);
ffields.ufilter = '^u_.*';
ffields.help = {...
['The flow fields store the deformation information. '...
 'The same fields can be used for both forward or backward deformations '...
 '(or even, in principle, half way or exaggerated deformations).']};
%------------------------------------------------------------------------
data = files('Images','images','nifti',[1 Inf]);
data.help = {...
['Select images to be warped. Note that there should be the same number '...
 'of images as there are flow fields, such that each flow field '...
 'warps one image.']};
%------------------------------------------------------------------------
data = repeat('Images','images',{data});
data.num = [1 Inf];
data.help = {...
['The flow field deformations can be applied to multiple images, '...
 'but it is assumed that there are fewer volumes for each flow field than '...
 'there are flow fields. '...
 'At this point, you are chosing how many images each flow field '...
 'should be applied to.']};
%------------------------------------------------------------------------
interp.type = 'menu';
interp.name = 'Interpolation';
interp.tag  = 'interp';
interp.labels = {'Nearest neighbour','Trilinear','2nd Degree B-spline',...
'3rd Degree B-Spline ','4th Degree B-Spline ','5th Degree B-Spline',...
'6th Degree B-Spline','7th Degree B-Spline'};
interp.values = {0,1,2,3,4,5,6,7};
interp.val = {1};
interp.help = {...
['The method by which the images are sampled when being written in a ',...
'different space.'],...
['    Nearest Neighbour: ',...
'    - Fastest, but not normally recommended.'],...
['    Bilinear Interpolation: ',...
'    - OK for PET, or realigned fMRI.'],...
['    B-spline Interpolation: ',...
'    - Better quality (but slower) interpolation/* \cite{thevenaz00a}*/, especially ',...
'      with higher degree splines.  Do not use B-splines when ',...
'      there is any region of NaN or Inf in the images. '],...
};
%------------------------------------------------------------------------
modulate = mnu('Modulation','modulate',{'No modulation','Modulation'},...
               {false,true});
modulate.val = {false};
modulate.help = {...
['This allows the spatiallly normalised images to be rescaled by the '...
 'Jacobian determinants of the deformations. '...
 'Note that the rescaling is only approximate for deformations generated '...
 'using smaller numbers of time steps.']};
%------------------------------------------------------------------------
nrm = branch('Create Warped','crt_warped',{ffields,data,modulate,K,interp});
nrm.prog = @spm_dartel_norm;
nrm.help = {...
['This allows spatially normalised images to be generated. '...
 'Note that voxel sizes and bounding boxes can not be adjusted, '...
 'and that there may be strange effects due to the boundary conditions used '...
 'by the warping.']};
%------------------------------------------------------------------------

%------------------------------------------------------------------------
data = files('Images','images','nifti',[1 Inf]);
data.help = {...
['Select the image(s) to be inverse normalised.  '...
 'These should be in alignment with the template image generated by the '...
 'warping procedure.']};
%------------------------------------------------------------------------
inrm = branch('Create Inverse Warped','crt_iwarped',{ffields,data,K,interp});
inrm.prog = @spm_dartel_invnorm;
inrm.help = {...
['Create inverse normalised versions of some image(s). '...
 'The image that is inverse-normalised should be in alignment with the '...
 'template (generated during the warping procedure). '...
 'Note that the results have the same dimensions as the "flow fields", '...
 'but are mapped to the original images via the affine transformations '...
 'in their headers.']};
%------------------------------------------------------------------------

%------------------------------------------------------------------------
job = repeat('DARTEL Tools','dartel',{initial,warp,nrm,inrm});
job.help = {...
['This toolbox is based around the "A Fast Diffeomorphic Registration '...
 'Algorithm" paper, submitted for '...
 'publication in NeuroImage. '...
 'The idea is to register images by computing a "flow field", '...
 'which can then be "exponentiated" to generate both forward and '...
 'backward deformations. '...
 'Currently, the software only works with images that have isotropic '...
 'voxels, identical dimensions and which are in approximate alignment '...
 'with each other. '...
 'One of the reasons for this is that the approach assumes circulant '...
 'boundary conditions, which makes modelling global rotations impossible. '...
 'Another reason why the images should be approximately aligned is because '...
 'there are interactions among the transformations that are minimised by '...
 'beginning with images that are already almost in register. '...
 'This problem would be alleviated by a time varying flow field, '...
 'but this would be computationally impractical.'],...
['Because of the limitations, images should first be imported. '...
 'This involves taking the seg_sn.mat files produced by the segmentation '...
 'code of SPM5, and writing out rigidly transformed versions of the images, '...
 'such that they are in as close alignment as possible with the tissue '...
 'probability maps (e.g. MNI space). '...
 'Rigidly transformed tissue class images can also be generated.'],...
['The next step is the registration itself.  This can involve matching '...
 'single images together, or it can involve the simultaneous registration '...
 'of e.g. GM with GM, WM with WM and 1-(GM+WM) with 1-(GM+WM). '...
 'This procedure begins by creating a mean of all the images, '...
 'which is used as an initial template. '...
 'Deformations from this template to each of the individual images '...
 'are computed, and the template is then re-generated by applying '...
 'the inverses of the deformations to the images and averaging. '... 
 'This procedure is repeated a number of times.'],...
['Finally, warped versions of the images (or other images that are '...
 'in alignment with them) can be generated. ']};

return;
%_______________________________________________________________________

%_______________________________________________________________________
function vf = vfiles_initial_import(job)
vf = {};
%_______________________________________________________________________

function run_dartel(job)
if isempty(job.template),
    spm_dartel_template(job);
else
    spm_dartel_run(job);
end;

