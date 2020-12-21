function [recordings, status, exception] = start_two_back(args)
% START_TWO_BACK Displays stimuli and records responses for 2-back tests

% use name-value pairs as input parameters
arguments
    % three types of tasks are included
    args.TaskType {mustBeMember(args.TaskType, ["digit", "word", "space"])} = "digit"
    % set experiment part, i.e., practice or testing
    args.ExperimentPart {mustBeMember(args.ExperimentPart, ["prac", "test"])} = "prac"
end

% ---- set default error related outputs ----
status = 0;
exception = [];

% ---- set experiment timing parameters (predefined here, all in secs) ----
% fixation duration
time_fixation_secs = 0.5;
% stimuli duration
time_stimuli_secs = 2;
% a blank screen still wait for user's response
time_blank_secs = 1;
% used in "prac" part, feedback duration
time_feedback_secs = 0.5;
% used in "test" part, interval for user's preparation for test
time_wait_start_secs = 4;
time_wait_end_secs = 4;
% set common relative trial boundaries, three events occured here
%  the first: fixation offset and stimuli onset
%  the second: stimulus offset and blank screen displayed
%  the third: trial end
trial_bound_rel = cumsum([time_fixation_secs, time_stimuli_secs, time_blank_secs]);

% ---- prepare sequences ----
args_cell = namedargs2cell(args);
config = init_config(args_cell{:});
num_trials_total = sum(cellfun(@length, {config.blocks.trials}));

% ----prepare data recording table ----
vars_trial_configs = {'trial_id', 'block', 'trial', 'type', 'stim_id'};
dflt_trial_configs = {nan, nan, nan, strings, nan};
vars_trial_resp = {'cresp', 'resp', 'resp_raw', 'acc', 'rt'};
dflt_trial_resp = {strings, strings, strings, nan, nan};
vars_trial_timing = {'trial_start_time_expt', 'trial_start_time', 'stim_onset_time', 'stim_offset_time'};
dflt_trial_timing = {nan, nan, nan, nan};
recordings = cell2table( ...
    repmat([dflt_trial_configs, dflt_trial_resp, dflt_trial_timing], num_trials_total, 1), ...
    'VariableNames', [vars_trial_configs, vars_trial_resp, vars_trial_timing]);

% ---- configure screen and window ----
% setup default level of 2
PsychDefaultSetup(2);
% screen selection
screen_to_display = max(Screen('Screens'));
% set the start up screen to black
old_visdb = Screen('Preference', 'VisualDebugLevel', 1);
% do not skip synchronization test to make sure timing is accurate
old_sync = Screen('Preference', 'SkipSyncTests', 0);
% set priority to the top
old_pri = Priority(MaxPriority(screen_to_display));

try % error proof programming
    % ---- open window ----
    % open a window and set its background color as gray
    gray = WhiteIndex(screen_to_display) / 2;
    [window_ptr, window_rect] = PsychImaging('OpenWindow', screen_to_display, gray);
    % disable character input and hide mouse cursor
    ListenChar(2);
    HideCursor;
    % set blending function
    Screen('BlendFunction', window_ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    % set default font name and size
    Screen('TextFont', window_ptr, 'SimHei');
    Screen('TextSize', window_ptr, 128);
    
    % ---- timing information ----
    % get inter flip interval
    ifi = Screen('GetFlipInterval', window_ptr);
    
    % ---- keyboard settings ----
    keys.start = KbName('s');
    keys.exit = KbName('Escape');
    keys.left = KbName('LeftArrow');
    keys.right = KbName('RightArrow');
    
    % ---- present stimuli ----
    % display welcome screen and wait for a press of 's' to start
    [welcome_img, ~, welcome_alpha] = ...
        imread(fullfile('image', 'welcome.png'));
    welcome_img(:, :, 4) = welcome_alpha;
    welcome_tex = Screen('MakeTexture', window_ptr, welcome_img);
    Screen('DrawTexture', window_ptr, welcome_tex);
    Screen('Flip', window_ptr);
    % the flag to determine if the experiment should exit early
    early_exit = false;
    % here we should detect for a key press and release
    while true
        [resp_time, resp_code] = KbStrokeWait(-1);
        if resp_code(keys.start)
            start_time = resp_time;
            break
        elseif resp_code(keys.exit)
            early_exit = true;
            break
        end
    end
    % present a fixation cross to wait user perpared in test part
    if ~early_exit
        if args.ExperimentPart == "test"
            % test cannot be stopped here
            DrawFormattedText(window_ptr, '+', 'center', 'center', [0, 0, 0]);
            Screen('Flip', window_ptr);
            time_expect_next = time_wait_start_secs;
        else
            time_expect_next = 0;
        end
    end
    trial_order = 0;
    % a block contains several trials
    for block = config.blocks
        if early_exit
            break
        end
        % display instruction when separately practicing
        if args.ExperimentPart == "prac"
            switch args.TaskType
                case "digit"
                    image_file = fullfile('image', 'two-back-number.PNG');
                case "word"
                    image_file = fullfile('image', 'two-back-verbal.PNG');
                case "space"
                    image_file = fullfile('image', 'two-back-space.PNG');
            end
            [instruction_img, ~, instruction_alpha] = imread(image_file);
            instruction_img(:, :, 4) = instruction_alpha;
            instruction_tex = Screen('MakeTexture', window_ptr, instruction_img);
            Screen('DrawTexture', window_ptr, instruction_tex);
            Screen('Flip', window_ptr);
            while true
                [resp_time, resp_code] = KbPressWait(-1);
                if resp_code(keys.exit)
                    early_exit = true;
                    break
                elseif resp_code(keys.start)
                    start_time = resp_time;
                    time_expect_next = 0;
                    break
                end
            end
        end
        % each trial contains fixation, stimuli and response
        for trial = block.trials
            if early_exit
                break
            end
            % a flag variable indicating if user has pressed a key
            resp_made = false;
            time_expect_current = time_expect_next;
            % stimulus trial contains a fixation cross, a stimulus and a blank screen
            time_expect_next = time_expect_next + trial_bound_rel(3);
            % set the absolute timing boundray of three phases of a trial
            trial_bound_abs = time_expect_current + trial_bound_rel;
            % draw fixation and wait for press of `Esc` to exit
            DrawFormattedText(window_ptr, '+', 'center', 'center', [0, 0, 0]);
            trial_start_timestamp = ...
                Screen('Flip', window_ptr, ...
                start_time + time_expect_current - 0.5 * ifi);
            [~, resp_code] = ...
                KbPressWait(-1, start_time + trial_bound_abs(1) - 0.5 * ifi);
            if resp_code(keys.exit)
                early_exit = true;
                break
            end
            % present stimuli now
            switch args.TaskType
                case "digit"
                    if trial.type == "filler"
                        DrawFormattedText(window_ptr, num2str(trial.stim), ...
                            'center', 'center', [1, 0, 0]);
                    else
                        DrawFormattedText(window_ptr, num2str(trial.stim), ...
                            'center', 'center', [0, 0, 0]);
                    end
                case "word"
                    if trial.type == "filler"
                        DrawFormattedText(window_ptr, trial.stim, ...
                            'center', 'center', [1, 0, 0]);
                    else
                        DrawFormattedText(window_ptr, trial.stim, ...
                            'center', 'center', [0, 0, 0]);
                    end
                case "space"
                    [center_x, center_y] = RectCenter(window_rect);
                    % display an X-shaped cross
                    line_width = floor(RectHeight(window_rect) * 0.01);
                    cross_area_size = floor(RectHeight(window_rect) * 0.1);
                    cross_x_coords = [-cross_area_size, cross_area_size, -cross_area_size, cross_area_size];
                    cross_y_coords = [-cross_area_size, cross_area_size, cross_area_size, -cross_area_size];
                    Screen('DrawLines', window_ptr, [cross_x_coords; cross_y_coords], ...
                        line_width, [0, 0, 0], [center_x, center_y], 2)
                    % draw dots
                    display_area_size = floor(RectHeight(window_rect) * 0.75);
                    dot_size = 20;
                    dot_pos = round((str2double(strsplit(trial.stim, '-')) - 0.5) * display_area_size);
                    if trial.type == "filler"
                        dot_color = [1, 0, 0];
                    else
                        dot_color = [0, 0, 0];
                    end
                    Screen('DrawDots', window_ptr, dot_pos, dot_size, dot_color, [center_x, center_y], 1);
            end
            stim_onset_timestamp = Screen('Flip', window_ptr, ...
                start_time + trial_bound_abs(1) - 0.5 * ifi);
            [resp_timestamp, resp_code] = ...
                KbPressWait(-1, start_time + trial_bound_abs(2) - 0.5 * ifi);
            if resp_code(keys.exit)
                early_exit = true;
                break
            end
            if any(resp_code)
                resp_made = true;
            end
            % blank screen to wait for user's reponse
            Screen('FillRect', window_ptr, gray);
            stim_offset_timestamp = Screen('Flip', window_ptr, ...
                start_time + trial_bound_abs(2) - 0.5 * ifi);
            if ~resp_made
                [resp_timestamp, resp_code] = ...
                    KbPressWait(-1, start_time + trial_bound_abs(3) - 0.5 * ifi);
                if resp_code(keys.exit)
                    early_exit = true;
                    break
                end
                if any(resp_code)
                    resp_made = true;
                end
            end
            % analyze user's response
            if ~resp_made
                resp = "";
                resp_raw = "";
                resp_time = 0;
            else
                resp_time = resp_timestamp - stim_onset_timestamp;
                % use "|" as delimiter for the KeyName of "|" is "\\"
                resp_raw = string(strjoin(cellstr(KbName(resp_code)), '|'));
                if ~resp_code(keys.left) && ~resp_code(keys.right)
                    resp = "Neither";
                elseif resp_code(keys.left) && resp_code(keys.right)
                    resp = "Both";
                elseif resp_code(keys.left)
                    resp = "Left";
                else
                    resp = "Right";
                end
            end
            if trial.type ~= "filler"
                if resp ~= ""
                    resp_acc = double(resp == trial.cresp);
                else
                    resp_acc = -1;
                end
            else
                resp_acc = nan;
            end
            % if practice, give feedback
            if args.ExperimentPart == "prac"
                % set a smaller text size to display text feedback
                old_text_size = Screen('TextSize', window_ptr, 64);
                if trial.type == "filler" && resp_made
                    feedback_msg = '还不是按键的时候';
                    feedback_color = [1, 1, 1];
                else
                    switch resp_acc
                        case -1
                            feedback_msg = '超时了\n\n请及时作答';
                            feedback_color = [1, 1, 1];
                        case 0
                            switch resp
                                case "Neither"
                                    feedback_msg = '按错键了';
                                case "Both"
                                    feedback_msg = '请不要同时按左右键';
                                otherwise
                                    feedback_msg = '错了（×）\n\n不要灰心';
                            end
                            feedback_color = [1, 0, 0];
                        case 1
                            feedback_msg = '对了（√）\n\n真棒';
                            feedback_color = [0, 1, 0];
                    end
                end
                % no feedback if no response to "filler" stimuli
                if ~(trial.type == "filler" && ~resp_made)
                    DrawFormattedText(window_ptr, double(feedback_msg), 'center', 'center', feedback_color);
                    Screen('Flip', window_ptr, start_time + trial_bound_abs(3) - 0.5 * ifi);
                    WaitSecs(time_feedback_secs);
                    time_expect_next = time_expect_next + time_feedback_secs;
                end
                % restore default larger text size
                Screen('TextSize', window_ptr, old_text_size);
            end
            % store trial data
            % store trial information
            trial_order = trial_order + 1;
            recordings.trial_id(trial_order) = trial_order;
            recordings.block(trial_order) = block.id;
            recordings.trial(trial_order) = trial.id;
            recordings.stim_id(trial_order) = trial.stim_id;
            recordings.type(trial_order) = trial.type;
            recordings.cresp(trial_order) = trial.cresp;
            % store stimulus trial special data
            recordings.stim_onset_time(trial_order) = stim_onset_timestamp - start_time;
            recordings.stim_offset_time(trial_order) = stim_offset_timestamp - start_time;
            recordings.resp(trial_order) = resp;
            recordings.resp_raw(trial_order) = resp_raw;
            recordings.acc(trial_order) = resp_acc;
            recordings.rt(trial_order) = resp_time;
            % store common trial data
            recordings.trial_start_time_expt(trial_order) = time_expect_current;
            recordings.trial_start_time(trial_order) = trial_start_timestamp - start_time;
        end
    end
    % present a fixation cross before ending in test part
    if ~early_exit && args.ExperimentPart == "test"
        % test cannot be stopped here
        DrawFormattedText(window_ptr, '+', 'center', 'center', [0, 0, 0]);
        Screen('Flip', window_ptr);
        WaitSecs(time_wait_end_secs);
    end
    % goodbye
    [ending_img, ~, ending_alpha] = ...
        imread(fullfile('image', 'ending.png'));
    ending_img(:, :, 4) = ending_alpha;
    ending_tex = Screen('MakeTexture', window_ptr, ending_img);
    Screen('DrawTexture', window_ptr, ending_tex);
    Screen('Flip', window_ptr);
    KbStrokeWait;
catch exception
    status = 1;
end
% clear jobs
Screen('Close');
sca;
% enable character input and show mouse cursor
ListenChar;
ShowCursor;

% restore preferences
Screen('Preference', 'VisualDebugLevel', old_visdb);
Screen('Preference', 'SkipSyncTests', old_sync);
Priority(old_pri);
end
