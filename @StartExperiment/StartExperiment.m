classdef StartExperiment < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure              matlab.ui.Figure
        ParticipantInfoPanel  matlab.ui.container.Panel
        UserNameLabel         matlab.ui.control.Label
        UserSexLabel          matlab.ui.control.Label
        UserDobLabel          matlab.ui.control.Label
        UserName              matlab.ui.control.Label
        UserSex               matlab.ui.control.Label
        UserDob               matlab.ui.control.Label
        Modify                matlab.ui.control.Button
        UserInfoLabel         matlab.ui.control.Label
        Create                matlab.ui.control.Button
        UserIdLabel           matlab.ui.control.Label
        UserId                matlab.ui.control.Label
        Load                  matlab.ui.control.Button
        DigitPanel            matlab.ui.container.Panel
        DigitPrac             matlab.ui.control.Button
        DigitTest             matlab.ui.control.Button
        DigitLabel            matlab.ui.control.Label
        DigitPracPC           matlab.ui.control.Label
        WordPanel             matlab.ui.container.Panel
        WordPrac              matlab.ui.control.Button
        WordTest              matlab.ui.control.Button
        WordLabel             matlab.ui.control.Label
        WordPracPC            matlab.ui.control.Label
        SpacePanel            matlab.ui.container.Panel
        SpacePrac             matlab.ui.control.Button
        SpaceTest             matlab.ui.control.Button
        SpaceLabel            matlab.ui.control.Label
        SpacePracPC           matlab.ui.control.Label
    end

    properties (Access = private)
        DialogEditUser % Child UI: user information editing
        DialogLoadUser % Child UI: load old user
        UsersHistory % users load from disk
        EventsHistory % users' events load from disk
        User % store the info of current user
        Events % store all the operations of current user
    end
    
    properties (Access = private, Constant)
        ExperimentName = "TwoBack" % used when storing data
        DataFolder = "data" % store user data
        AssetsFolder = ".assets" % store data used in app building
        UsersHistoryFile = "users_history.txt" % store users history
        EventsHistoryFile = "events_history.txt" % store users' events history
    end
    
    methods (Access = private)
        
        % set app ready for a new user
        function initialize(app)
            % load all the history user info
            users_history_file = fullfile(app.AssetsFolder, app.UsersHistoryFile);
            if exist(users_history_file, "file")
                app.UsersHistory = readtable(users_history_file, 'TextType', 'string');
            else
                app.UsersHistory = table;
            end
            % load all the history user events
            events_history_file = fullfile(app.AssetsFolder, app.EventsHistoryFile);
            if exist(events_history_file, "file")
                app.EventsHistory = readtable(events_history_file, 'TextType', 'string');
            else
                app.EventsHistory = table;
            end
            % no user info
            app.UserId.Text = "未注册";
            app.UserName.Text = "未注册";
            app.UserSex.Text = "未注册";
            app.UserDob.Text = "未注册";
            % enable creation but disable modification
            app.Create.Enable = "on";
            app.Modify.Enable = "off";
            % enable loading if history is not empty
            if isempty(app.UsersHistory)
                app.Load.Enable = "off";
            else
                app.Load.Enable = "on";
            end
            % disable all the experiment part because there is no user
            arrayfun(@initPanel, ["Digit", "Word", "Space"])
            % clear current user info
            app.User = table;
            % clear current user events
            app.Events = table;
            function initPanel(tasktype)
                app.(tasktype + "Panel").Enable = "off";
                app.(tasktype + "Prac").BackgroundColor = [0.96, 0.96, 0.96];
                app.(tasktype + "PracPC").Visible = "off";
                app.(tasktype + "Test").BackgroundColor = [0.96, 0.96, 0.96];
            end
        end
        % functions used when running an experiment
        % a practice workflow
        function practiceWorkflow(app, tasktype)
            tasktype_upper = app.capitalize_first(tasktype);
            [rec, status] = app.startExp(tasktype, "prac");
            app.colorStatus(tasktype, "prac", status);
            app.dispPC(tasktype, rec, status);
            app.outputExpData(tasktype, "prac", rec, status)
            app.appendEvent(tasktype_upper + "Prac");
            app.(tasktype_upper + "Test").Enable = "on";
        end
        % a test workflow
        function testWorkflow(app, tasktype)
            tasktype_upper = app.capitalize_first(tasktype);
            [rec, status] = app.startExp(tasktype, "test");
            app.colorStatus(tasktype, "test", status);
            app.outputExpData(tasktype, "test", rec, status)
            if status ~= 0
                app.appendEvent(tasktype_upper + "TestError");
                app.(tasktype_upper + "Test").Enable = "on";
            else
                app.appendEvent(tasktype_upper + "TestSucceed");
                % when succeeded, the whole panel will be disabled
                app.(tasktype_upper + "Panel").Enable = "off";
            end
        end
        % main stimuli presentation (this should be "Static", but no way?)
        function [rec, status] = startExp(~, tasktype, taskpart)
            % run this function from "src" folder
            [rec, status] = start_two_back(...
                "TaskType", tasktype, ...
                "ExperimentPart", taskpart);
        end
        % color buttons to signal completion status
        function colorStatus(app, tasktype, taskpart, status)
            calling = app.capitalize_first(tasktype) + ...
                app.capitalize_first(taskpart);
            if status == 0
                app.(calling).BackgroundColor = "green";
            else
                app.(Calling).BackgroundColor = "red";
            end
        end
        % display percent of correct for practice part
        function dispPC(app, tasktype, rec, status)
            label_update = app.capitalize_first(tasktype) + "PracPC";
            app.(label_update).Visible = "on";
            if status == 0
                pc = sum(rec.acc == 1) / sum(~isnan(rec.acc)) * 100;
            else
                pc = nan;
            end
            if ~isnan(pc)
                app.(label_update).FontColor = "black";
                app.(label_update).Text = sprintf("正确率：%.0f%%", pc);
            else
                app.(label_update).FontColor = "red";
                app.(label_update).Text = "请重新练习";
            end
        end
        % save the recorded responses (VERY IMPORTANT)
        function outputExpData(app, tasktype, taskpart, rec, status)
            data_file = sprintf('%s-Sub_%d-Task_%s-Part_%s', ...
                app.ExperimentName, app.User.Id, ...
                tasktype, taskpart);
            if status ~= 0
                [~, temp_suffix] = fileparts(tempname);
                data_file = sprintf('Tmp_%s_%s', data_file, temp_suffix);
            end
            writetable(rec, fullfile(app.DataFolder, data_file), "Delimiter", "\t")
        end
        % check completion
        function is_completed = checkCompletion(app)
            check_events = ["DigitTestSucceed", "WordTestSucceed", "SpaceTestSucceed"];
            is_completed = all(ismember(check_events, app.Events.Event));
        end
        % helper functions (these should be Static, but no way?)
        function str_out = capitalize_first(~, str_in)
            str_out = upper(extractBefore(str_in, 2)) + extractAfter(str_in, 1);
        end
        
    end
    
    methods (Access = public)
        
        % user edition
        function createUser(app, user)
            % add creation time
            user.CreateTime = datetime("now");
            % update user info
            app.updateUser(user);
        end
        function updateUser(app, user, events)
            % update current user info in panel and property
            app.UserId.Text = num2str(user.Id);
            app.UserName.Text = user.Name;
            app.UserSex.Text = user.Sex;
            app.UserDob.Text = datestr(user.Dob, 'yyyy-mm-dd');
            app.User.Id = user.Id;
            app.User.Name = user.Name;
            app.User.Sex = user.Sex;
            app.User.Dob = user.Dob;
            if ismember('CreateTime', fieldnames(user))
                % add create time if there is one
                app.User.CreateTime = user.CreateTime;
            end
            if nargin >= 3
                app.Events = events;
            end
        end
        function found = loadUser(app, user_id, args)
            arguments
                app
                user_id
                args.Pull (1,1) {islogical} = true
            end
            % check if user exists
            if isempty(app.UsersHistory) || ~ismember(user_id, app.UsersHistory.Id)
                found = false;
                user = table;
                events = table;
            else
                found = true;
                % get info from history
                user = app.UsersHistory(app.UsersHistory.Id == user_id, :);
                events = app.EventsHistory(app.EventsHistory.UserId == user_id, :);
            end
            if args.Pull
                % update ui and data
                app.updateUser(user, events);
                % clear history
                app.UsersHistory(app.UsersHistory.Id == user_id, :) = [];
                app.EventsHistory(app.EventsHistory.UserId == user_id, :) = [];
            end
        end
        % output for app use in future
        function saveUsersHistory(app)
            writetable(vertcat(app.UsersHistory, app.User), ...
                fullfile(app.AssetsFolder, app.UsersHistoryFile))
        end
        function saveEventsHistory(app)
            writetable(vertcat(app.EventsHistory, app.Events), ...
                fullfile(app.AssetsFolder, app.EventsHistoryFile))
        end
        % output for experimenter use
        function outputUsersHistory(app)
            writetable(vertcat(app.UsersHistory, app.User), ...
                fullfile(app.DataFolder, "users"), ...
                "FileType", "text", ...
                "Delimiter", "\t")
        end
        % append events to user events table
        function appendEvent(app, event)
            app.Events = vertcat(app.Events, ...
                table(app.User.Id, event, ...
                'VariableNames', {'UserId', 'Event'}));
            % update history after a new meaningful event happened
            if app.User.Id ~= 0
                app.saveUsersHistory();
                app.saveEventsHistory();
                app.outputUsersHistory();
            end
        end
        % set the app ready for experiment
        function getReady(app)
            % enable user modification and creation
            app.Create.Enable = "on";
            app.Modify.Enable = "on";
            % enable experiment based on progress
            arrayfun(@checkProgress, ["Digit", "Word", "Space"]);
            function checkProgress(tasktype)
                if ~ismember(tasktype + "TestSucceed", app.Events.Event)
                    app.(tasktype + "Panel").Enable = "on";
                    app.(tasktype + "Prac").Enable = "on";
                    app.(tasktype + "Test").Enable = "off";
                end
            end
        end
        
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % make sure app data folder is existing
            if ~isfolder(app.AssetsFolder)
                mkdir(app.AssetsFolder)
            end
            % make sure user data folder is existing
            if ~isfolder(app.DataFolder)
                mkdir(app.DataFolder)
            end
            % initialize all the controllers
            app.initialize()
            % add user code directory
            addpath("src")
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % check if user has completed if there's already one user
            if ~isempty(app.Events) && app.User.Id ~= 0 % user id 0 is of internal use
                is_completed = app.checkCompletion();
                if ~is_completed
                    selection = uiconfirm(app.UIFigure, ...
                        "当前被试还未完成所有测试，是否确认退出", "退出确认", ...
                        "Options", ["是", "否"], ...
                        "DefaultOption", "否");
                    if selection == "否"
                        return
                    end
                end
            end
            delete(app)
            % remove user code directory
            rmpath("src")
        end

        % Button pushed function: Create
        function CreateButtonPushed(app, event)
            % check if user has completed if there's already one user
            if ~isempty(app.Events) && app.User.Id ~= 0 % user id 0 is of internal use
                is_completed = app.checkCompletion();
                if ~is_completed
                    selection = uiconfirm(app.UIFigure, ...
                        "当前被试还未完成所有测试，是否继续新建被试", "新建确认", ...
                        "Options", ["是", "否"], ...
                        "DefaultOption", "否");
                    if selection == "否"
                        return
                    end
                end
            end
            % Create new user will trigger app initializing
            app.initialize();
            % Disable creation while creating
            app.Create.Enable = "off";
            % Call app without user information
            app.DialogEditUser = CreateOrModifyUser(app);
            % Enable creation after calling
            waitfor(app.DialogEditUser.UIFigure)
            app.Create.Enable = "on";
        end

        % Button pushed function: Modify
        function ModifyButtonPushed(app, event)
            % Disable modification while modifying
            app.Modify.Enable = "off";
            app.DialogEditUser = CreateOrModifyUser(app, app.User);
            % Enable modification after modifying
            waitfor(app.DialogEditUser.UIFigure)
            app.Modify.Enable = "on";
        end

        % Button pushed function: Load
        function LoadButtonPushed(app, event)
            % check if user has completed if there's already one user
            if ~isempty(app.Events) && app.User.Id ~= 0 % user id 0 is of internal use
                is_completed = app.checkCompletion();
                if ~is_completed
                    selection = uiconfirm(app.UIFigure, ...
                        "当前被试还未完成所有测试，是否继续导入已有用户", "导入确认", ...
                        "Options", ["是", "否"], ...
                        "DefaultOption", "否");
                    if selection == "否"
                        return
                    end
                end
            end
            % Load old user will trigger app initializing
            app.initialize();
            % Disable loading while loading
            app.Load.Enable = "off";
            app.DialogLoadUser = LoadUser(app, app.UsersHistory, app.EventsHistory);
            % Enable loading after loading
            waitfor(app.DialogLoadUser.UIFigure)
            app.Load.Enable = "on";
        end

        % Button pushed function: DigitPrac
        function DigitPracButtonPushed(app, event)
            app.practiceWorkflow("digit")
        end

        % Button pushed function: DigitTest
        function DigitTestButtonPushed(app, event)
            app.testWorkflow("digit")
        end

        % Button pushed function: WordPrac
        function WordPracButtonPushed(app, event)
            app.practiceWorkflow("word")
        end

        % Button pushed function: WordTest
        function WordTestButtonPushed(app, event)
            app.testWorkflow("word")
        end

        % Button pushed function: SpacePrac
        function SpacePracButtonPushed(app, event)
            app.practiceWorkflow("space")
        end

        % Button pushed function: SpaceTest
        function SpaceTestButtonPushed(app, event)
            app.testWorkflow("space")
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 800 600];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create ParticipantInfoPanel
            app.ParticipantInfoPanel = uipanel(app.UIFigure);
            app.ParticipantInfoPanel.Position = [271 283 260 292];

            % Create UserNameLabel
            app.UserNameLabel = uilabel(app.ParticipantInfoPanel);
            app.UserNameLabel.HorizontalAlignment = 'center';
            app.UserNameLabel.FontName = 'SimHei';
            app.UserNameLabel.FontSize = 15;
            app.UserNameLabel.Position = [56 164 35 22];
            app.UserNameLabel.Text = '姓名';

            % Create UserSexLabel
            app.UserSexLabel = uilabel(app.ParticipantInfoPanel);
            app.UserSexLabel.FontName = 'SimHei';
            app.UserSexLabel.FontSize = 15;
            app.UserSexLabel.Position = [56 127 35 22];
            app.UserSexLabel.Text = '性别';

            % Create UserDobLabel
            app.UserDobLabel = uilabel(app.ParticipantInfoPanel);
            app.UserDobLabel.FontName = 'SimHei';
            app.UserDobLabel.FontSize = 15;
            app.UserDobLabel.Position = [56 91 35 22];
            app.UserDobLabel.Text = '生日';

            % Create UserName
            app.UserName = uilabel(app.ParticipantInfoPanel);
            app.UserName.HorizontalAlignment = 'center';
            app.UserName.FontName = 'SimHei';
            app.UserName.FontSize = 15;
            app.UserName.Position = [103 164 101 22];
            app.UserName.Text = '未注册';

            % Create UserSex
            app.UserSex = uilabel(app.ParticipantInfoPanel);
            app.UserSex.HorizontalAlignment = 'center';
            app.UserSex.FontName = 'SimHei';
            app.UserSex.FontSize = 15;
            app.UserSex.Position = [103 127 101 22];
            app.UserSex.Text = '未注册';

            % Create UserDob
            app.UserDob = uilabel(app.ParticipantInfoPanel);
            app.UserDob.HorizontalAlignment = 'center';
            app.UserDob.FontName = 'SimHei';
            app.UserDob.FontSize = 15;
            app.UserDob.Position = [103 91 101 22];
            app.UserDob.Text = '未注册';

            % Create Modify
            app.Modify = uibutton(app.ParticipantInfoPanel, 'push');
            app.Modify.ButtonPushedFcn = createCallbackFcn(app, @ModifyButtonPushed, true);
            app.Modify.FontName = 'SimHei';
            app.Modify.FontSize = 15;
            app.Modify.Position = [30 56 88 26];
            app.Modify.Text = '修改';

            % Create UserInfoLabel
            app.UserInfoLabel = uilabel(app.ParticipantInfoPanel);
            app.UserInfoLabel.FontName = 'SimHei';
            app.UserInfoLabel.FontSize = 20;
            app.UserInfoLabel.Position = [87 247 85 26];
            app.UserInfoLabel.Text = '当前被试';

            % Create Create
            app.Create = uibutton(app.ParticipantInfoPanel, 'push');
            app.Create.ButtonPushedFcn = createCallbackFcn(app, @CreateButtonPushed, true);
            app.Create.FontName = 'SimHei';
            app.Create.FontSize = 15;
            app.Create.Position = [141 56 88 26];
            app.Create.Text = '新建';

            % Create UserIdLabel
            app.UserIdLabel = uilabel(app.ParticipantInfoPanel);
            app.UserIdLabel.FontName = 'SimHei';
            app.UserIdLabel.FontSize = 15;
            app.UserIdLabel.Position = [55 201 35 22];
            app.UserIdLabel.Text = '编号';

            % Create UserId
            app.UserId = uilabel(app.ParticipantInfoPanel);
            app.UserId.HorizontalAlignment = 'center';
            app.UserId.FontName = 'SimHei';
            app.UserId.FontSize = 15;
            app.UserId.Position = [103 201 101 22];
            app.UserId.Text = '未注册';

            % Create Load
            app.Load = uibutton(app.ParticipantInfoPanel, 'push');
            app.Load.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.Load.FontName = 'SimHei';
            app.Load.FontSize = 15;
            app.Load.Position = [86 14 88 26];
            app.Load.Text = '导入';

            % Create DigitPanel
            app.DigitPanel = uipanel(app.UIFigure);
            app.DigitPanel.TitlePosition = 'centertop';
            app.DigitPanel.Position = [78 40 196 208];

            % Create DigitPrac
            app.DigitPrac = uibutton(app.DigitPanel, 'push');
            app.DigitPrac.ButtonPushedFcn = createCallbackFcn(app, @DigitPracButtonPushed, true);
            app.DigitPrac.FontName = 'SimHei';
            app.DigitPrac.FontSize = 15;
            app.DigitPrac.Position = [47 124 100 26];
            app.DigitPrac.Text = '练习';

            % Create DigitTest
            app.DigitTest = uibutton(app.DigitPanel, 'push');
            app.DigitTest.ButtonPushedFcn = createCallbackFcn(app, @DigitTestButtonPushed, true);
            app.DigitTest.FontName = 'SimHei';
            app.DigitTest.FontSize = 15;
            app.DigitTest.Position = [47 52 100 26];
            app.DigitTest.Text = '正式测试';

            % Create DigitLabel
            app.DigitLabel = uilabel(app.DigitPanel);
            app.DigitLabel.HorizontalAlignment = 'center';
            app.DigitLabel.FontName = 'SimHei';
            app.DigitLabel.FontSize = 15;
            app.DigitLabel.Position = [79 171 35 22];
            app.DigitLabel.Text = '数字';

            % Create DigitPracPC
            app.DigitPracPC = uilabel(app.DigitPanel);
            app.DigitPracPC.HorizontalAlignment = 'center';
            app.DigitPracPC.FontName = 'SimHei';
            app.DigitPracPC.Position = [48 93 100 22];
            app.DigitPracPC.Text = '';

            % Create WordPanel
            app.WordPanel = uipanel(app.UIFigure);
            app.WordPanel.Position = [304 40 196 208];

            % Create WordPrac
            app.WordPrac = uibutton(app.WordPanel, 'push');
            app.WordPrac.ButtonPushedFcn = createCallbackFcn(app, @WordPracButtonPushed, true);
            app.WordPrac.FontName = 'SimHei';
            app.WordPrac.FontSize = 15;
            app.WordPrac.Position = [48 124 100 26];
            app.WordPrac.Text = '练习';

            % Create WordTest
            app.WordTest = uibutton(app.WordPanel, 'push');
            app.WordTest.ButtonPushedFcn = createCallbackFcn(app, @WordTestButtonPushed, true);
            app.WordTest.FontName = 'SimHei';
            app.WordTest.FontSize = 15;
            app.WordTest.Position = [49 52 100 26];
            app.WordTest.Text = '正式测试';

            % Create WordLabel
            app.WordLabel = uilabel(app.WordPanel);
            app.WordLabel.HorizontalAlignment = 'center';
            app.WordLabel.FontName = 'SimHei';
            app.WordLabel.FontSize = 15;
            app.WordLabel.Position = [81 171 35 22];
            app.WordLabel.Text = '文字';

            % Create WordPracPC
            app.WordPracPC = uilabel(app.WordPanel);
            app.WordPracPC.HorizontalAlignment = 'center';
            app.WordPracPC.FontName = 'SimHei';
            app.WordPracPC.Position = [47 93 100 22];
            app.WordPracPC.Text = '';

            % Create SpacePanel
            app.SpacePanel = uipanel(app.UIFigure);
            app.SpacePanel.Position = [530 40 196 208];

            % Create SpacePrac
            app.SpacePrac = uibutton(app.SpacePanel, 'push');
            app.SpacePrac.ButtonPushedFcn = createCallbackFcn(app, @SpacePracButtonPushed, true);
            app.SpacePrac.FontName = 'SimHei';
            app.SpacePrac.FontSize = 15;
            app.SpacePrac.Position = [48 124 100 26];
            app.SpacePrac.Text = '练习';

            % Create SpaceTest
            app.SpaceTest = uibutton(app.SpacePanel, 'push');
            app.SpaceTest.ButtonPushedFcn = createCallbackFcn(app, @SpaceTestButtonPushed, true);
            app.SpaceTest.FontName = 'SimHei';
            app.SpaceTest.FontSize = 15;
            app.SpaceTest.Position = [48 52 100 26];
            app.SpaceTest.Text = '正式测试';

            % Create SpaceLabel
            app.SpaceLabel = uilabel(app.SpacePanel);
            app.SpaceLabel.HorizontalAlignment = 'center';
            app.SpaceLabel.FontName = 'SimHei';
            app.SpaceLabel.FontSize = 15;
            app.SpaceLabel.Position = [80 171 35 22];
            app.SpaceLabel.Text = '空间';

            % Create SpacePracPC
            app.SpacePracPC = uilabel(app.SpacePanel);
            app.SpacePracPC.HorizontalAlignment = 'center';
            app.SpacePracPC.FontName = 'SimHei';
            app.SpacePracPC.Position = [48 93 100 22];
            app.SpacePracPC.Text = '';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = StartExperiment

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end