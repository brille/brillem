function output = release(upload_flag)
% Create a new version on github
% Syntax:
%   release(upload_flag, brille_version)
% Inputs:
%   upload_flag      - whether to upload to github (default: 'no_upload'/false)
%                    set to `true` or 'upload' to upload to github 
%
% First you must `git tag` a version (prefix with 'v'),
% then push the tag and run this. E.g. (within Matlab)
%   !git tag v0.1.0
%   !git push origin v0.1.0
%   release()
%
% Also, you must have a github personal access token
% stored as an environment variable $GITHUB_TOKEN
% You should also edit and update CHANGELOG.md
% If you don't a warning will be issued and the
% release will not be uploaded unless upload_flag='force'
%
    if nargin < 1; upload_flag = 'no_upload'; end
    this_dir = fileparts(mfilename('fullpath'));
    cur_dir = pwd;
    cd(this_dir);

    restore_git_repo()
    version = ['v' mersioneer()];
    version = regexprep(version, '+.*', ''); % Strip trailing string
    update_brille_version();
    create_mltbx(version);
    output = upload_to_github(upload_flag, version);

    cd(cur_dir);
end

function output = upload_to_github(upload_flag, version)
    if nargin < 1; upload_flag = 'no_upload'; end
    if strcmp(upload_flag, 'upload') || ...
       strcmp(upload_flag, 'force') || (islogical(upload_flag) && upload_flag)
        do_upload = true;
        if isempty(getenv('GITHUB_TOKEN'))
            warning('GITHUB_TOKEN environment variable not set, will not upload to github');
            do_upload = false;
        end
    else
        do_upload = false;
    end
    % Check versions
    fid = fopen('CHANGELOG.md');
    changelog = fread(fid, '*char')';
    fclose(fid);
    change_ver = regexp(changelog, '# \[(?<ver>\S*)\]\(http', 'names').ver;
    if ~strcmp(change_ver, version)
        wrnstr = sprintf('Git tag version "%s" does not match changelog version "%s".', ...
                         version, change_ver);
        if strcmp(upload_flag, 'force')
            wrnstr = [wrnstr ' But, we will still upload to github because upload_flag=''force''.'];
        else
            wrnstr = [wrnstr ' We will not upload to github. ' ...
                      'If you want to force upload, set upload_flag=''force''.'];
            do_upload = false;
        end
        warning(wrnstr);
    end
    % Extract description text
    descs = regexp(changelog, '# \[\S*\]\(http\S*\)', 'split'); % cell array of all descriptions
    desc = strip(descs{2});  % The first block is before the first version.
    % payload is a json string
    payload = jsonencode(struct('tag_name', version, 'target_commitish', 'master', 'name', version, ...
                                'body', desc, 'draft', true, 'prerelease', false));
    if ~do_upload
        output = sprintf('Would send: %s\n', payload);
        return
    end
    % Reads the mltbx file as bytes
    this_dir = fileparts(mfilename('fullpath'));
    fid = fopen(fullfile(this_dir, 'mltbx', 'brillem.mltbx'));
    mltbx = fread(fid, '*uint8');
    fclose(fid);
    % Push release to github
    import matlab.net.http.*
    headers = field.AuthorizationField('Authorization', sprintf('token %s', getenv('GITHUB_TOKEN')));
    request = RequestMessage(RequestMethod.POST, headers, MessageBody(payload));
    response = request.send('https://api.github.com/repos/brille/brillem/releases');
    if response.StatusCode ~= StatusCode.Created
        warning('Something went wrong creating the release. Github response returned');
        output = response;
        return
    end
    % Upload mltbx to github
    upload_url = regexp(response.Body.Data.upload_url, '^(?<url>[^{]*)', 'names').url;
    headers = [headers matlab.net.http.field.ContentTypeField(MediaType('application/octet-stream'))];
    reqmltbx = RequestMessage(RequestMethod.POST, headers, MessageBody(mltbx));
    respmltbx = reqmltbx.send(sprintf('%s?name=brillem.mltbx', upload_url));
    if response.StatusCode ~= StatusCode.Created
        warning('Something went wrong uploading mltbx file. Github response returned');
        output = respmltbx;
        return
    end
    output = sprintf('Successfully created release %s', version);
end

function update_brille_version()
    % Get brille version from requirements.txt file
    this_dir = fileparts(mfilename('fullpath'));
    fid = fopen(fullfile(this_dir, 'requirements.txt'));
    req = fread(fid, '*char')';
    fclose(fid);
    brille_version = regexp(req, 'brille[=>]*(?<ver>[0-9\.]*)', 'names').ver;
    this_dir = fileparts(mfilename('fullpath'));
    ver_file = fullfile(this_dir, '+brille', 'private', 'required_modules.m');
    fid = fopen(ver_file);
    req = fread(fid, '*char')';
    fclose(fid);
    fid = fopen(ver_file, 'w');
    new_req = regexprep(req, '''0.0.0''', sprintf('''%s''', brille_version));
    fwrite(fid, new_req);
    fclose(fid);
end

function create_mltbx(version)
    this_dir = fileparts(mfilename('fullpath'));
    cur_dir = pwd;
    if ~exist(fullfile(this_dir, 'light_python_wrapper', '+light_python_wrapper'), 'dir')
        cd(this_dir);
        [rc, git_submodule] = system('git submodule update --init light_python_wrapper');
        cd(cur_dir);
        if rc ~= 0; error('"git submodule update" failed to update light_python_wrapper'); end
    end
    copyfile(fullfile(this_dir, '+brille'), fullfile(this_dir, 'mltbx', '+brille'));
    copyfile(fullfile(this_dir, 'light_python_wrapper', '+light_python_wrapper'), ...
             fullfile(this_dir, 'mltbx', '+light_python_wrapper'));
    cd(fullfile(this_dir, 'mltbx'));
    fid = fopen('brillem.prj');
    text = fread(fid, inf, '*char')';
    fclose(fid);
    fid = fopen('brillem.prj', 'w');
    text = regexprep(text, 'TO_BE_REPLACED', version);
    fwrite(fid, text);
    fclose(fid);
    matlab.addons.toolbox.packageToolbox('brillem.prj', 'brillem.mltbx');
    cd(cur_dir);
end

function restore_git_repo()
    % Restore changes to files made by previous runs of this script
    this_dir = fileparts(mfilename('fullpath'));
    cur_dir = pwd;
    cd(this_dir);
    [rc1, ~] = system('git checkout -- +brille/private/required_modules.m');
    [rc2, ~] = system('git checkout -- mltbx/brillem.prj');
    if rc1 ~= 0 && rc2 ~=0
        error('"git restore" command failed to restore the repository'); 
    end
    cd(cur_dir);
end

function version = mersioneer(tag_prefix)
% A very poor man's reimplemenation of versioneer, to get version from git tags
    if nargin < 1
        tag_prefix = "v*";
    end
    try
        [rc, git_describe] = system(sprintf('git describe --tags --dirty --always --long --match "%s*"', tag_prefix));
        if rc ~= 0; error('"git describe" command failed to return a version string'); end
        git_describe = strtrim(git_describe);
        [rc, long] = system('git rev-parse HEAD');
        if rc ~= 0; error('"git rev-parse HEAD" command failed to return a commit SHA'); end
        short = git_describe(1:7);  % maybe improved later
        if any(regexp(git_describe, '-dirty$'))
            dirtystring = '.dirty';
        else
            dirtystring = '';
        end
        if any(regexp(git_describe, '-'))
            [~, groups] = regexp(git_describe, '^(.+)-(\d+)-g([0-9a-f]+)', 'match', 'tokens');
            closest_tag = groups{1}{1}((numel(tag_prefix)+1):end);
            distance = groups{1}{2};
            short = groups{1}{3};
        else
            closest_tag = sprintf('%s0.0.0', tag_prefix);
            [rc, distance] = system('git rev-list HEAD --count');
            if rc ~= 0; error('"git rev-parse HEAD" command failed to return a commit SHA'); end
        end
        plus_or_dot = '+';
        if contains(closest_tag, '+')
            plus_or_dot = '.';
        end
        version = sprintf('%s%s%s.%g%s', closest_tag, plus_or_dot, distance, short, dirtystring);
    catch ME
        % Converts errors to warnings and return basic version
        fprintf(2, '%s\n', strrep(getReport(ME, 'extended', 'hyperlinks', 'on'), 'Error', 'Warning'));
        version = '0.0.0+unknown';
    end
end
