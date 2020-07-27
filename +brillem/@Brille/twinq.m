function [Qtwin, rotQout] = twinq(obj, Q0)
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

% basis vectors
bv = (inv(brillem.p2m(obj.pygrid.BrillouinZone.lattice.lattice_matrix)) * 2 * pi) / obj.Qtrans(1:3,1:3);

nTwin = size(obj.twin.vol,2);

% rotation matrices, output only if requested
rotQ = zeros(3,3,nTwin);
for ii = 1:nTwin
    rotQ(:,:,ii) = bv\obj.twin.rotc(:,:,ii)*bv;
end
if nargout>1
    rotQout = rotQ;
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

end
