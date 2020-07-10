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

function bzt = BZTrellisQ(BrillouinZone,varargin)
kdef = struct('max_volume',0.1,'complex_values',false, 'complex_vectors', false);
[args,kwds]=brillem.parse_arguments(varargin,kdef,{'complex_values','complex_vectors'});

reqInType = 'py.brille._brille.BrillouinZone';
assert(isa(BrillouinZone,reqInType), ['A single',reqInType,' is required as input']);

if kwds.complex_values && kwds.complex_vectors
  bzt = py.brille.BZTrellisQcc(BrillouinZone, kwds.max_volume);
elseif kwds.complex_values
  bzt = py.brille.BZTrellisQcd(BrillouinZone, kwds.max_volume);
elseif kwds.complex_vectors
  bzt = py.brille.BZTrellisQdc(BrillouinZone, kwds.max_volume);
else
  bzt = py.brille.BZTrellisQdd(BrillouinZone, kwds.max_volume);
end

end
