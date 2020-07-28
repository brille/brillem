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

classdef Euphonic < handle
  properties
    pyobj
  end
  methods
    function obj = Euphonic(filename, varargin)
      % Ensure that the versions of Euphonic and brillem are as expected
      brillem.verify_python_modules('euphonic','0.3.0', 'brilleu','0.2.1');
      % separate MATLAB name-value pairs and Python name-value pairs:
      kv.names = {'castep', 'phonopy'};
      kv.defaults={true, false};
      [matkwds, kwds] = brillem.readparam(kv, varargin{:});
      % Verify that filename is the name of a file or folder:
      assert( isa(filename, 'char') )
      % Extract just the names from the pairs
      keys = fieldnames(kwds);
      % Convert the values to Python equivalents and make a cellarray (again)
      kwdscell = cell(2*numel(keys),1);
      for i=1:numel(keys)
        kwdscell{2*(i-1)+1} = keys{i};
        kwdscell{2*(i-1)+2} = brillem.m2p(kwds.(keys{i}));
      end
      pykwds = pyargs(kwdscell{:});
      % Grab a handle to the brilleu python module:
      pybe = py.importlib.import_module('brilleu');
      % Finally pass the filename/directory-path and optional
      % arguments to the py.brilleu.BrillEu constructor
      if matkwds.phonopy
        assert( exist(filename, 'dir') )
        obj.pyobj = pybe.BrillEu.from_phonopy(filename, pykwds);
      else
        assert( exist(filename, 'file') && ~exist(filename, 'dir') )
        obj.pyobj = pybe.BrillEu.from_castep(filename, pykwds);
      end
    end % intializer
    sqw = horace_sqw(obj,qh,qk,ql,en,varargin)
    wq  = w_q(obj,qh,qk,ql,varargin)
  end % methods
end % classdef
