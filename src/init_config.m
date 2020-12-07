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
    args.StimuliId (1,:) {mustBeInteger} = 1:10
    args.TrialsPerBlock (1,1) {mustBeInteger} = 10
end
% configure random seed and number of blocks
switch args.ExperimentPart
    case "prac"
        % set different random seed for each user
        rng('Shuffle')
        num_blocks = 2;
    case "test"
        % fix random seed for each type of task
        rng(sum(char(args.TaskType)))
        num_blocks = 8;
end
% generate sequence for each block
config.blocks = repelem(struct, num_blocks);
for i_block = 1:num_blocks
    config.blocks(i_block).id = i_block;
    config.blocks(i_block).trials = ...
        gen_block_seq(args.StimuliId, args.TrialsPerBlock);
end
rng('default')
end

function seq = gen_block_seq(stim_set, num_trials)
% GENBLOCKSEQ generates sequence for each block

% generate trial type sequence
types_stem = repelem(["target", "distractor"], num_trials / 2);
% add two filler trials to the front
types = [repelem("filler", 2), randsample(types_stem, length(types_stem))];
% preallocate
stims_id = nan(1, length(types));
% generate sequence
for itrial = 1:length(types)
    if types(itrial) == "filler"
        if itrial == 1
            exclude = [];
        else
            exclude = stims_id(itrial - 1);
        end
        stims_id(itrial) = randsample(stim_set, 1, true, ~ismember(stim_set, exclude));
    end
    if types(itrial) == "target"
        stims_id(itrial) = stims_id(itrial - 2);
    end
    if types(itrial) == "distractor"
        stims_id(itrial) = randsample(stim_set, 1, true, ~ismember(stim_set, stims_id(itrial - 2:itrial - 1)));
    end
end
% set the correct response sequence
cresp = strings(1, length(types));
cresp(types == "target") = "Left";
cresp(types == "distractor") = "Right";
seq = struct(...
    'id', num2cell(1:length(types)), ...
    'stim_id', num2cell(stims_id), ...
    'type', num2cell(types), ...
    'cresp', num2cell(cresp));
end
