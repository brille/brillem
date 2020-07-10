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
    function obj = Euphonic(euphonic, varargin)
      % Ensure that the versions of Euphonic and brillem are as expected
      brillem.verify_python_modules('euphonic','0.3.0', 'brilleu','0.1.0');
      % separate MATLAB name-value pairs and Python name-value pairs:
      % For now there are no key-value pairs which control behaviour on the
      % MATLAB side, so we provide an empty struct to readparam:
      [~, kwds] = brillem.readparam(struct(), varargin{:});
      % Verify that euphonic is a ForceConstants object:
      assert( isa(euphonic,'py.euphonic.force_constants.ForceConstants') )
      % Extract just the names from the pairs
      keys = fieldnames(kwds);
      % Convert the values to Python equivalents and make a cellarray (again)
      pykwds = cell(2*numel(keys),1);
      for i=1:numel(keys)
        pykwds{2*(i-1)+1} = keys{i};
        pykwds{2*(i-1)+2} = brillem.m2p(kwds.(keys{i}));
      end
      % Finally pass the py.Euphonic.ForceConstants object and optional
      % arguments to the py.brilleu.BrillEu constructor
      obj.pyobj = py.brilleu.BrillEu(euphonic, pyargs(pykwds{:}));
    end % intializer
    sqw = horace_sqw(obj,qh,qk,ql,en,varargin)
    wq  = w_q(obj,qh,qk,ql,varargin)
  end % methods
end % classdef
