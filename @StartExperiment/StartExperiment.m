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
        CurrentUser           matlab.ui.control.Label
        Create                matlab.ui.control.Button
        UserIdLabel           matlab.ui.control.Label
        UserId                matlab.ui.control.Label
        DigitPanel            matlab.ui.container.Panel
        DigitPrac             matlab.ui.control.Button
        DigitTest             matlab.ui.control.Button
        WordPanel             matlab.ui.container.Panel
        WordPrac              matlab.ui.control.Button
        WordTest              matlab.ui.control.Button
        SpacePanel            matlab.ui.container.Panel
        SpacePrac             matlab.ui.control.Button
        SpaceTest             matlab.ui.control.Button
    end

    
    properties (Access = private)
        DialogEditUser % User information editing
    end
    
    methods (Access = private)
        
        function initialize(app)
            % set status for all the controllers
            app.UserId.Text = "未注册";
            app.UserName.Text = "未注册";
            app.UserSex.Text = "未注册";
            app.UserDob.Text = "未注册";
            app.Create.Enable = "on";
            app.Modify.Enable = "off";
            app.DigitPanel.Enable = "off";
            app.WordPanel.Enable = "off";
            app.SpacePanel.Enable = "off";
        end
    end
    
    methods (Access = public)
        
        function updateUser(app, user)
            % public method interchanges user info between apps
            app.UserId.Text = num2str(user.Id);
            app.UserName.Text = user.Name;
            app.UserSex.Text = user.Sex;
            app.UserDob.Text = datestr(user.Dob, 'yyyy-mm-dd');
        end
        
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
            % initialize all the controllers
            app.initialize()
            % add user code directory
            addpath("src")
        end

        % Button pushed function: Create
        function CreateButtonPushed(app, event)
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

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app)
            % remove user code directory
            rmpath("src")
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
            app.ParticipantInfoPanel.Title = 'ParticipantInfo';
            app.ParticipantInfoPanel.Position = [271 283 260 292];

            % Create UserNameLabel
            app.UserNameLabel = uilabel(app.ParticipantInfoPanel);
            app.UserNameLabel.HorizontalAlignment = 'center';
            app.UserNameLabel.FontName = 'SimHei';
            app.UserNameLabel.FontSize = 15;
            app.UserNameLabel.Position = [56 145 35 22];
            app.UserNameLabel.Text = '姓名';

            % Create UserSexLabel
            app.UserSexLabel = uilabel(app.ParticipantInfoPanel);
            app.UserSexLabel.FontName = 'SimHei';
            app.UserSexLabel.FontSize = 15;
            app.UserSexLabel.Position = [56 108 35 22];
            app.UserSexLabel.Text = '性别';

            % Create UserDobLabel
            app.UserDobLabel = uilabel(app.ParticipantInfoPanel);
            app.UserDobLabel.FontName = 'SimHei';
            app.UserDobLabel.FontSize = 15;
            app.UserDobLabel.Position = [56 72 35 22];
            app.UserDobLabel.Text = '生日';

            % Create UserName
            app.UserName = uilabel(app.ParticipantInfoPanel);
            app.UserName.HorizontalAlignment = 'center';
            app.UserName.FontName = 'SimHei';
            app.UserName.FontSize = 15;
            app.UserName.Position = [103 145 101 22];
            app.UserName.Text = '未注册';

            % Create UserSex
            app.UserSex = uilabel(app.ParticipantInfoPanel);
            app.UserSex.HorizontalAlignment = 'center';
            app.UserSex.FontName = 'SimHei';
            app.UserSex.FontSize = 15;
            app.UserSex.Position = [103 108 101 22];
            app.UserSex.Text = '未注册';

            % Create UserDob
            app.UserDob = uilabel(app.ParticipantInfoPanel);
            app.UserDob.HorizontalAlignment = 'center';
            app.UserDob.FontName = 'SimHei';
            app.UserDob.FontSize = 15;
            app.UserDob.Position = [103 72 101 22];
            app.UserDob.Text = '未注册';

            % Create Modify
            app.Modify = uibutton(app.ParticipantInfoPanel, 'push');
            app.Modify.ButtonPushedFcn = createCallbackFcn(app, @ModifyButtonPushed, true);
            app.Modify.FontName = 'SimHei';
            app.Modify.FontSize = 15;
            app.Modify.Position = [33 31 88 26];
            app.Modify.Text = '修改';

            % Create CurrentUser
            app.CurrentUser = uilabel(app.ParticipantInfoPanel);
            app.CurrentUser.FontName = 'SimHei';
            app.CurrentUser.FontSize = 20;
            app.CurrentUser.Position = [87 228 85 26];
            app.CurrentUser.Text = '当前被试';

            % Create Create
            app.Create = uibutton(app.ParticipantInfoPanel, 'push');
            app.Create.ButtonPushedFcn = createCallbackFcn(app, @CreateButtonPushed, true);
            app.Create.FontName = 'SimHei';
            app.Create.FontSize = 15;
            app.Create.Position = [144 31 88 26];
            app.Create.Text = '新建';

            % Create UserIdLabel
            app.UserIdLabel = uilabel(app.ParticipantInfoPanel);
            app.UserIdLabel.FontName = 'SimHei';
            app.UserIdLabel.FontSize = 15;
            app.UserIdLabel.Position = [55 182 35 22];
            app.UserIdLabel.Text = '编号';

            % Create UserId
            app.UserId = uilabel(app.ParticipantInfoPanel);
            app.UserId.HorizontalAlignment = 'center';
            app.UserId.FontName = 'SimHei';
            app.UserId.FontSize = 15;
            app.UserId.Position = [103 182 101 22];
            app.UserId.Text = '未注册';

            % Create DigitPanel
            app.DigitPanel = uipanel(app.UIFigure);
            app.DigitPanel.Title = 'Digit';
            app.DigitPanel.Position = [92 40 196 208];

            % Create DigitPrac
            app.DigitPrac = uibutton(app.DigitPanel, 'push');
            app.DigitPrac.FontName = 'SimHei';
            app.DigitPrac.FontSize = 15;
            app.DigitPrac.Position = [48 135 100 26];
            app.DigitPrac.Text = '练习';

            % Create DigitTest
            app.DigitTest = uibutton(app.DigitPanel, 'push');
            app.DigitTest.FontName = 'SimHei';
            app.DigitTest.FontSize = 15;
            app.DigitTest.Position = [48 63 100 26];
            app.DigitTest.Text = '正式测试';

            % Create WordPanel
            app.WordPanel = uipanel(app.UIFigure);
            app.WordPanel.Title = 'Word';
            app.WordPanel.Position = [303 40 196 208];

            % Create WordPrac
            app.WordPrac = uibutton(app.WordPanel, 'push');
            app.WordPrac.FontName = 'SimHei';
            app.WordPrac.FontSize = 15;
            app.WordPrac.Position = [48 135 100 26];
            app.WordPrac.Text = '练习';

            % Create WordTest
            app.WordTest = uibutton(app.WordPanel, 'push');
            app.WordTest.FontName = 'SimHei';
            app.WordTest.FontSize = 15;
            app.WordTest.Position = [49 63 100 26];
            app.WordTest.Text = '正式测试';

            % Create SpacePanel
            app.SpacePanel = uipanel(app.UIFigure);
            app.SpacePanel.Title = 'Space';
            app.SpacePanel.Position = [514 40 196 208];

            % Create SpacePrac
            app.SpacePrac = uibutton(app.SpacePanel, 'push');
            app.SpacePrac.FontName = 'SimHei';
            app.SpacePrac.FontSize = 15;
            app.SpacePrac.Position = [48 135 100 26];
            app.SpacePrac.Text = '练习';

            % Create SpaceTest
            app.SpaceTest = uibutton(app.SpacePanel, 'push');
            app.SpaceTest.FontName = 'SimHei';
            app.SpaceTest.FontSize = 15;
            app.SpaceTest.Position = [48 63 100 26];
            app.SpaceTest.Text = '正式测试';

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