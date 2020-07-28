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

function isok = test()
isok=false;

[d,r] = brillem.lattice([2*pi,2*pi,2*pi],[90,90,120],'direct');

if     ~isapprox(r.a, 2*pi/d.a/sin(d.gamma))
    return;
elseif ~isapprox(r.b, 2*pi/d.b/sin(d.gamma))
    return;
elseif ~isapprox(r.c, 2*pi/d.c)
    return;
end

if ~throws_message('A single py.brille._brille.Reciprocal lattice is required as input',@brillem.brillouinzone,d)
    return;
end
bz = brillem.brillouinzone(r);
if bz.normals.shape{1}~=8 || bz.normals.shape{2}~=3
    return;
elseif size(bz.faces_per_vertex,2)~=12
    return;
elseif bz.vertices.shape{1}~=12||bz.vertices.shape{2}~=3
    return;
end

if ~throws_message('A single py.brille._brille.BrillouinZone is required as input',@brillem.BZTrellisQ,r)
    return;
end
bzg = brillem.BZTrellisQ(bz,'max_volume',0.0001);
if bzg.rlu.shape ~= bzg.invA.shape
    return;
end
% more tests?
[~,r]=brillem.lattice(2*pi*[1,1,1],90*[1,1,1]);
bz=brillem.brillouinzone(r);
bzg = brillem.BZTrellisQ(bz,'max_volume',0.0001);
sq = @(Q)( cat(2, Q(:,1),Q(:,2)+0.5*Q(:,3)) ); % replace with any function linear in the components of Q
gridvals = py.numpy.array(sq(double(bzg.rlu)));
gridels = brillem.m2p([2,0,0],'int');
bzg.fill(gridvals, gridels, gridvals, gridels, true);
qrand = (rand(30,3)-0.5);
ret = bzg.interpolate_at(py.numpy.array(qrand));
retvals = brillem.p2m(ret{1});
retvecs = brillem.p2m(ret{2});
if ~all(all(isapprox(retvals, retvecs)))
    return;
end
if ~all(all(isapprox(retvals, sq(qrand), 8)))
    return;
end

isok=true;
end

function tf=isapprox(a,b,tol)
if nargin<3 || isempty(tol); tol=1; end
tf = abs(a-b) < abs(a+b)*tol*eps();
end
function tf=throws_message(m,f,varargin)
    tf = false;
    try
        f(varargin{:});
        return;
    catch prob
        if strncmp(m,prob.message,min(length(m),length(prob.message)))
            tf=true;
        end
    end
end
