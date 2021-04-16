classdef LoadUser < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure     matlab.ui.Figure
        Confirm      matlab.ui.control.Button
        Title        matlab.ui.control.Label
        UserHistory  matlab.ui.control.Table
    end

    
    properties (Access = private)
        CallingApp % Store the calling app
        UsersData % store the data of all users
        UserIdSelected % store the selected user id
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp, users_history, events_history)
            app.CallingApp = mainApp;
            users_completion = groupsummary(events_history, 'UserId', @check_completion);
            users_data = join(users_history, users_completion, "LeftKeys", "Id", "RightKeys", "UserId");
            users_data = removevars(users_data, "GroupCount");
            users_data = renamevars(users_data, "fun1_Event", "IsCompleted");
            app.UsersData = users_data;
            app.UserHistory.Data = users_data;
            function is_completed = check_completion(events)
                check_events = ["DigitTestSucceed", "WordTestSucceed", "SpaceTestSucceed"];
                if all(ismember(check_events, events))
                    is_completed = "是";
                else
                    is_completed = "否";
                end
            end
        end

        % Cell selection callback: UserHistory
        function UserHistoryCellSelection(app, event)
            app.UserIdSelected = app.UsersData.Id(event.Indices(1));
        end

        % Button pushed function: Confirm
        function ConfirmButtonPushed(app, event)
            % check if the user has completed all tests
            if app.UsersData.IsCompleted(app.UsersData.Id == app.UserIdSelected) == "是"
                selection = uiconfirm(app.UIFigure, ...
                    "当前选择的用户已经完成所有的测试，是否继续导入？", "导入确认", ...
                    "Options", ["是", "否"], ...
                    "DefaultOption", "否");
                if selection == "否"
                    return
                end
            end
            app.CallingApp.loadUser(app.UserIdSelected);
            app.CallingApp.appendEvent("Loaded");
            app.CallingApp.getReady();
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [200 200 600 400];
            app.UIFigure.Name = 'MATLAB App';

            % Create UserHistory
            app.UserHistory = uitable(app.UIFigure);
            app.UserHistory.ColumnName = {'编号'; '姓名'; '性别'; '生日'; '创建时间'; '全部完成'};
            app.UserHistory.RowName = {};
            app.UserHistory.CellSelectionCallback = createCallbackFcn(app, @UserHistoryCellSelection, true);
            app.UserHistory.Position = [43 109 516 185];

            % Create Title
            app.Title = uilabel(app.UIFigure);
            app.Title.HorizontalAlignment = 'center';
            app.Title.FontName = 'SimHei';
            app.Title.FontSize = 20;
            app.Title.Position = [258 326 85 26];
            app.Title.Text = '选择被试';

            % Create Confirm
            app.Confirm = uibutton(app.UIFigure, 'push');
            app.Confirm.ButtonPushedFcn = createCallbackFcn(app, @ConfirmButtonPushed, true);
            app.Confirm.IconAlignment = 'center';
            app.Confirm.FontName = 'SimHei';
            app.Confirm.FontSize = 15;
            app.Confirm.Position = [251 47 100 26];
            app.Confirm.Text = '确定';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = LoadUser(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

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