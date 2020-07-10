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

function verify_versions()

min_brille_ver = '0.4.0';
min_py_ver = '3.6';

[pyv, pyexec, ~] = pyversion();

if ~semver_compatible(pyv, min_py_ver)
  error('brillem:verify_version:pythonVersion',...
        'brille requires Python >= %s', min_py_ver);
end

try
  brille_mod = py.importlib.import_module('brille');
catch prob
  error('brillem:verify_version:brilleNotFound', ...
        'Python brille module not imported by %s\n%s',...
        pyexec, prob.message);
end

try
  brv = char(brille_mod.version);
catch prob
  error('brillem:verify_version:brilleVersionUnavailable',...
        'Problem obtaining brille module version string\n%s',...
        prob.message);
end

if ~semver_compatible(brv, min_brille_ver)
  error('brillem:verify_version:brilleIncompatibleVersion',...
        'brille >= %s required but %s present', min_brille_ver, brv);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = semver_compatible(astr, bstr)
a = semver_split(astr);
b = semver_split(bstr);
if a(1) == b(1) && (a(2) > b(2) || (a(2)==b(2) && a(3)>=b(3)))
  ret = true;
else
  ret = false;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function v = semver_split(str)
rM   =       '^(?<major>0|[1-9]\d*)';
rMm  = [rM  '\.(?<minor>0|[1-9]\d*)'];
rMmp = [rMm '\.(?<patch>0|[1-9]\d*)'];

if regexp(str, rMmp)
  vs = regexp(str, rMmp, 'names');
elseif regexp(str, rMm)
  vs = regexp(str, rMm , 'names');
  vs.patch = '0';
elseif regexp(str, rM)
  vs = regexp(str, rM  , 'names');
  vs.minor = '0';
  vs.patch = '0';
end

v = structfun(@str2num, vs);
end
