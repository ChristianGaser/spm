function [F,M,Cq,Cp,QE,Qp] = spm_eeg_invert_EBoptimise(AY,UL,opttype,Qp,Qe,Qe0)
%% function [F,M,Cq,Cp,QE,Qp] = spm_eeg_invert_EBoptimise(AY,UL,opttype,Qp,Qe,Qe0)
%% Empirical Bayes optimization of priors Qp and Qe to fit data AY based on lead fields UL
% AY concatenated dimension reduced trials of M/EEG data
% UL dimension reduced lead field
% Qp source level priors- where Qp{i}.q holds an eigenmode. So source covariance
%                        component is Qp{i}.q*Qp{i}.q'.
%                         Alternately Qp{i} could be full source covariance component
% Qe sensor noise prior
% Qe0 floor of noise power to signal power (posteiror estimate of sensor noise will always be at
% least this big)
% opttype- how to optimize 'ARD','GS' or 'REML' 


%% QE sensor noise posterior
%% Cp source level posterior (source by source variance)
%% F free energy
%% M MAP operator
%% Cq conditional variance
%% F free energy
%% Qp contains the posterior in same form as prior

% Copyright (C) 2010 Wellcome Trust Centre for Neuroimaging

% Gareth Barnes



if ~iscell(Qe),
    Qe={Qe};
end;



AYYA=AY*AY'; %% covariance over trials
Q0          = Qe0*trace(AYYA)*Qe{1}; %% fixed (min) level of sensor space variance
% Get source-level priors (using all subjects)
%--------------------------------------------------------------------------
j=1;
ploton=0;
if ploton,
    figure;
end;


[LQpL,Q,sumLQpL,QE,Cy,M,Cp,Cq,Lq]=spm_eeg_assemble_priors(UL,Qp,Qe,ploton);


if isfield(opttype{j},'GSopt'),
    % Greedy search over MSPs
    %% needs to work with sparse covariance matrices Qp{i}.q
    %------------------------------------------------------------------
    
    if isempty(AY),
        error('NEED AY for greedy search');
    end;
    if size(Q,2)<2,
        error('Prior is not in a form for greedy search (try REML instead)');
    end;
    
   
    MVB   = spm_mvb(AY,UL,[],Q,Qe,16);
    %%  THE VERSION BELOW IS MORE PEDESTRIAN BUT EASIER TO FOLLOW
    %  MVB_grb = spm_mvb_slow_grb( AY,UL,Q,QE,16,Q0 );
    
    Ne=length(Qe);
    QE=zeros(size(Qe{1}));
    for j=1:Ne,
        QE=QE+MVB.h(j)*Qe{j};
    end;
      
    Qcp           = Q*MVB.cp; %% mvb works with unity dipole moments so here they get scaled back up by priors
  
    qful=Qcp*Q';
    Qp=compact_form({qful});
    Qe={QE};
    F=max(MVB.F);
    [LQpL,Q,sumLQpL,QE,Csensor,M,Cp]=spm_eeg_assemble_priors(UL,Qp,Qe,ploton);
    Qp=compact_form({Cp});
    
    
end; %%GS

if  isfield(opttype{j},'ARDopt'),
    %% needs to work with sparse (svd decomposed) source covariance matrices
    Nn=size(AY,2); %% number of data samples used to make up covariance matrix  
    
    
    ardthresh=opttype{j}.ARDopt; %% 
    fprintf('ARD removing components less than 1/%3.2f max\n',ardthresh);
   
    %------------------------------------------------------------------
    
    %% SPM_SP_REML STARTS WITH EIGEN MODES Lq RATHER THAN FULL COV MATRICES
    [Cy,h,Ph,F0] = spm_sp_reml(AYYA,[],[Qe Lq],Nn);
    
    
    % Spatial priors (QP)
    %------------------------------------------------------------------
    % h provides the final weights of the hyperparameters
    Ne    = length(Qe);
    Np    = length(Qp);
    
    hp    = h(Ne + (1:Np));
    
    dropind=find(hp<max(hp)/ardthresh);
    fprintf('Removing %d of %d components\n',length(dropind),length(hp));
    hp(dropind)=0;
    keepind=find(hp>max(hp)/ardthresh);
    
    h=[h(1:Ne) hp(keepind)'];
    
    [LQpL,Q,sumLQpL,QE,Csensor,M,Cp,Cq,Lq]=spm_eeg_assemble_priors(UL,Qp(keepind),Qe,ploton,h);
    [Cy,h2,Ph,F] = spm_sp_reml(AYYA,[],[Qe Lq],Nn);
    [LQpL,Q,sumLQpL,QE,Csensor,M,Cp,Cq,Lq]=spm_eeg_assemble_priors(UL,Qp(keepind),Qe,ploton,h2);
    % Accumulate empirical priors (New set of patches for the second inversion)
    fprintf('ARD improvement %3.2f\n',F-F0);
    Qp=compact_form({Cp});
    
end; % ARD

if  isfield(opttype{j},'REMLopt'),
    %  ReML: can work with both full and sparse source covariances
    %------------------------------------------------------------------
    Nn=size(AY,2); %% number of data samples used to make up covariance matrix
    
    %%% NOW OPTMIZE MIXTURE OF PRIOR COVARIANCE COMPS WITH REML
    
    [Cy,h,Ph,F] = spm_reml_sc(AYYA,[],[Qe LQpL],Nn,-4,16,Q0);
    
    
    %% Now convert the original priors to scaled versions of themselves
    [LQpL,Q,sumLQpL,QE,Csensor,M,QP]=spm_eeg_assemble_priors(UL,Qp,Qe,ploton,h);
    
    
    %% THIS NEXT LINE IS JUST A CHECK THAT THE POSTERIORS WORK AS PRIORS F2 should be greater or equal to F
    
    [Cy2,h2,Ph2,F2] = spm_reml_sc(AYYA,[],[{QE} {sumLQpL}],Nn,-4,16,Q0);
    
    if F2<F,
        error('something wrong here');
    end;
    
    
    Qp=compact_form({Cp});
    
    
    
end; %% REML opt




% re-do ReML (with informative hyperpriors)
%----------------------------------------------------------------------




 







function [Qp,Q]=compact_form(QP)


if isfield(QP{1},'q'),
    for j=1:length(QP),
        v=1;
        if isfield(QP{j},'v'),
            v=QP{j}.v;
        end;
        Q(:,j)=QP{j}.q*sqrt(v);
        Qp{j}.q=Q(:,j);
    end;
    disp('already sparse, returning');
    return;
end;
    
if length(QP)>1,
    error('only for single cells');
end;

[q,v] = spm_svd(QP{1});

if size(v,1)==size(QP{1},1),
    disp('Cannot sparsify returning full cov matrix');
    Qp=QP;
    return
end;

Q=q*sqrt(v); %% eigen vector

for i=1:size(Q,2),
    Qp{i}.q=Q(:,i);
end;
return;

