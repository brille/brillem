function run_tests()

this_dir = fileparts(mfilename('fullpath'));
cd(fullfile(this_dir, '..'));
addpath('.');
addpath('light_python_wrapper');
addpath(genpath('spinw'));

cd(fullfile(this_dir));
test_spinw_brille_basic;
test_spinw_brille_tutorials;

end
