this_dir = fileparts(mfilename('fullpath'));
cur_dir = pwd;
cd(fullfile(this_dir, '..'));
addpath('.');
addpath('light_python_wrapper');
addpath(genpath('spinw'));

cd(fullfile(this_dir));
test_spinw_brille_basic;
test_spinw_brille_tutorials;

cd(cur_dir);
