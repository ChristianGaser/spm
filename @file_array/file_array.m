function a = file_array(varargin)
% Function for creating file_array objects.
% FORMAT a = file_array(fname,dim,dtype,off,scale,inter)
% a      - file_array object
% fname  - filename
% dim    - dimensions (default = [0 0] )
% dtype  - datatype   (default = 'uint8-le')
% off    - offset into file (default = 0)
% scale  - scalefactor (default = 1)
% inter  - DC offset, such that dat = raw*scale + inter (default = 0)
% _______________________________________________________________________
% Copyright (C) 2005 Wellcome Department of Imaging Neuroscience

%
% $Id$


if nargin==1
    if isstruct(varargin{1}),
        a = class(varargin{1},'file_array');
        return;
    elseif isa(varargin{1},'file_array'),
        a = varargin{1};
        return;
    end;
end;
a = struct('fname','','dim',[0 0],'dtype',2,...
           'be',0,'offset',0,'pos',[],'scl_slope',[],'scl_inter',[]);
%a = class(a,'file_array');

if nargin>=1, a =     fname(a,varargin{1}); end;
if nargin>=2, a =       dim(a,varargin{2}); end;
if nargin>=3, a =     dtype(a,varargin{3}); end;
if nargin>=4, a =    offset(a,varargin{4}); end;
if nargin>=5, a = scl_slope(a,varargin{5}); end;
if nargin>=6, a = scl_inter(a,varargin{6}); end;

a.pos = ones(size(a.dim));
a     = class(a,'file_array');
