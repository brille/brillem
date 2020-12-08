classdef create_grid < brille.light_python_wrapper
    % Matlab wrapper around the create_grid function in brillem
    properties(Access=protected)
        pyobj = [];  % Reference to python object
    end
    methods
        % Constructor
        function obj = create_grid(varargin)
            brlm = py.importlib.import_module('brillem');
            obj.helpref = brlm.create_grid;
            % Overrides brille.BZ*Q.fill methods to handle input mangling
            obj.overrides = {'fill'}; 
            % Allow empty constructor for help function
            if ~isempty(varargin)
                args = brille.light_python_wrapper.parse_args(varargin, brlm.create_grid);
                obj.pyobj = brlm.create_grid(args{:});
                obj.populate_props();
            end
        end
        function out = plot(obj, varargin)
            brlplt = py.importlib.import_module('brille.plotting');
            args = brille.light_python_wrapper.parse_args(varargin, brlplt.plot);
            ax = brlplt.plot(obj.pyobj, args{:});
            if nargout > 0
                out = ax;
            end
        end
        function out = fill(obj, varargin)
            if ~isempty(varargin)
                fill(obj, varargin{:});
                out = 'fill successfull';
            else
                out = brille.generic_python_wrapper(py.getattr(obj.pyobj, 'fill'));
            end
        end
    end
end

function out = reshape_singletons(val)
    out = brille.m2p(val);
    sz = size(val);
    if numel(sz) < 3
        sz((end+1):3) = 1;
        out = py.numpy.reshape(out, {int32(sz(1)), int32(sz(2)), int32(1)});
    end
end

function fill(obj, varargin)
    % Ensures inputs are the correct type and shape.
    sort_flag = 0;
    if numel(varargin) == 5 || numel(varargin) == 7
        sort_flag = py.bool(varargin{end});
    end
    if numel(varargin) > 5
        [vals, nval, wval, vecs, nvec, wvec] = deal(varargin{1:6});
        wval = reshape_singletons(wval);
        wvec = reshape_singletons(wvev);
    else
        [vals, nval, vecs, nvec] = deal(varargin{1:4});
    end
    nval = {int32(nval)};
    nvec = {int32(nvec)};
    vals = reshape_singletons(vals);
    vecs = reshape_singletons(vecs);
    if numel(varargin) > 5
        obj.pyobj.fill(vals, nval, wval, vecs, nvec, wvec, sort_flag);
    else
        obj.pyobj.fill(vals, nval, vecs, nvec, sort_flag);
    end
end
