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
        DialogEditUser % User information editing
        UserCreateTime % Store the time when user is created
    end
    
    properties (Access = public)
        UsersHistory % users load from disk
        UserCurrent % store the info of current user
        UserEvents % store all the operations of current user
    end
    
    properties (Access = private, Constant)
        ExperimentName = "TwoBack" % used when storing data
        DataFolder = "data" % store user data
        AssetsFolder = ".assets" % store data used in app building
        UsersHistoryFile = "users_history.txt" % store users history
    end
    
    methods (Access = private)
        
        % turn off all operation but creation
        function initialize(app)
            app.UserId.Text = "未注册";
            app.UserName.Text = "未注册";
            app.UserSex.Text = "未注册";
            app.UserDob.Text = "未注册";
            app.Create.Enable = "on";
            app.Modify.Enable = "off";
            app.DigitPanel.Enable = "off";
            app.DigitPracPC.Visible = "off";
            app.WordPanel.Enable = "off";
            app.WordPracPC.Visible = "off";
            app.SpacePanel.Enable = "off";
            app.SpacePracPC.Visible = "off";
        end
        % functions used when running an experiment
        % a practice workflow
        function practiceWorkflow(app, tasktype)
            tasktype_upper = app.capitalize_first(tasktype);
            [rec, status] = app.startExp(tasktype, "prac");
            app.colorStatus(tasktype, "prac", status);
            app.dispPC(tasktype, rec, status);
            app.saveExpData(tasktype, "prac", rec, status)
            app.appendEvent(tasktype_upper + "Prac");
            app.(tasktype_upper + "Test").Enable = "on";
        end
        % a test workflow
        function testWorkflow(app, tasktype)
            tasktype_upper = app.capitalize_first(tasktype);
            [rec, status] = app.startExp(tasktype, "test");
            app.colorStatus(tasktype, "test", status);
            app.saveExpData(tasktype, "test", rec, status)
            app.appendEvent(tasktype_upper + "Test");
            if status == 0
                app.(tasktype_upper + "Test").Enable = "on";
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
            if status == 0
                app.(label_update).Visible = "on";
                app.(label_update).Text = sprintf('正确率：%.0f%%', ...
                    sum(rec.acc == 1) / sum(~isnan(rec.acc)) * 100);
            end
        end
        % save the recorded responses (VERY IMPORTANT)
        function saveExpData(app, tasktype, taskpart, rec, status)
            data_file = sprintf('%s-Sub_%d-Task_%s-Part_%s', ...
                app.ExperimentName, app.UserCurrent.Id, ...
                tasktype, taskpart);
            if status ~= 0
                [~, temp_suffix] = fileparts(tempname);
                data_file = sprintf('Tmp_%s_%s', data_file, temp_suffix);
            end
            writetable(rec, fullfile(app.DataFolder, data_file), "Delimiter", "\t")
        end
        % check completion
        function is_completed = checkCompletion(app)
            check_events = ["DigitTest", "WordTest", "SpaceTest"];
            is_completed = all(ismember(check_events, app.UserEvents));
        end
        % helper functions (these should be Static, but no way?)
        function str_out = capitalize_first(~, str_in)
            str_out = upper(extractBefore(str_in, 2)) + ...
                extractAfter(str_in, 1);
        end
        
    end
    
    methods (Access = public)
        
        % user creation and updating
        function updateUser(app, user)
            % update current user info
            app.UserId.Text = num2str(user.Id);
            app.UserName.Text = user.Name;
            app.UserSex.Text = user.Sex;
            app.UserDob.Text = datestr(user.Dob, 'yyyy-mm-dd');
            app.UserCurrent = struct2table(user);
            app.UserCurrent.createTime = app.UserCreateTime;
        end
        function createUser(app, user)
            % set the user creation time
            app.UserCreateTime = datetime("now");
            % update user info
            app.updateUser(user);
        end
        % output for app use in future
        function outputUsersHistory(app)
            writetable(vertcat(app.UsersHistory, app.UserCurrent), ...
                fullfile(app.AssetsFolder, app.UsersHistoryFile))
        end
        % output for experimenter use
        function saveUserHistory(app)
            writetable(vertcat(app.UsersHistory, app.UserCurrent), ...
                fullfile(app.DataFolder, "users"), ...
                "FileType", "text", ...
                "Delimiter", "\t")
        end
        % append events to user events structure
        function appendEvent(app, event)
            app.UserEvents = horzcat(app.UserEvents, event);
        end
        % set the app ready for experiment
        function getReady(app)
            % enable user modification and creation
            app.Create.Enable = "on";
            app.Modify.Enable = "on";
            % enable all the practice
            app.DigitPanel.Enable = "on";
            app.DigitPrac.Enable = "on";
            app.DigitTest.Enable = "off";
            % enable all the practice
            app.WordPanel.Enable = "on";
            app.WordPrac.Enable = "on";
            app.WordTest.Enable = "off";
            % enable all the practice
            app.SpacePanel.Enable = "on";
            app.SpacePrac.Enable = "on";
            app.SpaceTest.Enable = "off";
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
            history_file = fullfile(app.AssetsFolder, app.UsersHistoryFile);
            if exist(history_file, "file")
                app.UsersHistory = readtable(history_file, 'TextType', 'string');
            else
                app.UsersHistory = table;
            end
            % initialize all the controllers
            app.initialize()
            % add user code directory
            addpath("src")
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % check if user has completed if there's already one user
            if ~isempty(app.UserEvents) && app.UserCurrent.Id ~= 0 % user id 0 is of internal use
                is_completed = app.checkCompletion();
                if ~is_completed
                    selection = uiconfirm(app.UIFigure, ...
                        "当前用户还未完成所有测试，现在退出将导致当前用户不能继续测试，是否确认退出", "退出确认", ...
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
            if ~isempty(app.UserEvents) && app.UserCurrent.Id ~= 0 % user id 0 is of internal use
                is_completed = app.checkCompletion();
                if ~is_completed
                    selection = uiconfirm(app.UIFigure, ...
                        "当前用户还未完成所有测试，新建用户将导致当前用户不能继续测试，是否继续新建", "新建确认", ...
                        "Options", ["是", "否"], ...
                        "DefaultOption", "否");
                    if selection == "否"
                        return
                    end
                end
            end
            % Create new user will trigger app initializing
            app.initialize();
            % clear user events
            app.UserEvents = [];
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
            % Disable creation and modification while modifying
            app.Modify.Enable = "off";
            app.Create.Enable = "off";
            % a quick collection of user information
            user.Id = str2double(app.UserId.Text);
            user.Name = app.UserName.Text;
            user.Sex = app.UserSex.Text;
            user.Dob = datetime(app.UserDob.Text);
            app.DialogEditUser = CreateOrModifyUser(app, user);
            % Enable creation and modification after calling
            waitfor(app.DialogEditUser.UIFigure)
            app.Create.Enable = "on";
            app.Modify.Enable = "on";
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
            app.Modify.Position = [33 50 88 26];
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
            app.Create.Position = [144 50 88 26];
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