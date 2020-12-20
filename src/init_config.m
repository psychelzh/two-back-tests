function config = init_config(args)
%GENSEQ generates sequence for current study
%
%   The basic thing to do here is to generate sequence for our experiment
%   test, which contains two parts: practice (part: 'prac') and testing
%   (part: 'test'). Generally, a **fixed** pseudorandom sequence is
%   required for testing part but not for practice part. Thus, the random
%   number generation of testing part seed is set as 0 for each user,
%   whereas that of practice part is set as 'Shuffle'.
%
%   See also start_two_back

arguments
    % see the description of these in "start_two_back()"
    args.TaskType {mustBeMember(args.TaskType, ["digit", "word", "space"])} = "digit"
    args.ExperimentPart {mustBeMember(args.ExperimentPart, ["prac", "test"])} = "prac"
end
% configure stimuli set
stim_config = readtable(fullfile('config', 'stimuli.xlsx'), "Sheet", args.TaskType, "TextType", "string");
% configure random seed and number of blocks
switch args.ExperimentPart
    case "prac"
        % set different random seed for each user
        rng('Shuffle')
        num_blocks = 1;
    case "test"
        % fix random seed for each type of task
        rng(sum(char(args.TaskType)))
        num_blocks = 6;
end
% generate sequence for each block
config.blocks = repelem(struct, num_blocks);
for i_block = 1:num_blocks
    config.blocks(i_block).id = i_block;
    switch args.ExperimentPart
        case "prc"
            stim_set = stim_config(stim_config.block == 0, :);
        case "test"
            stim_set = stim_config(stim_config.block == i_block, :);
    end
    config.blocks(i_block).trials = ...
        gen_block_seq(stim_set);
end
rng('default')
end

function seq = gen_block_seq(stim_set)
% GENBLOCKSEQ generates sequence for each block

num_trials = height(stim_set);
while true
    seq = datasample(stim_set, num_trials, 'Replace', false);
    seq.id = (1:num_trials)';
    seq.type = strings(num_trials, 1);
    for i_trial = 1:num_trials
        seq.id(i_trial) = i_trial;
        if i_trial <= 2
            seq.type(i_trial) = "Filler";
            seq.cresp(i_trial) = "None";
        else
            if seq.group(i_trial) == seq.group(i_trial - 2)
                seq.type(i_trial) = "target";
                seq.cresp(i_trial) = "Left";
            else
                seq.type(i_trial) = "distractor";
                seq.cresp(i_trial) = "Right";
            end
        end
    end
    if sum(seq.type == "target") == sum(seq.type == "distractor")
        break
    end
end
seq = table2struct(seq)';
end
