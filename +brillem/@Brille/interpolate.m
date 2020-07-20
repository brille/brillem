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

function intvalres = interpolate(obj,qh,qk,ql,en)
% The python module expects an (N,3)
iat = cat(2,qh,qk,ql);
% or (N,4), if isQE is true
if obj.isQE
   iat = cat(2,iat,en);
end
s2 = size(iat,2);
trn = obj.Qtrans(1:s2,1:s2);
if sum(sum(abs(trn - eye(s2))))>0
    for i = 1:size(iat,1)
        iat(i,:) = permute( trn* permute(iat(i,:),[2,1]), [2,1]);
%         iat(i,:) = iat(i,:)/trn;
    end
end

% numpy.array as input to the interpolator
iat = brillem.m2p(iat);

num = numel(qh);
numres = num * sum(cellfun(@prod,obj.shape));

% Do the actual interpolation
pyallres = obj.pygrid.ir_interpolate_at(iat,true,obj.parallel);
valres = brillem.p2m( pyallres{1} );
vecres = brillem.p2m( pyallres{2} );

assert( numel(valres) + numel(vecres) == numres )
% and then split-up the interpolated results into the expected outputs
intvalres = cell(1,obj.nFillVal);

if ismatrix(valres)
    offsets = cumsum( cat(2, 0, cellfun(@prod,obj.valshape)) );
    for i=1:obj.nFillVal
        intvalres{i} = reshape( valres(:, (offsets(i)+1):offsets(i+1) ), cat(2,num,obj.valshape{i}) );
    end
elseif ndims(valres)==3
    offsets = cumsum( cat(2, 0, obj.valspan) );
    for i=1:obj.nFillVal
        intvalres{i} = reshape( valres(:, :, (offsets(i)+1):offsets(i+1)), cat(2,num,obj.valshape{i}) );
    end
end

intvecres = cell(1,obj.nFillVec);
if ismatrix(vecres)
    offsets = cumsum( cat(2, 0, cellfun(@prod,obj.vecshape)) );
    for i=1:obj.nFillVec
        intvecres{i} = reshape( vecres(:, (offsets(i)+1):offsets(i+1) ), cat(2,num,obj.vecshape{i}) );
    end
elseif ndims(vecres)==3
    offsets = cumsum( cat(2, 0, obj.vecspan) );
    for i=1:obj.nFillVec
        intvecres{i} = reshape( vecres(:, :, (offsets(i)+1):offsets(i+1)), cat(2,num,obj.vecshape{i}) );
    end
end



end
