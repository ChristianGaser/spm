function spm_barh(E,C)
% density plotting function (c.f. bar - horizontal)
% FORMAT spm_barh(E,C)
% E   - (n x 1) expectation
% C   - (n x 1) variances
%___________________________________________________________________________
% %W% Karl Friston %E%


% densities
%---------------------------------------------------------------------------
n     = length(E);
H     = zeros(2*n + 1,64);
x     = linspace(min(E - 4*sqrt(C)),max(E + 4*sqrt(C)),64);
for i = 1:n
	H(2*i,:) = exp(-[x - E(i)].^2/(2*C(i)));
end
imagesc(x,[0:n]+ 0.5,1 - H)
set(gca,'Ytick',[1:n])
grid on

% confidence intervals based on conditional variance
%---------------------------------------------------------------------------
for i = 1:n
	z           = spm_invNcdf(0.05)*sqrt(C(i));
	line([-z z] + E(i),[i i],'LineWidth',4);
end


