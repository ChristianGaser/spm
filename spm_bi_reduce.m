function [M0,M1,L1,L2] = spm_bi_reduce(M,P,O)
% reduction of a fully nonlinear MIMO system to Bilinear form
% FORMAT [M0,M1,L1,L2] = spm_bi_reduce(M,P,1);  order 1 [default]
% FORMAT [M0,M1,L1]    = spm_bi_reduce(M,P,2);  order 2
%
% M   - model specification structure
% Required fields:
%   M.fx  - dx/dt    = f(x,u,P)                     {function string or m-file}
%   M.lx  - y(t)     = l(x,P)                       {function string or m-file}
%   M.bi  - bilinear form [M0,M1,L1,L2] = bi(M,P)   {function string or m-file}
%   M.m   - m inputs
%   M.n   - n states
%   M.l   - l outputs
%   M.x   - (n x 1) = x(0) = expanston point
%
% P   - model parameters
%
% if called with 1 a 1st order Bilinear approximation is returned where
% the states are
%
%		 q(t) = [1; x(t) - x(0)]
%
% if called with 2 then a 2nd order expansion is used with states
%
%		 q(t) = [1; x(t) - x(0); kron(x(t) - x(0),x(t) - x(0))]
%
%___________________________________________________________________________
% Returns Matrix operators for the Bilinear approximation to the MIMO
% system described by
%
%		dx/dt = f(x,u,P)
% 		 y(t) = l(x,P)
%
% evaluated at x(0) = x and u = 0
%
%		dq/dt = M0*q + u(1)*M1{1}*q + u(2)*M1{2}*q + ....
%		 y(i) = L1(i,:)*q + q'*L2{i}*q;
%
% (Note second order effects are already in L1 for the 2nd order expansion)
%---------------------------------------------------------------------------
% %W% Karl Friston %E%

% set up
%===========================================================================

% use M.bi if provided
%---------------------------------------------------------------------------
if isfield(M,'bi')
	funbi      = fcnchk(M.bi,'M','P');
	[M0,M1,L1] = feval(funbi,M,P);
	return
end

% default = 2nd order
%---------------------------------------------------------------------------
if nargin ~= 3, O = 1; end

m     = M.m;					% m inputs
n     = M.n;					% n states
l     = M.l;					% l ouputs
x     = M.x(:);					% expansion point
dx    = 1e-6;
du    = 1e-6;
u     = zeros(m,1);

% create inline functions
%---------------------------------------------------------------------------
funx  = fcnchk(M.fx,'x','u','P');
funl  = fcnchk(M.lx,'x','P');


% f(x(0),0) and l(x(0),0)
%---------------------------------------------------------------------------
f0    = feval(funx,x,u,P);
l0    = feval(funl,x,P);


% Partial derivatives for 1st order Bilinear operators
%===========================================================================

% dl(x(0))/dx
%---------------------------------------------------------------------------
for i = 1:n
    xi        = x;
    xi(i)     = xi(i) + dx;
    lx(:,i)   = feval(funl,xi,P);
    dldx(:,i) = (lx(:,i) - l0)/dx;
end

% dl(x(0))/dxdx (& L2)
%---------------------------------------------------------------------------
for i = 1:n
	for j = 1:n
		xi                = x;
    		xi(i)             = xi(i) + dx;
    		xi(j)             = xi(j) + dx;
		lxx               = feval(funl,xi,P);
		dldxx(:,i,j)      = ((lxx - lx(:,j))/dx - dldx(:,i))/dx;
		dldqq(i + 1,j + 1,:) = dldxx(:,i,j);
	end
end


% df(x,0)/du
%---------------------------------------------------------------------------
dfdu  = zeros(n,m);
for i = 1:m
	ui         = u;
	ui(i)      = ui(i) + du;
	fu(:,i)    = feval(funx,x,ui,P);
	dfdu(:,i)  = (fu(:,i) - f0)/du;
end

% df(x,0)/dx 
%---------------------------------------------------------------------------
dfdx  = zeros(n,n);
dfdxx = zeros(n,n,n);
dfdxu = zeros(n,n,m);
for i = 1:n
	xi         = x;
	xi(i)      = xi(i) + dx;
	fx(:,i)    = feval(funx,xi,u,P);
	dfdx(:,i)  = (fx(:,i) - f0)/dx;
end

% df(x,0)/dxdu
%---------------------------------------------------------------------------
for i = 1:n
	for j = 1:m
		xi           = x;
		xi(i)        = xi(i) + dx;
		uj           = u;
		uj(j)        = uj(j) + du;
		fxu(:,i,j)   = feval(funx,xi,uj,P);
		dfdxu(:,i,j) = ((fxu(:,i,j) - fu(:,j))/dx - dfdx(:,i))/du;
	end
end

% 1st order Bilinear operators
%===========================================================================
I     = speye(n,n);
n0    = sparse(n*n,1);
if  O ~= 2

	% Bilinear operator - M0
	%-------------------------------------------------------------------
	M0    = [[0 sparse(1,n) ];
 	 	[f0 dfdx       ]];

	% Bilinear operator - M1
	%-------------------------------------------------------------------
	for i = 1:m
		Df     = dfdu(:,i);
		Ddfdx  = dfdxu(:,:,i);
		M1{i}  = [[0 sparse(1,n) ];
	 		 [Df Ddfdx/2    ]];
	end

	% Output matrices - L1 & L2
	%-------------------------------------------------------------------
	L1    = [l0 dldx];
	for i = 1:l
		L2{i} = dldqq(:,:,i);
	end

	return
end


% Partial derivatives of higher order %===========================================================================

% df(x,0)/dxdx
%---------------------------------------------------------------------------
for i = 1:n
	for j = 1:n
		xi           = x;
		xi(i)        = xi(i) + dx;
		xi(j)        = xi(j) + dx;
		fxx(:,i,j)   = feval(funx,xi,u,P);
		dfdxx(:,i,j) = ((fxx(:,i,j) - fx(:,j))/dx - dfdx(:,i))/du;
	end
end

% df(x,0)/dxdxdu
%---------------------------------------------------------------------------
% discounted from 2nd order approximation



% 2nd order Bilinear operators
%===========================================================================

% Bilinear operator - M0
%---------------------------------------------------------------------------
I     = speye(n,n);
n0    = sparse(n*n,1);
M0    = [[0 sparse(1,n)               n0'                              ];
 	[f0 dfdx                      dfdxx(:,:)/2                     ];
	[n0 (kron(f0,I) + kron(I,f0)) (kron(dfdx,I) + kron(I,dfdx))    ]];

% Bilinear operator - M1
%---------------------------------------------------------------------------
for i = 1:m
Df    = dfdu(:,i);
Ddfdx = dfdxu(:,:,i);
M1{i} = [[ 0 sparse(1,n)               n0'                               ];
	 [Df Ddfdx/2                   sparse(n,n*n)                     ];
         [n0 (kron(Df,I) + kron(I,Df)) (kron(Ddfdx,I) + kron(I,Ddfdx))/2]];
end

% Output matrix
%---------------------------------------------------------------------------
for i = 1:l
	Ddldx   = dldxx(i,:,:);
	L1(i,:) = [l0(i) dldx(i,:) Ddldx(:)'/2];
end
