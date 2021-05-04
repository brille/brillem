function brille_on()

global brille_is_initialised;
if isempty(brille_is_initialised) || ~brille_is_initialised
 
    % Check if Brille is installed and the correct version
    req_mods = required_modules;
    try
        verify_python_modules(req_mods{:});
    catch ME
        if ~isempty(strfind(ME.message, 'DistributionNotFound')) ...
            || ~isempty(strfind(ME.message, 'ModuleNotFoundError')) ...
            modules = join(mod_str(req_mods));
            modules = sprintf('%s', modules{:});
            error(sprintf(['The Python modules required are not installed. ' ... 
                  'Please install them with:\npip install ' modules '\n' ...
                  'Or use the ''brille.install_python_modules'' script.']));
        else
            rethrow(ME);
        end
    end
    
    % Check if Brille can be loaded
    try
        py.importlib.import_module('brille');
    catch ME
        [ver, ex, isloaded] = pyversion;
        warning(['Couldn''t import Brille Python library.\n' ...
                 'Has it been installed correctly for the currently loaded Python at %s?\n' ...
                 'If not you can install it using ''pip install %s'' on the command line ' ...
                 'or use the Matlab command ''brille.install_python_modules'' included ' ...
                 'in this package.\n' ...
                 '\nOriginal error message: %s'], ex, 'brille', ME.message);
    end
    
    brille_is_initialised = true;
end

end

