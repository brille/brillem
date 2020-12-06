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
    end
end
