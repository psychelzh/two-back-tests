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
%     % flag indicating newer version is found, latest version number and
%     % the status number are the three supported outputs respectively, and
%     % a status of 0 means succeeded, otherwise not
%     [foundnewer, latestver, status] = UpgradeExperiment(__);
arguments
    args.InstallNow {mustBeMember(args.InstallNow, ["yes", "no"])} = "yes"
end
% if a newer version has been found
foundnewer = false;
% return status, 0 means no error
status = 0;
curver = ExpVersion;
gh_host = 'https://github.com';
gh_handle = 'psychelzh';
repo_name = 'two-back-tests';
path_repo = sprintf('%s/%s/%s', gh_host, gh_handle, repo_name);
page_tags = sprintf('%s/tags', path_repo);
fprintf('Checking if there is a newer version...\n')
try
    % get the latest tag
    data_tags = webread(page_tags);
    % do some basic webscraping to extract all the tags of the repo
    tags = regexprep( ...
        extractBetween( ...
        extractBetween(data_tags, ...
        '<h4 class="flex-auto min-width-0 pr-2 pb-1 commit-title">', ...
        '<span class="hidden-text-expander inline">'), ...
        '>', '<'), ...
        '\s', '');
    % latest tagged version appears first
    latestver = tags{1};
    if string(latestver) > string(curver)
        foundnewer = true;
        switch args.InstallNow
            case "yes"
                fprintf('A new version (%s) of expriment is found, will try to upgrade now.\n', latestver)
                % download the files of the latest version to temp dir
                page_newver = sprintf('%s/archive/%s.zip', path_repo, latestver);
                temp_newzip = fullfile(tempdir, 'new.zip');
                fprintf('Start downloading...')
                websave(temp_newzip, page_newver);
                unzip(temp_newzip, tempdir)
                % copy the upzipped files to working directory
                fprintf('Upgrading...')
                copy_folder = fullfile(tempdir, sprintf('%s-%s', repo_name, latestver));
                copyfile(copy_folder, '.')
                fprintf('Completed.\n')
                % remove all files we generated in temp dir
                delete(temp_newzip)
                rmdir(copy_folder, 's')
            case "no"
                fprintf('A new version (%s) of expriment is found, please run `%s` to upgrade.\n', latestver, mfilename)
        end
    else
        fprintf('You are awesome! Current version (%s) you used is the latest.\n', curver)
    end
catch ME
    % turn error as meaning warning
    if strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
        status = 1;
        warning('Experiment:Upgrade:NotFound', ...
            'Upgrade failed! Some of the requested web pages not found.')
    elseif strcmp(ME.identifier, 'MATLAB:webservices:UnknownHost')
        status = 2;
        warning('Experiment:Upgrade:NetFailure', ...
            'Upgrade failed! Please check your network and make sure you have access to %s.', gh_host)
    else
        status = 3;
        warning('Experiment:Upgrade:InstallError', ...
            'Upgrade failed! Something unexpected happened.')
    end
end
% output if required
if nargout > 0
    varargout{1} = foundnewer;
end
if nargout > 1
    varargout{2} = latestver;
end
if nargout > 2
    varargout{3} = status;
end
end
