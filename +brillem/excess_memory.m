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

function excess = excess_memory(pygrid, npts, multiplier)
if nargin < 3 || isempty(multiplier); multiplier = 1; end
excess = freeBytes() - multiplier*npts*brillem.p2m(pygrid.bytes_per_point);
end

% Adapted from spinW sw_freemem:
function fb = freeBytes()
    fb = 0;
    if ismac
        % read free memory on a macOS machine
        [~,memStr] = unix('vm_stat | grep free');
        fb = sscanf(memStr(14:end),'%f')*4096;
    elseif isunix
        % read free memeory on a linux machine
        [~, memStr] = unix('free -b | grep ''-''');
        if isempty(memStr)
            % there is no buffer/cache, just get the 'Mem' values
            [~, memStr] = unix('free -b | grep ''Mem''');
            [~, mem_free] = strtok(memStr);
            mem = sscanf(mem_free,'%f');
            fb = mem(3);
        else
            [~, mem_free] = strtok(memStr(20:end));
            fb = str2double(mem_free);
        end
    elseif ispc
        % use built-in MATLAB functionality to read memory on a Windows machine
        uv = memory();
        fb = uv.MaxPossibleArrayBytes;
    end
end
