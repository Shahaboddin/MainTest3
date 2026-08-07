function [C,timingfile,userdefined_trialholder] = MainTest3_userloop(~, TrialRecord)

% 1) Default outputs
C = [];
timingfile = 'MainTest3.m';
userdefined_trialholder = '';

% 2) Max trials
max_trials = 900;
if TrialRecord.CurrentTrialNumber >= max_trials
    TrialRecord.NextBlock = -1;
    return;
end

% 3) Define the 9 images
img_names = { ...
    'Picture1.png','Picture2.png','Picture3.png', ...
    'Picture4.png','Picture5.png','Picture6.png', ...
    'Picture7.png','Picture8.png','Picture9.png' };

% 4) Build list of allowed unordered pairs
%    Only within {1,4,7} OR {2,5,8} OR {3,6,9}
allowed_pairs = [];

% ORIGINAL:
% sets = { [1 4 7], [2 5 8], [3 6 9] };

% MINIMAL CHANGE: only use 1,4,7
sets = { [1 4 7] };   % <--- comment out the others instead of deleting

for k = 1:numel(sets)
    s = sets{k};
    comb = nchoosek(s,2);          % all 2-combinations within this 3-set
    allowed_pairs = [allowed_pairs; comb]; %#ok<AGROW>
end

% Remove duplicates (not really needed here, but safe)
allowed_pairs = unique(allowed_pairs,'rows');

% 5) Pick one allowed pair at random
n_pairs = size(allowed_pairs,1);
idx_pair = randi(n_pairs);
pair_ids = allowed_pairs(idx_pair,:);   % [idA idB], e.g. [1 4]

pic_id1 = pair_ids(1);
pic_id2 = pair_ids(2);

% Get filenames
pic1name = img_names{pic_id1};
pic2name = img_names{pic_id2};

% 6) Randomly assign left/right
if rand < 0.5
    left_id   = pic_id1;
    right_id  = pic_id2;
    left_name = pic1name;
    right_name= pic2name;
else
    left_id   = pic_id2;
    right_id  = pic_id1;
    left_name = pic2name;
    right_name= pic1name;
end

% 7) Locations & sizes
fix_loc = [0 -18];        % small cue a bit lower
loc1    = [-8 -13];       % left
loc2    = [ 8 -13];       % right

cue_radius   = 2;         % cue size
pic_size     = 180;       % object size

% Save for timing file / analysis
TrialRecord.User.left_id    = left_id;
TrialRecord.User.right_id   = right_id;
TrialRecord.User.left_name  = left_name;
TrialRecord.User.right_name = right_name;
TrialRecord.User.loc1       = loc1;
TrialRecord.User.loc2       = loc2;
TrialRecord.User.fix_loc    = fix_loc;

TrialRecord.User.img_indices = [left_id right_id];
TrialRecord.User.img_names   = {left_name right_name};

% 8) Build TaskObjects
% #1: fixation (bottom center)
% #2: cue (bottom center, same loc, different color)
% #3: left picture
% #4: right picture
C = { ...
    sprintf('crc(%d,[.8 .8 .8],1,%.1f,%.1f)', cue_radius, fix_loc(1), fix_loc(2)), ...   % #1 fixation
    sprintf('crc(%d,[.6 .6 .6],1,%.1f,%.1f)', cue_radius, fix_loc(1), fix_loc(2)), ...   % #2 cue
    sprintf('pic(%s,%.1f,%.1f,%d,%d)', left_name,  loc1(1), loc1(2), pic_size, pic_size), ... % #3 left
    sprintf('pic(%s,%.1f,%.1f,%d,%d)', right_name, loc2(1), loc2(2), pic_size, pic_size) ...  % #4 right
    };

end