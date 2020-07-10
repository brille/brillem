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

function bzm = BZMeshQ(BrillouinZone,varargin)
% Create a py.brille.BZMeshQ object from a py.brille.BrillouinZone object
% and an optional list of keyword-value paired arguments.
% One argument, 'complex' is used by the MATLAB function to choose a real or
% complex-valued data structure in the mesh; the remaining provided
% keyword-value paired agruments are passed to the Python function.
% As of this writing, the valid keywords are:
%
%   max_size        The maximum edge length of any tetrahedron in the mesh
%                   expressed in inverse Angstrom. Default value -1.0, which
%                   indicates no maximum size.
%   min_angle       The minimum tetrahedron face angle in degrees. Default
%                   value 20.0; -1.0 indicates no minimum. Care should be taken
%                   when setting this value higher than 20 degrees; at some
%                   point the number of mesh points required to satisfy a
%                   large minimum face-angle grows rapidly and above ~30 degrees
%                   there might not be a solution.
%   max_angle       The maximum tetrahedron dihedral angle in degrees. Default
%                   value -1.0, which indicates that an interal default of 179
%                   or 179.99 degrees should be used.
%   min_ratio       The minimum tetrahedron length(?) to circumscribed sphere
%                   radius ratio. Default value -1.0, indicating no limit.
%   max_points      The maximum number of Steiner points to add to the mesh
%                   while attempting to satisfy other provided mesh quality
%                   criteria. This keyword value must be a Python integer and
%                   its default is -1, meaning there is no limit to extra points.
d.names = {'complex_values', 'complex_vectors'};
d.defaults = {false, false};
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
  bzm = py.brille.BZMeshQcc(BrillouinZone, args);
elseif kwds.complex_values
  bzm = py.brille.BZMeshQcd(BrillouinZone, args);
elseif kwds.complex_vectors
  bzm = py.brille.BZMeshQdc(BrillouinZone, args);
else
  bzm = py.brille.BZMeshQdd(BrillouinZone, args);
end

end


