function varargout = cfg_util(cmd, varargin)

% This is the command line interface to the batch system. It manages the
% following structures:
% * Generic configuration structure c0. This structure will be initialised
%   to an cfg_repeat with empty .values list. Each application should
%   provide an application-specific master configuration file, which
%   describes the executable module(s) of an application and their inputs.
%   This configuration will be rooted directly under the master
%   configuration node. In this way, modules of different applications can
%   be combined with each other.
%   CAVE: the root nodes of each application must have an unique tag -
%   cfg_util will refuse to add an application which has a root tag that is
%   already used by another application.
% * Job specific configuration structure cj. This structure contains the
%   modules to be executed in a job, their input arguments and
%   dependencies between them. The layout of cj is not visible to the user.
% To address executable modules and their input values, cfg_util will
% return id(s) of unspecified type. If necessary, these id(s) should be
% stored in cell arrays in a calling application, since their internal
% format may change.
% Currently, cfg_util is not re-entrant, because a new call to
% cfg_util('initjob') will clear its previous cj or even c0. This means,
% that a job can not run another job since the original job would be lost.
%
% The commands to manipulate these structures are described below in
% alphabetical order.
%
%  cfg_util('addapp', cfg[, def])
%
% Add an application to cfg_util. If cfg is a cfg_item, then it is used
% as initial configuration. Alternatively, if cfg is a MATLAB function,
% this function is evaluated. The return argument of this function must be
% a single variable containing the full configuration tree of the
% application to be batched.
% Optionally, a defaults configuration struct or function can be supplied.
% This function must return a single variable containing a (pseudo) job
% struct/cell array which holds defaults values for configuration items.
% These defaults should be rooted at the application's root node, not at
% the overall root node. They will be inserted by calling initialise on the
% application specific part of the configuration tree.
%
%  mod_job_id = cfg_util('addtojob', mod_cfg_id)
%
% Append module with id mod_cfg_id in the cfg tree to current job. Returns
% a mod_job_id, which can be passed on to other functions that modify the
% module in the job.
%
%  [mod_job_idlist new2old_id] = cfg_util('compactjob')
%
% Modifies the internal representation of a job by removing deleted modules
% from the job configuration tree. This will invalidate all mod_job_ids and
% generate a new mod_job_idlist.
% A translation table new2old_id is provided, where 
% 
%    mod_job_idlist = old_mod_job_idlist{new2old_id}
%
% translates between an old id list and the compact new id list.
%
%  cfg_util('delfromjob', mod_job_id)
%
% Delete a module from a job.
%
%  cfg_util('deljob', job_id)
%
% Delete job with job_id from the job list. 
%
%  cfg_util('gencode', fname, apptag|cfg_id[, tropts])
%
% Generate code from default configuration structure, suitable for
% recreating the tree structure. Note that function handles may not be
% saved properly. By default, the entire tree is saved into a file fname.
% If tropts is given as a traversal option specification, code generation
% will be split at the nodes matching tropts.stopspec. Each of these nodes will
% generate code in a new file with filename fname_<tag of node>, and the
% nodes up to tropts.stopspec will be saved into fname.
%
%  job_id = cfg_util('getcjob')
%
% Get job_id of current job.
%
%  [tag val] = cfg_util('harvest'[, mod_job_id])
%
% Harvest is a method defined for all 'cfg_item' objects. It collects the
% entered values and dependencies of the input items in the tree and
% assembles them in a struct/cell array.
% If no mod_job_id is supplied, the internal configuration tree will be
% cleaned up before harvesting. Dependencies will not be resolved in this
% case. The internal state of cfg_util is not modified in this case. The
% structure returned in val may be saved to disk as a job and can be loaded
% back into cfg_util using the 'init' command.
% If a mod_job_id is supplied, only the relevant part of the configuration
% tree is harvested, dependencies are resolved and the internal state of
% cfg_util is updated. In this case, the val output is only part of a job
% description and can not be loaded back into cfg_util.
%
%  [tag appdef] = cfg_util('harvestdef'[, apptag|cfg_id])
%
% Harvest the defaults branches of the current configuration tree. If
% apptag is supplied, only the subtree of that application whose root tag
% matches apptag/whose id matches cfg_id is harvested. In this case,
% appdef is a struct/cell array that can be supplied as a second argument
% in application initialisation by cfg_util('addapp', appcfg,
% appdef). 
% If no application is specified, defaults of all applications will be
% returned in one struct/cell array. 
% 
%  cfg_util('initcfg')
%
% Initialise cfg_util configuration. All currently added applications and
% jobs will be cleared.
% Initial application data will be initialised to a combination of
% cfg_mlbatch_appcfg.m files in their order found on the MATLAB path. Each
% of these config files should be a function that (optionally) adds a path
% to a configuration file and calls cfg_util('addapp',...) with an
% application configuration. These files are executed in the order they are
% found on the MATLAB path with the one first found taking precedence over
% following ones.
%
%  cfg_util('initdef', apptag|cfg_id, def)
%
% Set default values for application specified by apptag or cfg_id. Def
% can be any representation of a defaults job as returned by
% cfg_util('harvestdef', apptag|cfg_id), i.e. a MATLAB variable, a
% function creating this variable...
% New defaults only apply to modules added to a job after the defaults
% have been loaded. Saved jobs and modules already present in the current
% job will not be changed.
%
%  [job_id mod_job_idlist] = cfg_util('initjob'[, job])
%
% Initialise a new job. 
% If job is given as input argument, the job tree structure will be
% loaded with data from the struct/cell array job and a cell list of job
% ids will be returned. Otherwise, a new job without modules will be
% created.
% The new job will be appended to an internal list of jobs. Other
% cfg_util commands will always operate on the current job. To make
% another job current or delete a job, use cfg_util('setcjob',...) and
% cfg_util('delcjob',...) resp.
%
%  sts = cfg_util('ismod_cfg_id', mod_cfg_id)
%  sts = cfg_util('ismod_job_id', mod_job_id)
%  sts = cfg_util('isitem_mod_id', item_mod_id)
% Test whether the supplied id seems to be of the queried type. Returns
% true if the id matches the data format of the queried id type, false
% otherwise. No checks are performed whether the id is really valid
% (i.e. points to an item in the configuration structure). This can be
% used to decide whether 'list*' or 'tag2*' callbacks returned valid ids.
%
%  [mod_cfg_idlist stop [contents]] = cfg_util('listcfg[all]', mod_cfg_id, find_spec[, fieldnames])
%
% List modules with the specified contents in the cfg tree, starting at
% mod_cfg_id. If mod_cfg_id is empty, search will start at the root level
% of the tree. The returned mod_cfg_id_list is always relative to the root
% level of the tree, not to the mod_cfg_id of the start item. This search
% is designed to stop at cfg_exbranch level. Its behaviour is undefined if
% mod_cfg_id points to an item within an cfg_exbranch. See 'match' and
% 'cfg_item/find' for details how to specify find_spec. A cell list of
% matching modules is returned.
% If the 'all' version of this command is used, also matching
% non-cfg_exbranch items up to the first cfg_exbranch are returned. This
% can be used to build a menu system to manipulate configuration.
% If a cell array of fieldnames is given, contents of the specified fields
% will be returned. See 'cfg_item/list' for details. This callback is not
% very specific in its search scope. To find a cfg_item based on the
% sequence of tags of its parent items, use cfg_util('tag2mod_cfg_id',
% tagstring) instead.
%
%  [item_mod_idlist stop [contents]] = cfg_util('listmod', mod_job_id, item_mod_id, find_spec[, tropts][, fieldnames])
%  [item_mod_idlist stop [contents]] = cfg_util('listmod', mod_cfg_id, item_mod_id, find_spec[, tropts][, fieldnames])
%
% Find configuration items starting in module mod_job_id in the current
% job or in module mod_cfg_id in the defaults tree, starting at item
% item_mod_id. If item_mod_id is an empty array, start at the root of a
% module. By default, search scope are the filled items of a module. See
% 'match' and 'cfg_item/find' for details how to specify find_spec and
% tropts and how to search the default items instead of the filled ones. A
% cell list of matching items is returned.
% If a cell array of fieldnames is given, contents of the specified fields
% will be returned. See 'cfg_item/list' for details.
%
%  sts = cfg_util('match', mod_job_id, item_mod_id, find_spec)
%
% Returns true if the specified item matches the given find spec and false
% otherwise. An empty item_mod_id means that the module node itself should
% be matched.
%
%  new_mod_job_id = cfg_util('replicate', mod_job_id)
%
% Replicate a module by appending it to the end of the job list.
% The values of all items will be copied. This is in contrast to
% 'addtojob', where a module is added with default settings. 
% Dependencies where this module is a target will be kept, whereas source
% dependencies will be dropped from the copied module.
%
%  cfg_util('replicate', mod_job_id, item_mod_id, val)
%
% If item_mod_id points to a cfg_repeat object, its setval method is called
% with val. To achieve replication, val(1) must be finite and negative, and
% val(2) must be the index into item.val that should be replicated. All
% values are copied to the replicated entry.
%
%  cfg_util('run'[, job|job_id])
%
% Run the currently configured job. If job is supplied as argument and is
% a harvested job, then cfg_util('initjob', job) will be called first. If
% job_id is supplied and is a valid job_id, the job with this job id will
% be run.
%
% The job is harvested and dependencies are resolved if possible. All
% modules without unresolved dependencies will be run in arbitrary order.
% Then the remaining modules are harvested again and run, if their
% dependencies can be resolved. This process is iterated until no modules
% are left or no more dependencies can resolved. In a future release,
% independent modules may run in parallel, if there are licenses to the
% Distributed Computing Toolbox available.
% Note that this requires dependencies between modules to be described by
% cfg_dep objects. If a module e.g. relies on file output of another module
% and this output is already specified as a filename of a non-existent
% file, then the dependent module may be run before the file is created.
% If a module fails to execute, computation will continue on modules that
% do not depend on this module. An error message will be logged and the
% module will be reported as 'failed to run' in the MATLAB command window.
%
%  cfg_util('runserial'[, job])
%
% Like 'run', but force cfg_util to run the job as if each module was
% dependent of its predecessor.
%
%  cfg_util('savejob', filename)
%
% The current job will be save to the .m file specified by filename. This
% .m file contains MATLAB script code to recreate the job variable. It is
% based on gencode (part of this MATLAB batch system) for all standard
% MATLAB types. For objects to be supported, they must implement their own
% gencode method.
%
%  job_id = cfg_util('setcjob', job_id)
%
% Set the current job to the specified job_id. If this id is not valid, then
% the last job in the job list will be made current.
%
%  sts = cfg_util('setval', mod_job_id, item_mod_id, val)
%
% Set the value of item item_mod_id in module mod_job_id to val. If item is
% a cfg_choice, cfg_repeat or cfg_menu and val is numeric, the value will
% be set to item.values{val(1)}. If item is a cfg_repeat and val is a
% 2-vector, then the min(val(2),numel(item.val)+1)-th value will be set
% (i.e. a repeat added or replaced). If val is an empty cell, the value of
% item will be cleared.
% sts returns the status of all_set_item after the value has been
% set. This can be used to check whether the item has been successfully
% set.
% Once editing of a module has finished, the module needs to be harvested
% in order to update dependencies from and to other modules.
%
%  cfg_util('setdef', mod_cfg_id, item_mod_id, val)
% 
% Like cfg_util('setval',...) but set items in the defaults tree. This is
% only supported for cfg_leaf items, not for cfg_choice, cfg_repeat,
% cfg_branch items.
%
%  [mod_job_idlist str sts dep sout] = cfg_util('showjob'[, mod_job_idlist])
%
% Return information about the current job (or the part referenced by the
% input cell array mod_job_idlist). Output arguments
% * mod_job_idlist - cell list of module ids (same as input, if provided)
% * str            - cell string of names of modules 
% * sts            - array of all set status of modules
% * dep            - array of dependency status of modules
% * sout           - array of output description structures 
% Each module configuration may provide a callback function 'vout' that
% returns a struct describing module output variables. See 'cfg_exbranch'
% for details about this callback, output description and output structure.
% The module needs to be harvested before to make output_struct available.
% This information can be used by the calling application to construct a
% dependency object which can be passed as input to other modules. See
% 'cfg_dep' for details about dependency objects.
%
%  [mod_cfg_id item_mod_id] = cfg_util('tag2cfg_id', tagstr)
%
% Return a mod_cfg_id for the cfg_exbranch item that is the parent to the
% item in the configuration tree whose parents have tag names as in the
% dot-delimited tag string. item_mod_id is relative to the cfg_exbranch
% parent. If tag string matches a node above cfg_exbranch level, then
% item_mod_id will be invalid and mod_cfg_id will point to the specified
% node.
% Use cfg_util('ismod_cfg_id') and cfg_util('isitem_mod_id') to determine
% whether returned ids are valid or not.
% Tag strings should begin at the root level of an application configuration, 
% not at the matlabbatch root level.
%
%  mod_cfg_id = cfg_util('tag2mod_cfg_id', tagstr)
%
% Same as cfg_util('tag2cfg_id', tagstr), but it only returns a proper
% mod_cfg_id. If none of the tags in tagstr point to a cfg_exbranch, then
% mod_cfg_id will be invalid.
%
% The layout of the configuration tree and the types of configuration items
% have been kept compatible to a configuration system and job manager
% implementation in SPM5 (Statistical Parametric Mapping, Copyright (C)
% 2005 Wellcome Department of Imaging Neuroscience). This code has been
% completely rewritten based on an object oriented model of the
% configuration tree.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: cfg_util.m 1246 2008-03-26 10:45:13Z volkmar $

rev = '$Rev: 1246 $';

%% Initialisation of cfg variables
% load persistent configuration data, initialise if necessary

% generic configuration structure
persistent c0;
% job specific configuration structure
% This will be initialised to a struct (array) with fields cj and
% id2subs. When initialising a new job, it will be appended to this
% array. Jobs in this array may be cleared by setting cj and id2subs to
% [].
% field cj:
% configuration tree of this job.
% field cjid2subs:
% cell array that maps ids to substructs into the configuration tree -
% ids do not change for a cfg_util life time, while the actual position
% of a module in cj may change due to adding/removing modules. This would
% also allow to reorder modules in cj without changing their id.
persistent jobs;
% index of current job in jobs.
persistent cjob;

if isempty(c0) && ~strcmp(cmd,'initcfg')
    % init, if not yet done
    cfg_util('initcfg');
end;

%% Callback switches
% evaluate commands
switch lower(cmd),
    case 'addapp',
        [c0 jobs] = local_addapp(c0, jobs, varargin{:});
    case 'addtojob',
        [jobs(cjob), id] = local_addtojob(c0, jobs(cjob), varargin{:});
        varargout{1} = id;
    case 'compactjob',
        [jobs(cjob), n2oid] = local_compactjob(jobs(cjob));
        varargout{1} = mat2cell(1:numel(jobs(cjob).cjid2subs), 1, ones(1,numel(jobs(cjob).cjid2subs)));
        varargout{2} = n2oid;
    case 'deljob',
        if varargin{1} == numel(jobs) && varargin{1} > 1
            jobs = jobs(1:end-1);
        else
            jobs(varargin{1}).cj = c0;
            jobs(varargin{1}).cjid2subs = {};
        end;
        if cjob == varargin{1}
            cjob = numel(jobs);
        end;
    case 'delfromjob',
        jobs(cjob) = local_delfromjob(jobs(cjob), varargin{:});
    case 'gencode',
        fname = varargin{1};
        cm = local_getcm(c0, varargin{2});
        if nargin > 3
            tropts = varargin{3};
        else
            % default for SPM5 menu structure
            tropts = cfg_tropts(cfg_findspec, 1, 2, 0, Inf, true);
        end;
        local_gencode(cm, fname, tropts);
    case 'getcjob',
        varargout{1} = cjob;
    case 'harvest',
        if nargin == 1
            % harvest entire job
            % do not resolve dependencies
            cj1 = local_compactjob(jobs(cjob));
            [tag val] = harvest(cj1.cj, cj1.cj, false, false);
        else
            [tag val u3 u4 u5 jobs(cjob).cj] = harvest(subsref(jobs(cjob).cj, ...
                                                              jobs(cjob).cjid2subs{varargin{1}}), ...
                                                       jobs(cjob).cj, false, true);
        end;
        varargout{1} = tag;
        varargout{2} = val;
    case 'harvestdef',
        if nargin == 1
            % harvest all applications
            cm = c0;
        else
            cm = local_getcm(c0, varargin{1});
        end;
        [tag defval] = harvest(cm, cm, true, false);
        varargout{1} = tag;
        varargout{2} = defval;
    case 'initcfg',
        [c0 jobs cjob] = local_initcfg;
        local_initapps;
    case 'initdef',
        cm = local_getcm(c0, varargin{1});
        cm = local_initdef(cm, varargin{2});
        c0 = subsasgn(c0, id{1}, cm);
    case 'initjob'
        if isempty(jobs(end).cjid2subs)
            cjob = numel(jobs);
        else
            cjob = numel(jobs)+1;
        end;
        if nargin == 1
            jobs(cjob).cj =c0;
            jobs(cjob).cjid2subs = {};
            varargout{1} = cjob;
            varargout{2} = {};
            return;
        elseif iscellstr(varargin{1})
            job = {};
            for k = 1:numel(varargin{1})
                [p jobfun e v] = fileparts(varargin{1}{k});
                switch e,
                    case '.m',
                        job{end+1} = local_eval(jobfun,p);
                    case '.mat'
                        tmp = load(varargin{1}{k});
                        if isfield(tmp,'matlabbatch')
                            job{end+1} = tmp.matlabbatch;
                        else
                            error('matlabbatch:initjob:loadmat', 'Load failed.');
                        end;
                end;
            end;
        else
            % try to initialise single job
            job{1} = varargin{1};
        end;
        [jobs(cjob) mod_job_idlist] = local_initjob(c0, job);
        varargout{1} = cjob;
        varargout{2} = mod_job_idlist;
    case 'isitem_mod_id'
        varargout{1} = isstruct(varargin{1}) && ...
            all(isfield(varargin{1}, {'type','subs'}));
    case 'ismod_cfg_id'
        varargout{1} = isstruct(varargin{1}) && ...
            all(isfield(varargin{1}, {'type','subs'}));
    case 'ismod_job_id'
        varargout{1} = isnumeric(varargin{1}) && ...
            varargin{1} <= numel(jobs(cjob).cjid2subs) ...
            && ~isempty(jobs(cjob).cjid2subs{varargin{1}});
    case {'listcfg','listcfgall'}
        % could deal with hidden/modality fields here
        if strcmpi(cmd(end-2:end), 'all')
            exspec = cfg_findspec({});
        else
            exspec = cfg_findspec({{'class','cfg_exbranch'}});
        end;
        % Stop traversal at hidden flag
        % If user input find_spec contains {'hidden',false}, then a hidden
        % node will not match and will not be listed. If a hidden node
        % matches, it will return with a stop-flag set.
        tropts = cfg_tropts({{'class','cfg_exbranch','hidden',true}}, 1, Inf, 0, Inf, true);
        % Find start node
        if isempty(varargin{1})
            cs = c0;
            sid = [];
        else
            cs = subsref(c0, varargin{1});
            sid = varargin{1};
        end;
        if nargin < 4
            [id stop] = list(cs, [varargin{2} exspec], tropts);
            for k=1:numel(id)
                id{k} = [sid id{k}];
            end;
            varargout{1} = id;
            varargout{2} = stop;
        else
            [id stop val] = list(cs, [varargin{2} exspec], tropts, varargin{3});
            for k=1:numel(id)
                id{k} = [sid id{k}];
            end;
            varargout{1} = id;
            varargout{2} = stop;
            varargout{3} = val;
        end;
    case 'listmod'
        % could deal with hidden/modality fields here
        if cfg_util('ismod_job_id', varargin{1})
            if isempty(varargin{2})
                cm = subsref(jobs(cjob).cj, jobs(cjob).cjid2subs{varargin{1}});
            else
                cm = subsref(jobs(cjob).cj, [jobs(cjob).cjid2subs{varargin{1}} varargin{2}]);
            end;
        else
            if isempty(varargin{2})
                cm = subsref(c0, varargin{1});
            else
                cm = subsref(c0, [varargin{1} varargin{2}]);
            end;
        end;
        findspec = varargin{3};
        if (nargin > 4 && isstruct(varargin{4})) || nargin > 5
            tropts = varargin{4};
        else
            tropts = cfg_tropts({{'hidden',true}}, 1, Inf, 0, Inf, false);
        end;
        if (nargin > 4 && iscellstr(varargin{4}))
            fn = varargin{4};
        elseif nargin > 5
            fn = varargin{5};
        else
            fn = {};
        end;
        if isempty(fn)
            [id stop] = list(cm, findspec, tropts);
            varargout{1} = id;
            varargout{2} = stop;
        else
            [id stop val] = list(cm, findspec, tropts, fn);
            varargout{1} = id;
            varargout{2} = stop;
            varargout{3} = val;
        end
    case 'match'
        if isempty(varargin{2})
            cm = subsref(jobs(cjob).cj, jobs(cjob).cjid2subs{varargin{1}});
        else
            cm = subsref(jobs(cjob).cj, [jobs(cjob).cjid2subs{varargin{1}} varargin{2}]);
        end;
        varargout{1} = match(cm, varargin{3});
    case 'replicate'
        if nargin == 2
            % replicate module
            [jobs(cjob) id] = local_replmod(jobs(cjob), varargin{1});
        elseif nargin == 4
            % replicate val entry of cfg_repeat, use setval with sanity
            % check
            cm = subsref(jobs(cjob).cj, [jobs(cjob).cjid2subs{varargin{1}}, varargin{2}]);
            if isa(cm, 'cfg_repeat')
                cm = setval(cm, varargin{3});
                jobs(cjob).cj = subsasgn(jobs(cjob).cj, ...
                                         [jobs(cjob).cjid2subs{varargin{1}}, varargin{2}], cm);
            end;
        end;
    case {'run','runserial'}
        rjob = cjob;
        dflag = false;
        if nargin > 1
            if isstruct(varargin{1})
                rjob = cfg_util('initjob',varargin{1});
                dflag = true;
            else
                rjob = varargin{1};
            end;
        end;
        if strcmpi(cmd, 'run')
            jobrun = local_runcj(jobs(rjob), false);
        else
            jobrun = local_runcj(jobs(rjob), true);
        end;
        if dflag
            cfg_util('deljob', rjob);
        end;
    case 'savejob'
        sjob = local_compactjob(jobs(cjob));
        [tag job] = harvest(sjob.cj, sjob.cj, false, false);
        jobstr = gencode(job, tag);
        [p n e v] = fileparts(varargin{1});
        fid = fopen(fullfile(p, [n '.m']),'w');
        fprintf(fid, '%%-----------------------------------------------------------------------\n');
        fprintf(fid, '%% Job configuration created by %s (rev %s)\n', mfilename, rev);
        fprintf(fid, '%%-----------------------------------------------------------------------\n');
        for k = 1:numel(jobstr)
            fprintf(fid, '%s\n', jobstr{k});
        end;
        fclose(fid);
    case 'setcjob',
        cjob = min(numel(jobs), varargin{1});
    case 'setdef',
        cm = subsref(c0, [varargin{1}, varargin{2}]);
        cm = setval(cm, varargin{3});
        c0 = subsasgn(c0, [varargin{1}, varargin{2}], cm);
    case 'setval',
        cm = subsref(jobs(cjob).cj, [jobs(cjob).cjid2subs{varargin{1}}, varargin{2}]);
        cm = setval(cm, varargin{3});
        jobs(cjob).cj = subsasgn(jobs(cjob).cj, [jobs(cjob).cjid2subs{varargin{1}}, varargin{2}], cm);
        varargout{1} = all_set_item(cm);
    case 'showjob',
        if nargin > 1
            id = varargin{1};
            [unused str sts dep sout] = local_showjob(jobs(cjob).cj, ...
                                                      subsref(jobs(cjob).cjid2subs, ...
                                                              substruct('{}', varargin{1})));
        else
            [id str sts dep sout] = local_showjob(jobs(cjob).cj, jobs(cjob).cjid2subs);
        end;
        varargout{1} = id;
        varargout{2} = str;
        varargout{3} = sts;
        varargout{4} = dep;
        varargout{5} = sout;
    case 'tag2cfg_id',
        [mod_cfg_id item_mod_id] = local_tag2cfg_id(c0, varargin{1}, ...
                                                        true);
        if iscell(mod_cfg_id)
            % don't force mod_cfg_id to point to cfg_exbranch
            mod_cfg_id = local_tag2cfg_id(c0, varargin{1}, false);
        end;
        varargout{1} = mod_cfg_id;
        varargout{2} = item_mod_id;
    case 'tag2mod_cfg_id',
        varargout{1} = local_tag2cfg_id(c0, varargin{1}, true);
    otherwise
        error('matlabbatch:cfg_util:unknown', 'Unknown command ''%s''.', cmd);
end;
return;

%% Local functions
% These are the internal implementations of commands.
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [c0 jobs] = local_addapp(c0, jobs, cfg, varargin)
% Add configuration data to c0 and all jobs
% Input
% * cfg - Function name, function handle or cfg_item tree. If a
%         function is passed, this will be evaluated with no arguments and
%         must return a single configuration tree.
% * def - Optional. Function name, function handle or defaults struct/cell.
%         This function should return a job struct suitable to initialise
%         the defaults branches of the cfg tree.

if subsasgn_check_funhandle(cfg)
    c1 = feval(cfg);
elseif isa(cfg, 'cfg_item')
    c1 = cfg;
else
    error('matlabbatch:cfg_util:addappcfg','Invalid configuration');
end;
for k = 1:numel(c0.values)
    if strcmp(c1.tag, c0.values{k}.tag)
        error('matlabbatch:cfg_util:addappdup',...
              'Duplicate application tag in applications ''%s'' and ''%s''.', ...
              c1.name, c0.values{k}.name);
    end;
end;
if nargin > 3
    c1 = local_initdef(c1, varargin{1});
end;
fprintf('%s: Added application ''%s''\n', mfilename, c1.name);
c0.values{end+1} = c1;
for k = 1:numel(jobs)
    jobs(k).cj.values{end+1} = c1;
end;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [job, id] = local_addtojob(c0, job, c0subs)
% Add module subsref(c0, c0subs) to job.cj, append its subscript to
% job.cjid2subs and return the index into job.cjid2subs to the caller.
% The module will be added in a 'degenerated' branch of a cfg tree, where
% it is the only exbranch that can be reached on the 'val' path.
id = numel(job.cj.val)+1;
cjsubs = c0subs;
for k = 1:2:numel(cjsubs)
    % assume subs is [.val(ues){X}]+ and there are only choice/repeats
    % above exbranches
    % replace values{X} with val{1} in '.' references
    if strcmp(cjsubs(k).subs, 'values')
        cjsubs(k).subs = 'val';
        if k == 1
            % set id in cjsubs(2)
            cjsubs(k+1).subs = {id};
        else
            cjsubs(k+1).subs = {1};
        end;
    end;
    % add path to module to cj
    job.cj = subsasgn(job.cj, cjsubs(1:(k+1)), subsref(c0, c0subs(1:(k+1))));
end;
% set id in module    
job.cj = subsasgn(job.cj, [cjsubs substruct('.', 'id')], cjsubs);
job.cjid2subs{id} = cjsubs;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [job n2oid] = local_compactjob(ojob)
% Remove placeholders from cj and recursively update dependencies to fit
% new ids. Warning: this will invalidate mod_job_ids!

job.cj = ojob.cj;
job.cj.val = {};
job.cjid2subs = {};

oid = {};
nid = 1;
n2oid = [];
for k = 1:numel(ojob.cjid2subs)
    if ~isempty(ojob.cjid2subs{k})
        cjsubs = ojob.cjid2subs{k};
        oid{nid} = ojob.cjid2subs{k};
        cjsubs(2).subs = {nid};
        job.cjid2subs{nid} = cjsubs;
        for l = 1:2:numel(cjsubs)
            % subs is [.val(ues){X}]+
            % add path to module to cj
            job.cj = subsasgn(job.cj, job.cjid2subs{nid}(1:(l+1)), ...
                          subsref(ojob.cj, ojob.cjid2subs{k}(1:(l+1))));
        end;
        n2oid(nid) = k;
        nid = nid + 1;
    end;
end;
job.cj = update_deps(job.cj, oid, job.cjid2subs);
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function job = local_delfromjob(job, id)
% Remove module subsref(job.cj, job.cjid2subs{id}) from job.cj. All
% target and source dependencies between the module and other modules in
% job.cj are removed. Corresponding entries in job.cj and job.cjid2subs
% are set to {} in order to keep relationships within the tree consistent
% and in order to keep other ids valid. A rebuild of job.cj and an update
% of changed subsrefs would be possible (and needs to be done before
% e.g. saving the job). 
if isempty(job.cjid2subs) || isempty(job.cjid2subs{id}) || numel(job.cjid2subs) < id
    warning('matlabbatch:cfg_util:local_delfromjob:invid', ...
            'Invalid id %d.', id);
    return;
end;
cm = subsref(job.cj, job.cjid2subs{id});
if ~isempty(cm.tdeps)
    job.cj = del_in_source(cm.tdeps, job.cj);
end;
if ~isempty(cm.sdeps)
    job.cj = del_in_target(cm.sdeps, job.cj);
end;
% replace module with placeholder
cp = cfg_const;
cp.tag = 'deleted_item';
cp.val = {''};
cp.hidden = true;
% replace deleted module at top level, not at branch level
job.cj = subsasgn(job.cj, job.cjid2subs{id}(1:2), cp);
job.cjid2subs{id} = struct([]);
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function matlabbatch = local_eval(varargin)
% Evaluate a matlab expression or script
opwd = pwd;
try
    cd(varargin{2});
    eval(varargin{1});
    if ~exist('matlabbatch', 'var')
        try
            matlabbatch = eval(varargin{1});
        end;
    end;
    cd(opwd);
catch
    cd(opwd);
    error('cfg_util:initjob:local_eval', 'Load failed.');
end;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function local_gencode(c0, fname, tropts)
% Generate code, split at nodes matching stopspec (if stopspec is not
% empty). fname will be overwritten if tropts is empty (i.e. for single
% file output or subtrees). Note that some manual fixes may be required
% (function handles, variable/function names).
if isempty(tropts)
    tropts(1).clvl = 1;
    tropts(1).mlvl = Inf;
    tropts(1).cnt  = 1;
    [p funcname e v] = fileparts(fname);
    [cstr tag] = gencode(c0, '', funcname, tropts);
    funcname = [funcname '_' tag];
    fname = fullfile(p, [funcname e v]);
    unpostfix = '';
    while exist(fname, 'file')
        warning('matlabbatch:cfg_util:gencode:fileexist', ...
                ['While generating code for cfg_item: ''%s'', %s. File ' ...
                 '''%s'' already exists. Trying new filename - you will ' ...
                 'need to adjust generated code.'], ...
                c0.name, tag, fname);
        unpostfix = [unpostfix '1'];
        fname = fullfile(p, [funcname unpostfix e v]);
    end;
    fid = fopen(fname,'w');
    fprintf(fid, 'function %s = %s\n', tag, funcname);
    for k = 1:numel(cstr)
        fprintf(fid, '%s\n', cstr{k});
    end;
    fclose(fid);
else
    % generate root level code
    [p funcname e v] = fileparts(fname);
    [cstr tag] = gencode(c0, 'jobs', funcname, tropts);
    fid = fopen(fname,'w');
    fprintf(fid, 'function %s = %s\n', tag, funcname);
    for k = 1:numel(cstr)
        fprintf(fid, '%s\n', cstr{k});
    end;
    fclose(fid);
    % generate subtree code - find nodes one level below stop spec
    tropts.mlvl = tropts.mlvl+1;
    [ids stop] = list(c0, tropts.stopspec, tropts);
    ids = ids(stop); % generate code for stop items only
    tropts = cfg_tropts;
    for k = 1:numel(ids)
        if ~isempty(ids{k}) % don't generate root level code again
            local_gencode(subsref(c0, ids{k}), fname, tropts);
        end;
    end;
end;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [cj cjid2subs] = local_getcjid2subs(cjin)
% Find ids of exbranches. 
% find ids
exspec = cfg_findspec({{'class', 'cfg_exbranch'}});
tropts = cfg_tropts({{'class', 'cfg_exbranch'}}, 1, Inf, 0, Inf, false);
cjid2subsin = list(cjin, exspec, tropts);
cjid2subs = cjid2subsin;
cj = cjin;
cj.val = {};
% canonicalise SPM5 batches to cj.val{X}.val{1}....val{1}
% This would break dependencies, but in SPM5 batches there should not be any
for k = 1:numel(cjid2subs)
    % assume subs is [.val{X}]+ and there are only choice/repeats
    % above exbranches
    for l = 2:2:numel(cjid2subs{k})
        if l == 2
            cjid2subs{k}(l).subs = {k};
        else
            cjid2subs{k}(l).subs = {1};
        end;
        % add path to module to cj
        cpath = subsref(cjin, cjid2subsin{k}(1:l));
        % clear val field for nodes below exbranch
        if l < numel(cjid2subs{k})
            cpath.val = {};
        end;
        cj = subsasgn(cj, cjid2subs{k}(1:l), cpath);
    end;
    % set ids in exbranches
    cj = subsasgn(cj, [cjid2subs{k} substruct('.', 'id')], cjid2subs{k});
end;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function cm = local_getcm(c0, cfg_id)
% This code could use tag2cfg_id
if cfg_util('ismod_cfg_id', cfg_id)
    % This should better test something like 'iscfg_id'
    id{1} = cfg_id;
else
    % find application root
    root = cfg_findspec({{'tag',cfg_id}});
    tropts = cfg_tropts(cfg_findspec, 1, 2, 0, 1, true);
    [id stop] = list(c0, root, tropts);
    if numel(id) ~= 1 || isempty(id{1})
        error('matlabbatch:cfg_util:harvestdef', ...
              'Application with tag ''%s'' not found.', varargin{2});
    end;
end;
cm = subsref(c0, id{1});
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [c0 jobs cjob] = local_initcfg
% initial config
c0   = cfg_mlbatch_root;
cjob = 1;
jobs(cjob).cj        = c0;
jobs(cjob).cjid2subs = {};
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function c1 = local_initdef(c1, defspec)
if subsasgn_check_funhandle(defspec)
    opwd = pwd;
    if ischar(defspec)
        [p fn e v] = fileparts(defspec);
        cd(p);
        defspec = fn;
    end;
    def = feval(defspec);
    cd(opwd);
elseif isa(defspec, 'cell') || isa(defspec, 'struct')
    def = defspec;
else
    def = [];
end;
if ~isempty(def)
    c1 = initialise(c1, def, true);
end;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function local_initapps
% add application data
appcfgs = which('cfg_mlbatch_appcfg','-all');
cwd = pwd;
for k = 1:numel(appcfgs)
    % cd into directory containing config file
    [p n e v] = fileparts(appcfgs{k});
    cd(p);
    try
        feval('cfg_mlbatch_appcfg');
    catch
        try
            evalc('cfg_mlbatch_appcfg');
        catch
            warning('matlabbatch:initcfg:eval_appcfg', ...
                    'Failed to load %s', which('cfg_mlbatch_appcfg'));
            %            rethrow(lasterror);
        end;
    end;
end;
cd(cwd);
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [cjob mod_job_idlist] = local_initjob(c0, job)
% Initialise a cell array of jobs
for n = 1:numel(job)
    % init job
    cj1 = initialise(c0, job{n}, false);
    % canonicalise (this may break dependencies, see comment in
    % local_getcjid2subs)
    [cj1 cjid2subs1] = local_getcjid2subs(cj1);
    % harvest, keeping dependencies
    [u1 u2 u3 u4 u5 cj1] = harvest(cj1, cj1, false, false);
    if n == 1
        cjob.cj = cj1;
        cjob.cjid2subs = cjid2subs1;
    else
        cjidoffset = numel(cjob.cjid2subs);
        cjid2subs2 = cjid2subs1;
        for k = 1:numel(cjid2subs2)
            % update id subscripts
            cjid2subs2{k}(2).subs{1} = cjid2subs2{k}(2).subs{1} + cjidoffset;
            cj1 = subsasgn(cj1, [cjid2subs1{k}, substruct('.','id')], ...
                           cjid2subs2{k});
            % update src_exbranch in dependent cfg_items
            sdeps = subsref(cj1, [cjid2subs1{k}, substruct('.','sdeps')]);
            for l = 1:numel(sdeps)
                % dependent module
                dm = subsref(cj1, sdeps(l).tgt_exbranch);
                % delete old tdeps - needs to be updated by harvest
                dm.tdeps = [];
                % dependencies in dependent item
                ideps = subsref(dm, ...
                                [sdeps(l).tgt_input substruct('.','val','{}',{1})]);
                for m = 1:numel(ideps)
                    % find reference that matches old source id
                    if isequal(ideps(m).src_exbranch, cjid2subs1{k})
                        ideps(m).src_exbranch = cjid2subs2{k};
                    end;
                end;
                % save updated item
                dm = subsasgn(dm, ...
                              [sdeps(l).tgt_input substruct('.','val','{}',{1})], ...
                              ideps);
                % save updated module
                cj1 = subsasgn(cj1, sdeps(l).tgt_exbranch, dm);
            end;
            % done with sdeps - clear
            cj1 = subsasgn(cj1, [cjid2subs1{k}, substruct('.','sdeps')], []);
        end;
        % concatenate configs
        cjob.cjid2subs = {cjob.cjid2subs{:} cjid2subs2{:}};
        for k = 1:numel(cj1.val)
            cjob.cj.val{end+1} = cj1.val{k};
        end;
    end;
end;
% harvest, update dependencies
[u1 u2 u3 u4 u5 cjob.cj] = harvest(cjob.cj, cjob.cj, false, false);
mod_job_idlist = mat2cell(1:numel(cjob.cjid2subs),1,ones(1,numel(cjob.cjid2subs)));
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [job, id] = local_replmod(job, oid)
% Replicate module subsref(job.cj,job.cjid2subs{oid}) by adding it to the end of
% the job list. Update id in module and delete links to dependent modules,
% these dependencies are the ones of the original module, not of the
% replica.
id = numel(job.cj.val)+1;
% subsref of original module
ocjsubs = job.cjid2subs{oid};
% subsref of replica module
rcjsubs = ocjsubs;
rcjsubs(2).subs = {id};
for k = 1:2:numel(ocjsubs)
    % Add path to replica module, copying items from original path
    job.cj = subsasgn(job.cj, rcjsubs(1:(k+1)), subsref(job.cj, ocjsubs(1:(k+1))));
end;
% set id in module, delete copied sdeps and tdeps
job.cj = subsasgn(job.cj, [rcjsubs substruct('.', 'id')], rcjsubs);
job.cj = subsasgn(job.cj, [rcjsubs substruct('.', 'sdeps')], []);
job.cj = subsasgn(job.cj, [rcjsubs substruct('.', 'tdeps')], []);
% re-harvest to update tdeps and outputs
[u1 u2 u3 u4 u5 job.cj] = harvest(subsref(job.cj, rcjsubs), job.cj, false, false);
job.cjid2subs{id} = rcjsubs;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function cjrun = local_runcj(job, pflag)
% Matlab uses a copy-on-write policy with very high granularity - if
% modified, only parts of a struct or cell array are copied.
% However, forward resolution may lead to high memory consumption if
% variables are passed, but avoids extra housekeeping for outputs and
% resolved dependencies.
% Here, backward resolution is used. This may be time consuming for large
% jobs with many dependencies, because dependencies of any cfg_item are
% resolved only if all of them are resolvable (i.e. there can't be a mix of
% values and dependencies in a .val field).
% If pflag is true, then modules will be executed in parallel if they are
% independent. Setting pflag to false forces serial execution of modules
% even if they seem to be independent.
% If a job with pre-set module outputs .jout is passed in cj, the
% corresponding modules will not be run again. This feature is currently unused.

job = local_compactjob(job);
cj = job.cj;
cjid2subs = job.cjid2subs;
[u1 jobs u3 u4 u5 cjrun] = harvest(cj, cj, false, true);
% get subscripts of all exbranches into harvested job structure
for k = 1:numel(cjid2subs)
    jobsubs{k} = cfg2jobsubs(cjrun, cjid2subs{k});
end;
cjid2subsfailed = {};
while ~isempty(cjid2subs)
    % find jobs that can run
    cand = false(size(cjid2subs));
    if pflag
        % Check dependencies of all remaining jobs
        maxcand = numel(cjid2subs);
    else
        % Check dependencies of first remaining job only
        maxcand = min(1, numel(cjid2subs));
    end;
    for k = 1:maxcand
        if isempty(subsref(cjrun, [cjid2subs{k} substruct('.','tdeps')])) && subsref(cjrun, [cjid2subs{k} substruct('.','chk')])
            cand(k) = true;
        end;
    end;
    if ~any(cand)
        warning('matlabbatch:cfg_util:local_runcj:nomods', ...
                'No executable modules, but still unresolved dependencies or incomplete module inputs.');
        cjid2subsfailed = cjid2subs;
        break;
    end;
    % split job list
    cjid2subsrun = cjid2subs(cand);
    cjid2subs = cjid2subs(~cand);
    jobsubsrun = jobsubs(cand);
    jobsubs = jobsubs(~cand);
    % run jobs that have all dependencies resolved
    for k = 1:numel(cjid2subsrun)
        cm = subsref(cjrun, cjid2subsrun{k});
        if isempty(cm.jout)
            % no cached outputs (module did not run or it does not return
            % outputs) - run job
            fprintf('Running ''%s''\n', cm.name);
            try
                if isempty(cm.vout) && ~isempty(cm.vfiles);
                    warning('matlabbatch:cfg_util:vfiles', ...
                            'Using deprecated ''vfiles'' output in node ''%s''.', cm.tag);
                    feval(cm.prog, subsref(jobs, jobsubsrun{k}));
                    cm.jout.vfiles = feval(cm.vfiles, ...
                                           subsref(jobs, jobsubsrun{k}));
                elseif isempty(cm.sout)
                    % no outputs specified
                    feval(cm.prog, subsref(jobs, jobsubsrun{k}));
                else
                    cm.jout = feval(cm.prog, subsref(jobs, jobsubsrun{k}));
                end;
            catch
                cjid2subsfailed = {cjid2subsfailed{:} cjid2subsrun{k}};
                fprintf('%s failed\n', cm.name);
                l = lasterror;
                disp(l.message);
                if isfield(l,'stack'), % Does not always exist
                    for m = 1:numel(l.stack),
                        try
                            fp  = fopen(l.stack(m).file,'r');
                            str = fread(fp,Inf,'*uchar');
                            fclose(fp);
                            str = char(str(:)');
                            re  = regexp(str,'\$Id: \w+\.\w+ ([0-9]+) [0-9][0-9][0-9][0-9].*\$','tokens');
                            if numel(re)>0 && numel(re{1})>0,
                                id = [' (v', re{1}{1}, ')'];
                            else
                                id = ' (???)';
                            end
                        catch
                            id = '';
                        end
                        fprintf('In file "%s"%s, function "%s" at line %d.\n', ...
                                l.stack(m).file, id, l.stack(m).name, l.stack(m).line);
                    end
                end;
            end;
            % save results (if any) into job tree
            cjrun = subsasgn(cjrun, cjid2subsrun{k}, cm);
        else
            % Use cached outputs
            fprintf('Using cached outputs for ''%s''\n', cm.name);
        end;
    end;
    % update dependencies, re-harvest jobs
    [u1 jobs u3 u4 u5 cjrun] = harvest(cjrun, cjrun, false, true);
end;
if isempty(cjid2subsfailed)
    fprintf('Done\n');
else
    fprintf('The following modules did not run:\n');
    for k = 1:numel(cjid2subsfailed)
        fprintf('%s\n', subsref(cj, [cjid2subsfailed{k} substruct('.','name')]));
    end;
end;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [id str sts dep sout] = local_showjob(cj, cjid2subs)
% Return name, all_set status and id of internal job representation
id  = {};
str = {};
sts = [];
dep = [];
sout = {};
cmod = 1; % current module count
for k = 1:numel(cjid2subs)
    if ~isempty(cjid2subs{k})
        cm = subsref(cj, cjid2subs{k});
        id{cmod}  = k;
        str{cmod} = cm.name;
        sts(cmod) = all_set(cm);
        dep(cmod) = ~isempty(cm.tdeps);
        sout{cmod} = cm.sout;
        cmod = cmod + 1;
    end;
end;
%-----------------------------------------------------------------------

%-----------------------------------------------------------------------
function [mod_cfg_id item_mod_id] = local_tag2cfg_id(c0, tagstr, splitspec)

tags = textscan(tagstr, '%s', 'delimiter', '.');
taglist = tags{1};
if ~strcmp(taglist{1}, c0.tag)
    % assume tag list starting at application level
    taglist = {c0.tag taglist{:}};
end;
if splitspec
    % split ids at cfg_exbranch level
    finalspec = cfg_findspec({{'class','cfg_exbranch'}});
else
    finalspec = {};
end;
tropts=cfg_tropts({{'class','cfg_exbranch'}},0, inf, 0, inf, true);
[mod_cfg_id stop rtaglist] = tag2cfgsubs(c0, taglist, finalspec, tropts);
if iscell(mod_cfg_id)
    item_mod_id = {};
    return;
end;

if isempty(rtaglist)
    item_mod_id = struct('type',{}, 'subs',{});
else
    % re-add tag of stopped node
    taglist = {gettag(subsref(c0, mod_cfg_id)) rtaglist{:}};
    tropts.stopspec = {};
    [item_mod_id stop rtaglist] = tag2cfgsubs(subsref(c0, mod_cfg_id), ...
                                              taglist, {}, tropts);
end;