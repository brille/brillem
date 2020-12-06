classdef create_bz < brille.light_python_wrapper
    % Matlab wrapper around the create_bz function in brillem
    properties(Access=protected)
        pyobj = [];  % Reference to python object
    end
    methods
        % Constructor
        function obj = create_bz(varargin)
            brlm = py.importlib.import_module('brillem');
            obj.helpref = brlm.create_bz;
            % Allow empty constructor for help function
            if ~isempty(varargin)
                args = brille.light_python_wrapper.parse_args(varargin, brlm.create_bz);
                obj.pyobj = brlm.create_bz(args{:});
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
    end
end
