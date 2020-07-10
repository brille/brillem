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

function fill(obj,varargin)

% First, refill the grid(s) if the hashes differ
newHash = brillem.DataHash(varargin);
if ~strcmp(obj.parameterHash, newHash)
    vecs = obj.get_mapped();
    fillwith = cell(1,obj.nFill);
    [fillwith{:}] = obj.filler{1}(vecs{:},varargin{:});
    for i=2:obj.nFillers
        [fillwith{:}] = obj.filler{i}(fillwith{:});
    end

    % reshape the output(s) if necessary
    obj.span = ones(size(fillwith));
    num = numel(vecs{1});
    mds = zeros(size(fillwith));
    for i=1:obj.nFill
        fws = size(fillwith{i});
        obj.shape{i} = fws(2:end);
        mds(i) = fws(2);
        if length(fws)>2
            obj.span(i)=prod(fws(3:end));
        end
    end
    equalmodes = std(mds)==0;
    for i=1:obj.nFill
        if equalmodes
            fillwith{i} = reshape( fillwith{i}, [num, mds(i), obj.span(i)] );
        elseif length(obj.shape{i}) > 1
            fillwith{i} = reshape( fillwith{i}, [num, prod(obj.shape{i})] );
        end
    end
    % and smash them together for input into the grid:
    if equalmodes
        fillwith = cat(3, fillwith{:});
    else
        fillwith = cat(2, fillwith{:});
    end
    %
    assert( numel(fillwith) == num * sum(cellfun(@prod,obj.shape)) )
    %
    % BAD HACK FOR NOW. CHANGE ME!
    nel = brillem.m2p( uint16([1,0,0,3]) );
    % and finally put them in:
    obj.pygrid.fill( brillem.m2p(fillwith), nel); % TODO FIXME !!!!!! This is no longer the correct syntax!

    % we have successfully filled the grid(s), so store the hash.
    obj.parameterHash = newHash;
end

end
