# [v0.2.0](https://github.com/brille/brillem/compare/v0.1.0...v0.2.0)

## Major changes

[SpinW](https://github.com/spinw/spinw) support has been removed from this
project (`brillem`) and moved into SpinW itself.
Instead of constructing a `brillem.Brille` object from a `spinw` object
and calling the `Brille` object's `spinwave()` method to calculate an
interpolated structure, users should now use the `spinw.spinwave()` method
directly with the `'use_brille', true` option.

Likewise, [Euphonic](https://github.com/pace-neutrons/euphonic) support 
via the [brilleu](https://github.com/brille/brilleu) Python project has
been removed from this repository. Instead, use of Brille in Euphonic will
be handled internally in Euphonic and will be accessible from Matlab
using the [horace-euphonic-interface](https://www.mathworks.com/matlabcentral/fileexchange/83758-horace-euphonic-interface)
toolbox.

The code itself has been refactored to remove most of the Matlab code.
Instead most of this code (to construct the lattices and grids) has
been translated to Python and incorporated into `brille` itself.
A [light_python_wrapper](https://github.com/pace-neutrons/light_python_wrapper)
is used to wrap the Python code for access by Matlab.

## Minor changes

Additional online help text and a function to install brille from Matlab
has been added. The code is now also wrapped as a Matlab toolbox 
(`mltbx` file) which can be downloaded and installed by the "Add-on"
system from the File-Exchange.


# [v0.1.0](https://github.com/brille/brillem/compare/212c6a6...v0.1.0)

Initial release

Verified to work with [brille v0.4.2](https://github.com/brille/brille/releases/tag/v0.4.2), 
[Euphonic v0.3.0](https://github.com/pace-neutrons/Euphonic/releases/tag/v0.3.0) and 
[brilleu v0.2.1](https://github.com/brille/brilleu/releases/tag/v0.2.1)
