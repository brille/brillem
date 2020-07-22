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

% The Brille object holds one generalised py.brille grid object,
% a function that can be evaluated to fill the object, and one or more
% functions to interpret the interpolation results for, e.g, Horace.
classdef Brille < handle
    % making copies of the python object is (a) a bad idea for memory
    % management and (b) possibly bad for memory access --> handle class
    properties
        pygrid
        filler
        interpreter
    end
    properties (GetAccess = protected, SetAccess = private, SetObservable=true)
        parameterHash = ''
    end
    properties (SetAccess = private)
        isQE = false       % Does the py.brille grid span Q or (Q,E)
        nFillVal = 1       % How many eigenvalue outputs are provided by the grid filling function(s)
        nFillVec = 1       % How many eigenvector outputs are provided by the grid filling function(s)
        nFillers = 1;      % How many functions comprise the grid filling series
        span  = 1          %
        shapeval = {1}     % What is the eigenvalue shape of each filling function output per Q/(Q,E)
        shapevec = {1}     % What is the eigenvector shape of each filling function output per Q/(Q,E)
        nRet = 0           %
        nInt = 1           %
        rluNeeded = true   % Does the grid filling function expect Q in rlu (true) or inverse angstrom (false)
        parallel = true    % Should OpenMP parallelism be used by py.brille
        formfact = false   % Should the magnetic form factor be included
        magneticion        % If so, for which magnetic ion
        formfactfun        % What function calculates the form factor
        Qscale = eye(4);   % An optional multiplicitive transformation of (Q,E)
        Qtrans = eye(4);   % An optional translational transformation of (Q,E)
        baseobj            % Base (calculator) object (e.g. SpinW object)
    end
    methods
        function obj = Brille(ingrid,varargin)
            inpt ={ 'filler'     , [ 1,-1], true, @(x)1+0*x
                    'nfillval'   , [ 1, 1], true, []
                    'nfillvec'   , [ 1, 1], true, []
                    'max_volume' , [ 1, 1], true, 0.00001
                    'shapeval'   , [ 1,-7], true, []
                    'shapevec'   , [ 1,-7], true, []
                    'model'      , [ 1,-2], true, ''
                    'interpret'  , [ 1,-3], true, @(x)x
                    'nret'       , [ 1, 1], true, []
                    'rlu'        , [ 1, 1], true, true
                    'parallel'   , [ 1, 1], true, true
                    'formfact'   , [ 1, 1], true, false
                    'magneticion', [ 1,-4], true, ''
                    'formfactfun', [ 1, 1], true, @sw_mff
                    'Qscale'     , [-5, -5], true, eye(4)
                    'Qtrans'     , [-6, -6], true, zeros(4)
                    };
            sdef.names = inpt(:,1);
            sdef.sizes = inpt(:,2);
            sdef.soft = inpt(:,3);
            sdef.defaults = inpt(:,4);
            [kwds, ~] = brillem.readparam(sdef, varargin{:});
            % If the input is a SpinW object, automagically generate all required inputs
            if (strcmp(class(ingrid), 'spinw'))
                kwds.model = 'spinw';
                obj.baseobj = ingrid;
                magions = obj.baseobj.unit_cell.label;
                if numel(magions) == 1 || all(cellfun(@(x) strcmp(x, magions{1}), magions))
                    % Identical magnetic ions - interpolate Sab
                    [ingrid, Qtrans] = brillem.spinw2bzg(ingrid, 'max_volume', kwds.max_volume, 'iscomplex', false);
                    kwds.filler = @(varargin) brillem.spinwfiller(obj.baseobj, varargin{:});
                    kwds.magneticion = obj.baseobj.unit_cell.label{1};
                    kwds.formfact = false;
                else
                    % Non-identical magnetic ions, use eigenvectors
                    [ingrid, Qtrans] = brillem.spinw2bzg(ingrid, 'max_volume', kwds.max_volume);
                    kwds.filler = @(varargin) brillem.spinwfiller(obj.baseobj, varargin{:}, 'usevectors', true);
                end
                kwds.Qtrans = Qtrans;
            end
            grid_dim = brillem.is_brille_grid(ingrid);
            obj.isQE = 4 == grid_dim;
            if 0 == grid_dim
                error('brillem:Brille:inputGrid',...
                      'Unexpected input grid type %s', class(ingrid));
            end
            if islogical( kwds.parallel )
                obj.parallel = kwds.parallel;
            end
            if islogical( kwds.formfact )
                obj.formfact = kwds.formfact;
            end
            if obj.formfact && ~isempty(kwds.magneticion)
                obj.magneticion = kwds.magneticion;
            end
            if obj.formfact && isa(kwds.formfactfun,'function_handle')
                obj.formfactfun = kwds.formfactfun;
            end
            if isnumeric(kwds.Qscale) && ismatrix(kwds.Qscale)
                if numel(kwds.Qscale)==16
                    obj.Qscale(:) = kwds.Qscale(:);
                elseif numel(kwds.Qscale)==9
                    obj.Qscale([1,2,3,5,6,7,9,10,11])=kwds.Qscale(:);
                end
            end
            if isnumeric(kwds.Qtrans) && ismatrix(kwds.Qtrans)
                if numel(kwds.Qtrans)==16
                    obj.Qtrans(:) = kwds.Qtrans(:);
                elseif numel(kwds.Qtrans)==9
                    obj.Qtrans([1,2,3,5,6,7,9,10,11])=kwds.Qtrans(:);
                end
            end

            if iscell(kwds.filler)
                filler = kwds.filler;
            else
                filler = {kwds.filler};
            end
            assert(iscell(filler) && all( cellfun(@(x)(isa(x,'function_handle')), filler) ));
            obj.filler = filler;
            obj.nFillers = length(filler);

            % anything that defines 'varargout', including anonymous functions, returns negative nargout
            if ~isempty(kwds.nfillval) && isnumeric(kwds.nfillval) && isscalar(kwds.nfillval)
                nfillval = kwds.nfillval;
            end
            if ~isempty(kwds.nfillvec) && isnumeric(kwds.nfillvec) && isscalar(kwds.nfillvec)
                nfillvec = kwds.nfillvec;
            end
            fshapeval = kwds.shapeval; % what is the shape of each filler output
            fshapevec = kwds.shapevec;
            rlu = kwds.rlu; % does the filler function expect Q in rlu or inverse Angstrom?

            nret = [];
            if ~isempty(kwds.model) && ischar(kwds.model)
                switch lower(kwds.model)
                    case 'spinw'
                        nfillval = 1;
                        nfillvec = 1;
                        rlu = true;
                        interpret = { @obj.neutron_spinwave_intensity, @obj.convolve_modes };
                        nret = [2,1];
                        fshapeval = {1}; % filler produces 1 energy and a 3x3 matrix per Q
                        fshapevec = {[3,3]};
                end
            else
                interpret = kwds.interpret;
            end
            if ~iscell(interpret)
                interpret = {interpret};
            end
            assert( all( cellfun(@(x)(isa(x,'function_handle')), interpret) ),...
                'A single function handle or a cell of function handles is required for the interpreter' );
            obj.nInt = numel(interpret);

            if ~isempty(kwds.nret) && isnumeric(kwds.nret) && numel(kwds.nret)==numel(interpret)
                nret = kwds.nret;
            elseif isempty(nret)
                nret = cellfun(@(x)(abs(nargout(x))),interpret);
            end

            if ~iscell(fshapeval)
                fshapeval = {fshapeval};
            end
            if ~iscell(fshapevec)
                fshapevec = {fshapevec};
            end
            assert( ~isempty(fshapevec) && ~isempty(fshapeval) && numel(fshapeval) == nfillval && numel(fshapevec) == nfillvec, 'We need to know the shape of the filler output(s)' );

            assert( nret(end) == 1, 'the last interpreter function should return a scalar!');
            obj.nFillVal = nfillval;
            obj.nFillVec = nfillvec;
            obj.shapeval = fshapeval;
            obj.shapevec = fshapevec;
            obj.rluNeeded = rlu;
            obj.nRet = nret;
            obj.interpreter = interpret;

            obj.pygrid=ingrid;
        end
        sqw = horace_sqw(obj,qh,qk,ql,en,varargin)
        QorQE = get_mapped(obj)
        fill(obj,varargin)
        [valres, vecres] = interpolate(obj,qh,qk,ql,en)
        [omega, S] = neutron_spinwave_intensity(obj,qh,qk,ql,en,omega,Sab,varargin)
        con = convolve_modes(obj,qh,qk,ql,en,omega,S,varargin)
    end
end
