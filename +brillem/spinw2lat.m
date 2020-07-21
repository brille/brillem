% brillem -- a MATLAB interface for brille
% Copyright 2020 Greg Tucker
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

function [dlat,rlat,trnm,latmat,latmat_primitive] = spinw2lat(sw,varargin)
% function [dlat,rlat, positions, types] = sw2lat(sw,varargin)
d.names = {'k', 'nExt'};
d.defaults = {NaN*[0;0;0], NaN*[1;1;1]};
kwds = brillem.readparam(d, varargin{:});

% In SpinW notation, nExt and k define separate functionalities and need not be related.
% SpinW uses nExt to define the supercell and k to define a single-k magnetic structure
% which can be represented by a single rotating coordinate frame (so not all single-k
% structures can be represented). It is possible in SpinW to have both a supercell
% and a single-k structure by specifying non-unity values for nExt and non-zero
% values for k. In this case the spins of adjacent supercells will have their
% angles rotated by the amount determined by k.

if all(isnan(kwds.k)) && all(isnan(kwds.nExt))
    % Default case, use nExt and k values from SpinW object
    if ~all(sw.mag_str.k==0) && ~all(sw.mag_str.nExt==1)
        error(['Brille cannot handle SpinW models which have both supercell' ...
              'and single-k structure simultaneously']);
    elseif all(sw.mag_str.k==0)
        nExt = double(sw.mag_str.nExt);
        k = 1 ./ nExt;
    else
        k = sw.mag_str.k;
        [~, nExt] = rat(k(:), 1e-5);  % Use the denominator of k
    end
elseif ~all(isnan(kwds.k)) && ~all(isnan(kwds.nExt))
    % User specified nExt and k
    k = kwds.k;
    nExt = kwds.nExt;
elseif ~all(isnan(kwds.k))
    % User specified k only
    warning('Using user specified k, ignoring SpinW nExt and k values');
    k = kwds.k;
    [~, nExt] = rat(k(:), 1e-5);
else
    % User specified nExt only
    warning('Using user specified nExt, ignoring SpinW nExt and k values');
    nExt = kwds.nExt;
    k = 1 ./ nExt;
end

assert(numel(nExt)==3,'the number of unit cell extensions, nExt, must be (1,3) or (3,1)')
nExt = nExt(:);

if numel(k)==3
    % nExt and k should be compatible, with nExt a direct lattice "vector" and
    % k a reciprocal lattice vector
    [kn,kd]=rat(k(:),1e-5);
    % the rationalized denominator of k should (normally) be nExt
    if sum(abs(kd - nExt)) > sum(abs(kd + nExt))*eps()
        warning('k=(%d/%d,%d/%d,%d/%d) and nExt=(%d,%d,%d) are not compatible',...
            kn(1),kd(1),kn(2),kd(2),kn(3),kd(3),...
            nExt(1),nExt(2),nExt(3))
        nExt = max( kd, nExt);
        warning('Returning supercell lattice for nExt=(%d,%d,%d)',nExt(1),nExt(2),nExt(3))
    end
end

% the transformation matrix from units of Q in input lattice to those in
% the returned lattice (which SpinW expects)
trnm = diag( nExt );

lens = sw.lattice.lat_const(:) .* nExt;
angs = sw.lattice.angle(:); % SpinW stores angles in radian

%positions = sw.atom.r;  %(3,nAtoms)
%types = sw.atom.idx(:); %(nAtoms,1)
%if any(nExt > 1)
%    ijk = zeros(3, 1, prod(nExt));
%    l=1;
%    for i=1:nExt(1)
%       for j=1:nExt(2)
%           for k=1:nExt(3)
%               ijk(:,l) = [i;j;k];
%               l = l + 1;
%           end
%       end
%    end
%    positions = reshape( bsxfun(@plus,positions,ijk-1), [3, size(positions,2)*prod(nExt)]);
%    positions = bsxfun(@rdivide,positions,nExt);
%    types = repmat(types,[prod(nExt),1]);
%end

% TODO
latmat = [];
latmat_primitive = [];

[dlat,rlat]=brillem.lattice(lens,angs,'radian','direct','spgr',sw.lattice.label);
