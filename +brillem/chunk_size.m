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

function chunk = chunk_size(pygrid, multiplier)
if nargin < 2 || isempty(multiplier); multiplier = 1; end
chunk = brillem.free_bytes();
bpp = multiplier*brillem.p2m(pygrid.bytes_per_point);
if bpp > 0; chunk = chunk/bpp; end
end

