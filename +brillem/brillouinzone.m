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

function bz = brillouinzone(Reciprocal,varargin)
d.names = {'extent'};
d.defaults = {1};
kwds = brillem.readparam(d, varargin{:});

reqInType = 'py.brille._brille.Reciprocal';
assert(isa(Reciprocal,reqInType), ['A single',reqInType,' lattice is required as input']);

bz = py.brille.BrillouinZone( Reciprocal, int32(kwds.extent));
end
