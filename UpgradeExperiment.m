function varargout = UpgradeExperiment(args)
%UPGRADEEXPERIMENT Fetch lastest release from github
%   This will just check if there is a newer version of this experiment and
%   fetch all the required files of this newer version from github.
%   
%   Example usage:
%
%     % this will check if there is a new version only
%     UpgradeExperiment("InstallNow", "no")
%
%     % these two are identical, both check new version and install it
%     UpgradeExperiment
%     UpgradeExperiment("InstallNow", "yes")
%
%     % the newer version number, older version number and the status
%     % number are the first second and third outputs respectively
%     [newver, oldver, status] = UpgradeExperiment(__);
arguments
    args.InstallNow {mustBeMember(args.InstallNow, ["yes", "no"])} = "yes"
end
status = 0;
oldver = ExpVersion;
gh_host = 'https://github.com';
gh_handle = 'psychelzh';
repo_name = 'two-back-tests';
path_repo = sprintf('%s/%s/%s', gh_host, gh_handle, repo_name);
page_tags = sprintf('%s/tags', path_repo);
fprintf('Checking if there is a newer version...\n')
try
    % get the latest tag
    data_tags = webread(page_tags);
catch ME
    if strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
        status = 1;
    end
    if strcmp(ME.identifier, 'MATLAB:webservices:UnknownHost')
        status = 2;
    end
end
if status == 0
    tags = regexprep( ...
        extractBetween( ...
        extractBetween(data_tags, ...
        '<h4 class="flex-auto min-width-0 pr-2 pb-1 commit-title">', ...
        '<span class="hidden-text-expander inline">'), ...
        '>', '<'), ...
        '\s', '');
    newver = tags{1};
    if string(newver) > string(oldver)
        switch args.InstallNow
            case "yes"
                fprintf('A new version (%s) of expriment is found, will try to upgrade now.\n', newver)
                page_newver = sprintf('%s/archive/%s.zip', path_repo, newver);
                temp_newzip = fullfile(tempdir, 'new.zip');
                try
                    fprintf('Start downloading...')
                    websave(temp_newzip, page_newver);
                    fprintf('Completed.\n')
                catch ME
                    if strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
                        status = 1;
                    end
                    if strcmp(ME.identifier, 'MATLAB:webservices:UnknownHost')
                        status = 2;
                    end
                end
                unzip(temp_newzip, tempdir)
                fprintf('Upgrading...')
                copy_folder = fullfile(tempdir, sprintf('%s-%s', repo_name, newver));
                try
                    copyfile(copy_folder, '.')
                catch
                    status = 3;
                end
                delete(temp_newzip)
                rmdir(copy_folder, 's')
                fprintf('Completed.\n')
            case "no"
                fprintf('A new version (%s) of expriment is found, please run `%s` to upgrade.\n', newver, mfilename)
        end
    else
        fprintf('You are awesome! Current version (%s) you used is the latest.\n', oldver)
    end
end
% turn error as meaning warning
if status == 1
    warning('Experiment:Upgrade:NotFound', ...
        'Upgrade failed! Some of the requested web pages not found.')
end
if status == 2
    warning('Experiment:Upgrade:NetFailure', ...
        'Upgrade failed! Please check your network and make sure you have access to %s.', gh_host)
end
if status == 3
    warning('Experiment:Upgrade:InstallError', ...
        'Upgrade failed! Something unexpected happened when copying download files.')
end
if nargout > 0
    varargout{1} = newver;
end
if nargout > 1
    varargout{2} = oldver;
end
if nargout > 2
    varargout{3} = status;
end
end
