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
d.names = {'complex_values', 'complex_vectors', 'max_volume'};
d.defaults = {false, false, 0.1};
[kwds, dict] = brillem.readparam(d, varargin{:});

reqInType = 'py.brille._brille.BrillouinZone';
assert(isa(BrillouinZone,reqInType), ['A single',reqInType,' is required as input']);

% Convert the extra values to Python equivalents and make a cellarray (again)
keys = fieldnames(dict);
pydict = cell(2*numel(keys),1);
for i=1:numel(keys)
    pydict{2*(i-1)+1} = keys{i};
    pydict{2*(i-1)+2} = brillem.m2p(kwds.(keys{i}));
end
args = pyargs(pydict{:});

if kwds.complex_values && kwds.complex_vectors
  bzt = py.brille.BZTrellisQcc(BrillouinZone, kwds.max_volume, args);
elseif kwds.complex_values
  bzt = py.brille.BZTrellisQcd(BrillouinZone, kwds.max_volume, args);
elseif kwds.complex_vectors
  bzt = py.brille.BZTrellisQdc(BrillouinZone, kwds.max_volume, args);
else
  bzt = py.brille.BZTrellisQdd(BrillouinZone, kwds.max_volume, args);
end

end
