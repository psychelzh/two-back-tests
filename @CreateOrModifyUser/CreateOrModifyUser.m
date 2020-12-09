classdef CreateOrModifyUser < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure   matlab.ui.Figure
        MainTitle  matlab.ui.control.Label
        Label      matlab.ui.control.Label
        UserId     matlab.ui.control.NumericEditField
        Label_2    matlab.ui.control.Label
        UserName   matlab.ui.control.EditField
        Label_3    matlab.ui.control.Label
        UserSex    matlab.ui.control.DropDown
        Label_4    matlab.ui.control.Label
        UserDob    matlab.ui.control.DatePicker
        Confirm    matlab.ui.control.Button
    end

    
    properties (Access = private)
        CallingApp % Store the calling app
        CallingMethod % Modify or create
        CallingUserId % User id in calling app
        IsChanged = false % If value has been changed
    end
    
    methods (Access = private)
        
        function success = validateInfo(app)
            success = true;
            % input values validation
            if app.UserId.Value == 0
                selection = uiconfirm(app.UIFigure, ...
                    "编号0为测试，数据不会被记录，是否继续？", "确认测试", ...
                    "Options", ["确认", "取消"], ...
                    "DefaultOption", "取消", ...
                    "Icon", "warning");
                if selection == "取消"
                    success = false;
                    return
                end
            end
            if isempty(app.UserName.Value)
                selection = uiconfirm(app.UIFigure, ...
                    "用户姓名未填写，是否返回填写", "姓名缺失", ...
                    "Options", ["确认", "取消"], ...
                    "DefaultOption", "确认", ...
                    "Icon", "warning");
                if selection == "确认"
                    success = false;
                    return
                end
            end
            if isnat(app.UserDob.Value)
                uialert(app.UIFigure, "必须填入生日", "生日缺失")
                success = false;
                return
            end
        end
        
        function setupMainApp(app)
            % update user info in main app
            user.Id = app.UserId.Value;
            user.Name = app.UserName.Value;
            user.Sex = app.UserSex.Value;
            user.Dob = app.UserDob.Value;
            switch app.CallingMethod
                case "Creation"
                    app.CallingApp.createUser(user);
                    app.CallingApp.UserEvents = ...
                        horzcat(app.CallingApp.UserEvents, "Created");
                case "Modification"
                    app.CallingApp.updateUser(user);
                    app.CallingApp.UserEvents = ...
                        union(app.CallingApp.UserEvents, "Modified");
            end
            app.CallingApp.outputUsersHistory();
            % let main app be ready for work
            app.CallingApp.getReady();
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, mainApp, user)
            % Store main app object
            app.CallingApp = mainApp;
            if ~exist('user', 'var')
                app.CallingMethod = "Creation";
                app.MainTitle.Text = '新建被试';
            else
                app.CallingMethod = "Modification";
                app.MainTitle.Text = '修改信息';
                app.UserId.Value = user.Id;
                app.UserName.Value = user.Name;
                app.UserSex.Value = user.Sex;
                app.UserDob.Value = user.Dob;
                app.CallingUserId = user.Id;
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            if app.IsChanged
                switch app.CallingMethod
                    case "Creation"
                        msg = "是否录入当前用户信息？";
                    case "Modification"
                        msg = "是否修改当前用户信息？";
                end
                exit_confirm = uiconfirm(app.UIFigure, ...
                    msg, "退出确认",  ...
                    "Options", ["是", "否"], ...
                    "DefaultOption", "否");
                if exit_confirm == "是"
                    % update user info in main app
                    ok = app.validateInfo();
                    if ~ok, return; end
                    if app.CallingMethod == "Creation"
                        app.setupMainApp();
                    end
                end
            end
            delete(app)
        end

        % Button pushed function: Confirm
        function ConfirmButtonPushed(app, event)
            if app.IsChanged
                % ensure values are valid and set up main app before exiting
                ok = app.validateInfo();
                if ~ok, return; end
                app.setupMainApp();
            end
            delete(app)
        end

        % Value changed function: UserId
        function UserIdValueChanged(app, event)
            app.IsChanged = true;
            if ~isempty(app.CallingApp.UsersHistory)
                is_used = ismember(event.Value, app.CallingApp.UsersHistory.Id);
            else
                is_used = false;
            end
            if is_used
                switch app.CallingMethod
                    case "Creation"
                        selection = uiconfirm(app.UIFigure, ...
                            "当前编号已经使用过，请选择操作：", "编号重复", ...
                            "Options", ["删除旧被试并继续", "返回重新输入"], ...
                            "DefaultOption", "返回重新输入");
                        switch selection
                            case "删除旧被试并继续"
                                app.CallingApp.UsersHistory(is_used, :) = [];
                            case "返回重新输入"
                                app.UserId.Value = 0;
                        end
                    case "Modification"
                        uialert(app.UIFigure, ...
                            "不允许修改为已有用户的编号", "编号重复", ...
                            "Icon", "error")
                        app.UserId.Value = app.CallingUserId;
                end
            end
        end

        % Value changed function: UserName
        function UserNameValueChanged(app, event)
            app.IsChanged = true;
        end

        % Value changed function: UserSex
        function UserSexValueChanged(app, event)
            app.IsChanged = true;
        end

        % Value changed function: UserDob
        function UserDobValueChanged(app, event)
            app.IsChanged = true;
            if app.UserDob.Value > datetime("now")
                uialert(app.UIFigure, "出生日期不能大于当前日期，请重新输入", "生日无效")
                app.UserDob.Value = NaT;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [300 200 300 300];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create MainTitle
            app.MainTitle = uilabel(app.UIFigure);
            app.MainTitle.HorizontalAlignment = 'center';
            app.MainTitle.FontName = 'SimHei';
            app.MainTitle.FontSize = 20;
            app.MainTitle.Position = [104 250 94 26];
            app.MainTitle.Text = '主要标题';

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.HorizontalAlignment = 'center';
            app.Label.FontName = 'SimHei';
            app.Label.FontSize = 15;
            app.Label.Position = [68 200 35 22];
            app.Label.Text = '编号';

            % Create UserId
            app.UserId = uieditfield(app.UIFigure, 'numeric');
            app.UserId.Limits = [0 Inf];
            app.UserId.RoundFractionalValues = 'on';
            app.UserId.ValueDisplayFormat = '%.0f';
            app.UserId.ValueChangedFcn = createCallbackFcn(app, @UserIdValueChanged, true);
            app.UserId.HorizontalAlignment = 'center';
            app.UserId.FontName = 'SimHei';
            app.UserId.FontSize = 15;
            app.UserId.Tooltip = {'请输入非负整数。小数会四舍五入为整数。正式测试请不要用0作为编号。'};
            app.UserId.Position = [118 200 116 22];

            % Create Label_2
            app.Label_2 = uilabel(app.UIFigure);
            app.Label_2.HorizontalAlignment = 'center';
            app.Label_2.FontName = 'SimHei';
            app.Label_2.FontSize = 15;
            app.Label_2.Position = [68 161 35 22];
            app.Label_2.Text = '姓名';

            % Create UserName
            app.UserName = uieditfield(app.UIFigure, 'text');
            app.UserName.ValueChangedFcn = createCallbackFcn(app, @UserNameValueChanged, true);
            app.UserName.HorizontalAlignment = 'center';
            app.UserName.FontName = 'SimHei';
            app.UserName.FontSize = 15;
            app.UserName.Position = [118 160 115 23];

            % Create Label_3
            app.Label_3 = uilabel(app.UIFigure);
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.FontName = 'SimHei';
            app.Label_3.FontSize = 15;
            app.Label_3.Position = [66 121 35 22];
            app.Label_3.Text = '性别';

            % Create UserSex
            app.UserSex = uidropdown(app.UIFigure);
            app.UserSex.Items = {'男', '女'};
            app.UserSex.ValueChangedFcn = createCallbackFcn(app, @UserSexValueChanged, true);
            app.UserSex.FontName = 'SimHei';
            app.UserSex.FontSize = 15;
            app.UserSex.Position = [116 121 113 22];
            app.UserSex.Value = '男';

            % Create Label_4
            app.Label_4 = uilabel(app.UIFigure);
            app.Label_4.HorizontalAlignment = 'right';
            app.Label_4.FontName = 'SimHei';
            app.Label_4.FontSize = 15;
            app.Label_4.Position = [68 82 35 22];
            app.Label_4.Text = '生日';

            % Create UserDob
            app.UserDob = uidatepicker(app.UIFigure);
            app.UserDob.ValueChangedFcn = createCallbackFcn(app, @UserDobValueChanged, true);
            app.UserDob.FontName = 'SimHei';
            app.UserDob.FontSize = 15;
            app.UserDob.Position = [118 82 117 22];

            % Create Confirm
            app.Confirm = uibutton(app.UIFigure, 'push');
            app.Confirm.ButtonPushedFcn = createCallbackFcn(app, @ConfirmButtonPushed, true);
            app.Confirm.FontName = 'SimHei';
            app.Confirm.FontSize = 15;
            app.Confirm.Position = [102 26 100 26];
            app.Confirm.Text = '确定';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CreateOrModifyUser(varargin)

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