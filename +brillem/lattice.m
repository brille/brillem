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

function [dlat,rlat] = lattice(lens, angs, rord, varargin)
if nargin < 3 || isempty(rord)
    rord = 'direct';
end
if nargin < 2 || isempty(angs)
    angs = [90,90,90];
end

d.names = {'spgr'};
d.defaults = {'P 1'};
kwds = brillem.readparam(d, varargin{:});

% Brille will automatically deduce if angles given in degrees or radians
assert(numel(lens)>=3 && numel(angs)>=3)
pylens =brillem.m2p( lens(1:3) );
pyangs =brillem.m2p( angs(1:3) );

if strncmpi('reciprocal', rord, numel(rord))
    rlat = py.brille.Reciprocal(pylens, pyangs, kwds.spgr);
    dlat = rlat.star;
else
    dlat = py.brille.Direct(pylens, pyangs, kwds.spgr);
    rlat = dlat.star;
end
end
