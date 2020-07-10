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

function wq = w_q(obj,qh,qk,ql,varargin)
% Input:
% ------
%   qh,qk,ql   Arrays containing points at which to evaluate omega(q)
%
%   kwds       A series of 'keywords' and parameters.
%
%              Some keywords control aspects of this function:
%              'coordtrans' - a matrix to transform the input coordinates
%                             (qh,qk,ql,en) before being sent to the
%                             py.brille.euphonic.BrEu object's method.
%                             [default: eye(4) % identity]
%
%              Any additional keyword parameters will be passed to
%              BrillEu.w_q as a py.dict for processing.
%
% Output:
% -------
%   w(q)       Array with eigen energies at the Q points
%              [ size(w_q) == size(qh) ]
matkeys.names = {'coordtrans'};
matkeys.defaults = {eye(4)};
matkeys.sizes = {[4,4]};
[kwds, dict] = brillem.readparam(matkeys, varargin{:});


nQ = numel(qh);
inshape = size(qh);
if size(qh,1) ~= nQ
    qh = qh(:);
    qk = qk(:);
    ql = ql(:);
end
% Transforms input coordinates if needed
if sum(sum(abs(kwds.coordtrans - eye(4)))) > 0
    qc = [qh qk ql 0*qh];
    qh = sum(bsxfun(@times, kwds.coordtrans(1,:), qc),2);
    qk = sum(bsxfun(@times, kwds.coordtrans(2,:), qc),2);
    ql = sum(bsxfun(@times, kwds.coordtrans(3,:), qc),2);
    clear qc;
end
Q = brille.m2p(cat(2,qh,qk,ql));

wq = brille.p2m(obj.pyobj.w_q(Q, py.dict(dict)));

wq_size = size(wq);
if wq_size(1:end-1) ~= inshape
    wq = reshape(wq, [inshape, wq_size(end)]);
end
end % w_q
