function varargout = twinq(obj, Q0, varargin)
% calculates equivalent Q point in twins, and optionally rotation matrices
% that transform the $Q$ point from the original lattice to the twin rlu coordinates
% 
% ### Syntax
% 
% `[qTwin, rotQ] = twinq(obj, {Q0})`
% 
% ### Arguments
%
% `Q0` - $Q$ values in the original crystal orientation as a $[3\times n_Q]$ matrix
% `qTwin` - $Q$ values in the twin (1 cell per twin)
% `rotQ` - $[3\times 3\times n_{twin}]$ Rotation matrices

if nargin > 1
    Q0 = cat(2, Q0, varargin{1:2})';
end
if nargout > 3 && nargin < 4
    error('Insufficient inputs for demanded outputs. Requested [qh, qk, ql, en] out but only supplied [qh, qk, ql] in');
end

% basis vectors
bv = (inv(brillem.p2m(obj.pygrid.BrillouinZone.lattice.lattice_matrix)) * 2 * pi) / obj.Qtrans(1:3,1:3);

nTwin = size(obj.twin.vol,2);

% rotation matrices, output only if requested
rotQ = zeros(3,3,nTwin);
for ii = 1:nTwin
    rotQ(:,:,ii) = bv\obj.twin.rotc(:,:,ii)*bv;
end

% rotate Q points if given as input
Qtwin = cell(1,nTwin);
if nargin>1
    for ii = 1:nTwin
        Qtwin{ii} = (Q0'*rotQ(:,:,ii))';
    end
else
    Qtwin = {};
end

if nargout == 2
    varargout = {Qtwin, rotQ};
elseif nargout == 1
    varargout = {Qtwin};
elseif nargout > 2
    for ii = 1:nTwin
        Qh{ii} = Qtwin{ii}(1,:)'; Qk{ii} = Qtwin{ii}(2,:)'; Ql{ii} = Qtwin{ii}(3,:)';
    end
    if nargout == 3
        varargout = {Qh, Qk, Ql};
    else
        for ii = 1:nTwin;
            en{ii} = varargin{3};
        end
        varargout = {Qh, Qk, Ql, en};
    end
end

end
