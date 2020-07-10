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

function latmat = latmat(lens, angs, varargin)
if numel(lens) > 3
    assert(size(lens,1)==3 && size(lens,2)==3 && ismatrix(lens));
    latmat = lens;
    return
end
% use varargin to define angle units
d.names = {'degree', 'radian'};
d.defaults = {true, false};
kwds = brillem.readparam(d, varargin{:});

assert(numel(lens)>=3 && numel(angs)>=3)
if kwds.degree && ~kwds.radian
    angs = angs / 180 * pi;
end

% spglib takes a matrix with columns defining the lattice vectors of
% the direct lattice. The first vector, a, is along the x axis of this
% orthonormal coordinate system. The second, b, is in the x-y plane; away
% from a by their mutual angle gamma. And the direction of the third is
% defined by alpha and beta.

xhat = [ 1;0;0];
yhat = [cos(angs(3));sin(angs(3));0];

cstar_hat = cross(xhat,yhat);
ccc2 = (cos(angs(2))+cos(angs(1))*cos(angs(3)))^2;
cz2 = ccc2*( 1/cos(angs(2))^2 -1) - (sin(angs(3))*cos(angs(1)))^2;
cz = sqrt(cz2)* cstar_hat/norm(cstar_hat);
zhat = xhat * cos(angs(2)) + yhat * cos(angs(1)) + cz;
zhat = zhat / norm(zhat);

latmat = cat(2,lens(1)*xhat,lens(2)*yhat,lens(3)*zhat);

end
