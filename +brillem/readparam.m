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

% This function is a sw_readparam from spinw modified to take an empty
% format struct and also to return all key-value pairs not in format.

function [input, extras] = readparam(format, varargin)
% parse input arguments
%
% ### Syntax
%
% `[parsed, extras] = brillem.readparam(format,Name,Value,...)`
%
% ### Description
%
% `[parsed, extras] = brillem.readparam(format,Name,Value)` parses
% name-value pair arguments. The parsing is controlled by the given
% `format` input. The name-value pairs are converted into the parsed struct
% which has field names identical to the given parameter names and
% corresponding values taken from the input. `format` can also define
% required dimensionality of a given value and default values for select
% parameters. Extra name-value pairs not defined in format are returned in
% the second output argument.
%
%
% ### Input Arguments
%
% `format`
% : A struct either empty or with the following fields:
%   * `names` Field names, $n_{param}$ strings in cell.
%   * `sizes` Required dimensions of the corresponding value in a cell of
%     $n_{param}$ vectors. Negative integer means dimension has to match
%     with any other dimension which has the identical negative integer.
%   * `defaults` Cell of $n_{param}$ values, provides default values for
%     missing parameters.
%   * `soft` Cell of $n_{param}$ logical values, optional. If `soft(i)` is
%     true, in case of missing parameter value $i$, no warning will be
%     given.
%
% `Name`
% : A char array named parameter
%
% `Value`
% : The value of the last provided name, of any type
%
% `...`
% : Any additional number of `Name`-`Value` pairs

if nargin == 0
    help brillem.readparam
    return
end

if (nargin>2) && (mod(nargin,2) == 1)
    nPar = nargin-1;
    raw = struct;
    for ii = 1:2:nPar
        raw.(varargin{ii}) = varargin{ii+1};
    end
elseif nargin == 2
    raw = varargin{1};
elseif nargin == 1
    raw = struct;
else
    MException('brillem:readparam:WrongParameter',...
        'Parameter name-value pairs are expected!').throwAsCaller;
end

if ~isstruct(raw)
    if isempty(raw)
        raw = struct;
    else
        MException('brillem:readparam:WrongParameter',...
            'Parameter name-value pairs are expected!').throwAsCaller;
    end
end

if ~isfield(format, 'names')
    format.names = [];
end

fName     = format.names;
rName     = fieldnames(raw);
storeSize = zeros(20,1);
input     = struct;

usedField = false(1,numel(rName));

% Go through all fields.
for ii = 1:length(fName)
    
    rawIdx = find(strcmpi(rName,fName{ii}));
    
    if any(rawIdx)
        rawIdx = rawIdx(1);
        usedField(rawIdx) = true;
        
        inputValid = true;
        
        % Go through all dimension of the selected field to check size.
        if isfield(format, 'sizes')
            for jj = 1:length(format.sizes{ii})
                if format.sizes{ii}(jj)>0
                    if format.sizes{ii}(jj) ~= size(raw.(rName{rawIdx}),jj)
                        inputValid = false;
                    end
                else
                    if storeSize(-format.sizes{ii}(jj)) == 0
                        storeSize(-format.sizes{ii}(jj)) = size(raw.(rName{rawIdx}),jj);
                    else
                        if storeSize(-format.sizes{ii}(jj)) ~= size(raw.(rName{rawIdx}),jj)
                            inputValid = false;
                        end
                        
                    end
                end
            end
        end
        if inputValid
            input.(fName{ii}) = raw.(rName{rawIdx});
        else
            if isfield(format,'soft') && format.soft{ii}
                input.(fName{ii}) = format.defaults{ii};
            else
                MException('brillem:readparam:ParameterSizeMismatch',['Input parameter size mismatch in parameter ''' fName{ii} '''!']).throwAsCaller;
            end
        end
    else
        if isfield(format,'defaults') && (any(size(format.defaults{ii})) || (isfield(format,'soft') && format.soft{ii}))
            input.(fName{ii}) = format.defaults{ii};
        else
            MException('brillem:readparam:MissingParameter',['Necessary input parameter ''' fName{ii} ''' is missing!']).throwAsCaller;
        end
    end
end

% Deal with extra specified name-value pairs
extras    = struct;
if ~all(usedField)
    for ii = 1:numel(rName)
        if ~usedField(ii)
            extras.(rName{ii}) = raw.(rName{ii});
            usedField(ii) = true;
        end
    end
end

end
