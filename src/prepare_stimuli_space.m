% temporary script to prepare space stimuli
% Generate the relative postion of each stimuli
% Define:
% Group 1: y < x & y > 1 - x
% Group 2: y > x & y > 1 - x
% Group 3: y > x & y < 1 - x
% Group 4: y < x & y < 1 - x
rng(20201220)
num_stim_each_group = 21;
num_blocks = 7;
num_group = 4;
stimuli = table;
for group = 1:num_group
    stimuli_cur_group = table;
    for i_stimuli = 1:num_stim_each_group
        while true
            coord_pos = rand(1, 2);
            % ensure they are not near the rims
            if any(coord_pos < 0.15 | coord_pos > 0.85)
                continue
            end
            % ensure they are not near the arms of the cross
            check_diags = [coord_pos(2) - coord_pos(1), coord_pos(2) - (1 - coord_pos(1))];
            if any(abs(check_diags) < 0.15)
                continue
            end
            switch group
                case 1
                    group_note = "第一象限";
                    if check_diags(1) < 0 && check_diags(2) > 0
                        break
                    end
                case 2
                    group_note = "第二象限";
                    if check_diags(1) > 0 && check_diags(2) > 0
                        break
                    end
                case 3
                    group_note = "第三象限";
                    if check_diags(1) > 0 && check_diags(2) < 0
                        break
                    end
                case 4
                    group_note = "第四象限";
                    if check_diags(1) < 0 && check_diags(2) < 0
                        break
                    end
            end
        end
        stim = join(compose("%.2f", coord_pos), '-');
        cur_stimuli = table(stim, group, group_note);
        stimuli_cur_group = vertcat(stimuli_cur_group, cur_stimuli); %#ok<AGROW>
    end
    stimuli_cur_group = addvars(stimuli_cur_group, ...
        repelem((0:(num_blocks - 1))', num_stim_each_group / num_blocks), ...
        'Before', 1, 'NewVariableNames', 'block');
    stimuli = vertcat(stimuli, stimuli_cur_group); %#ok<AGROW>
end
stimuli = addvars(stimuli, (1:height(stimuli))', 'Before', 1, 'NewVariableNames', 'stim_id');
writetable(stimuli, fullfile('config', 'space.csv'))
