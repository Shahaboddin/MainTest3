% MainTestResult3_eye.m
% Combined analysis for MainTest3_userloop:
% - Subject performance
% - Monitor eye (Eye2): Up/Down windows, 150 ms dwell
% - Face eye (Eye1): face ROI, pre/post choice and total
% - Pupil: AI17 (Eye1), AI21 (Eye2)
% Outputs:
%   analysis_output/MainTest3_eye_summary.csv / .xlsx  (all sessions)
%   analysis_output/<base_name>.csv / .xlsx            (this session)

%% SETTINGS
bhvfile = '261016_sh_MainTest3_userloop.bhv2';   % <-- set your file name
% bhvfile is supplied by RunAll_MainTest3_eye.m

sample_interval_ms = 1;       % ML analog sampling ~1 kHz
min_dwell_ms       = 150;     % dwell threshold (ms)
min_dwell_samp     = round(min_dwell_ms / sample_interval_ms);

%% LOAD
data = mlread(bhvfile);
ntr  = numel(data);

% Preallocate pupil
pupil1_mean = nan(1,ntr);  % Eye1 (face) pupil, AI17
pupil2_mean = nan(1,ntr);  % Eye2 (monitor) pupil, AI21

% Preallocate behavioral
chosen_id = nan(1,ntr);
rt_choice = nan(1,ntr);
left_id   = nan(1,ntr);
right_id  = nan(1,ntr);

for i = 1:ntr
if isfield(data(i).UserVars,'chosen_id')
chosen_id(i) = data(i).UserVars.chosen_id;
end
if isfield(data(i).UserVars,'rt_choice')
rt_choice(i) = data(i).UserVars.rt_choice;
end
if isfield(data(i).UserVars,'left_id')
left_id(i) = data(i).UserVars.left_id;
end
if isfield(data(i).UserVars,'right_id')
right_id(i) = data(i).UserVars.right_id;
end
end

pair_ids = [left_id(:) right_id(:)];

%% Correct / incorrect classification (same reward, different puff)
% Within each pair, the option with SMALLER puff_rank is "correct".
% puff_rank: 1 = least puff (0 ms), 2 = medium (150 ms), 3 = most (300 ms)

puff_rank = nan(1,9);
puff_rank(1) = 1;  puff_rank(4) = 1;  puff_rank(7) = 1;
puff_rank(2) = 2;  puff_rank(5) = 2;  puff_rank(8) = 2;
puff_rank(3) = 3;  puff_rank(6) = 3;  puff_rank(9) = 3;

is_valid     = false(1,ntr);
is_correct   = false(1,ntr);
is_incorrect = false(1,ntr);

for i = 1:ntr
if any(isnan(pair_ids(i,:))) || isnan(chosen_id(i))
continue;
end

    this_pair = pair_ids(i,:);
if any(isnan(this_pair))
continue;
end

    is_valid(i) = true;

    rank_left  = puff_rank(this_pair(1));
rank_right = puff_rank(this_pair(2));

    if rank_left < rank_right
correct_id = this_pair(1);
elseif rank_right < rank_left
correct_id = this_pair(2);
else
% Equal puff rank; treat as invalid
is_valid(i) = false;
continue;
end

    if chosen_id(i) == correct_id
is_correct(i) = true;
else
is_incorrect(i) = true;
end
end

n_valid        = sum(is_valid);
n_correct      = sum(is_correct);
n_incorrect    = sum(is_incorrect);
total_trials   = ntr;

if n_valid > 0
percent_correct = 100 * n_correct / n_valid;
else
percent_correct = NaN;
end

rt_correct   = rt_choice(is_correct & is_valid & ~isnan(rt_choice));
rt_incorrect = rt_choice(is_incorrect & is_valid & ~isnan(rt_choice));

mean_rt_correct   = mean(rt_correct);
mean_rt_incorrect = mean(rt_incorrect);

%% Print behavioral summary
fprintf('File: %s\n', bhvfile);
if total_trials > 0
percent_valid = 100 * n_valid / total_trials;
else
percent_valid = NaN;
end

fprintf('Valid trials (use)/Total trials  : %d/%d  (%.1f %%)\n', ...
n_valid, total_trials, percent_valid);
fprintf('Highest chosen (n/N)             : %d/%d  (%.1f %%)\n', ...
n_correct, max(n_valid,1), percent_correct);
fprintf('Incorrect trials (non-highest)   : %d\n\n', n_incorrect);

if ~isempty(rt_correct)
fprintf('Mean RT correct   : %.1f ms (n = %d)\n', mean_rt_correct, numel(rt_correct));
else
fprintf('Mean RT correct   : NaN (no correct RTs)\n');
end
if ~isempty(rt_incorrect)
fprintf('Mean RT incorrect : %.1f ms (n = %d)\n', mean_rt_incorrect, numel(rt_incorrect));
else
fprintf('Mean RT incorrect : NaN (no incorrect RTs)\n');
end
fprintf('\n');

%% Up/Down eye ROI analysis with EXPANDED rectangles (fixed centers) -- Eye2

% Up-left  (orig: x[-12,-4], y[-13,-10])
UL_x_min = -13; UL_x_max = -3;
UL_y_min = -13; UL_y_max = -9;

% Up-right (orig: x[4,12], y[-13,-10])
UR_x_min =  3;  UR_x_max = 13;
UR_y_min = -13; UR_y_max = -9;

% Down-left (orig: x[-12,-4], y[-16,-13])
DL_x_min = -13; DL_x_max = -3;
DL_y_min = -17; DL_y_max = -13;

% Down-right (orig: x[4,12], y[-16,-13])
DR_x_min =  3;  DR_x_max = 13;
DR_y_min = -17; DR_y_max = -13;

first_look_roi  = nan(1,ntr);  % 1=Down first, 2=Up first, 0=none
time_in_down    = nan(1,ntr);  % ms
time_in_up      = nan(1,ntr);
n_entries_down  = nan(1,ntr);
n_entries_up    = nan(1,ntr);

for i = 1:ntr
if ~isfield(data(i),'AnalogData')
continue;
end

    eyeXY = [];
if isfield(data(i).AnalogData,'Eye2') && ~isempty(data(i).AnalogData.Eye2)
eyeXY = data(i).AnalogData.Eye2;
elseif isfield(data(i).AnalogData,'Eye') && ~isempty(data(i).AnalogData.Eye)
eyeXY = data(i).AnalogData.Eye;
end
if isempty(eyeXY) || size(eyeXY,2) < 2
continue;
end

    ex = eyeXY(:,1);
ey = eyeXY(:,2);

    in_UL = (ex >= UL_x_min & ex <= UL_x_max) & (ey >= UL_y_min & ey <= UL_y_max);
in_UR = (ex >= UR_x_min & ex <= UR_x_max) & (ey >= UR_y_min & ey <= UR_y_max);
in_DL = (ex >= DL_x_min & ex <= DL_x_max) & (ey >= DL_y_min & ey <= DL_y_max);
in_DR = (ex >= DR_x_min & ex <= DR_x_max) & (ey >= DR_y_min & ey <= DR_y_max);

    in_down = in_DL | in_DR;
in_up   = in_UL | in_UR;

    if ~any(in_down | in_up)
first_look_roi(i) = 0;
time_in_down(i)   = NaN;
time_in_up(i)     = NaN;
n_entries_down(i) = NaN;
n_entries_up(i)   = NaN;
continue;
end

    first_look_roi(i) = 0;

    down_starts = find(~[false; in_down(1:end-1)] & in_down);
down_ends   = find(in_down & ~[in_down(2:end); false]);
down_durs   = down_ends - down_starts + 1;

    up_starts = find(~[false; in_up(1:end-1)] & in_up);
up_ends   = find(in_up & ~[in_up(2:end); false]);
up_durs   = up_ends - up_starts + 1;

    down_idx = find(down_durs >= min_dwell_samp, 1, 'first');
up_idx   = find(up_durs   >= min_dwell_samp, 1, 'first');

    first_down_time = inf;
first_up_time   = inf;

    if ~isempty(down_idx), first_down_time = down_starts(down_idx); end
if ~isempty(up_idx),   first_up_time   = up_starts(up_idx);   end

    if isfinite(first_down_time) || isfinite(first_up_time)
if first_up_time < first_down_time
first_look_roi(i) = 2;
elseif first_down_time < first_up_time
first_look_roi(i) = 1;
else
first_look_roi(i) = 0;
end
else
first_look_roi(i) = 0;
end

    time_in_down(i) = sum(in_down);
time_in_up(i)   = sum(in_up);

    in_down_pad = [false; in_down(:)];
in_up_pad   = [false; in_up(:)];
n_entries_down(i) = sum(~in_down_pad(1:end-1) & in_down_pad(2:end));
n_entries_up(i)   = sum(~in_up_pad(1:end-1)   & in_up_pad(2:end));
end

n_any_roi    = sum(first_look_roi~=0);
n_first_down = sum(first_look_roi==1);
n_first_up   = sum(first_look_roi==2);

fprintf('Eye ROI summary (150 ms dwell, expanded windows):\n');
fprintf('Trials with any ROI look       : %d/%d\n', n_any_roi, ntr);
fprintf('First saccade to UPPER half    : %d\n', n_first_up);
fprintf('First saccade to LOWER half    : %d\n\n', n_first_down);

if any(~isnan(time_in_up))
mean_up_ms = mean(time_in_up(~isnan(time_in_up)));
total_up_ms= nansum(time_in_up);
else
mean_up_ms = NaN; total_up_ms = NaN;
end
if any(~isnan(time_in_down))
mean_down_ms = mean(time_in_down(~isnan(time_in_down)));
total_down_ms= nansum(time_in_down);
else
mean_down_ms = NaN; total_down_ms = NaN;
end

fprintf('Mean dwell time in UP   (ms)   : %.1f\n', mean_up_ms);
fprintf('Total dwell time in UP   (ms)  : %.1f\n', total_up_ms);
fprintf('Mean dwell time in DOWN (ms)   : %.1f\n', mean_down_ms);
fprintf('Total dwell time in DOWN (ms)  : %.1f\n\n', total_down_ms);

%% Saccade (dwell-based) summary for Eye2

max_saccades_to_count = 3;
sacc_seq = nan(ntr, max_saccades_to_count);  % 1=DOWN, 2=UP

for i = 1:ntr
if ~isfield(data(i),'AnalogData')
continue;
end

    eyeXY = [];
if isfield(data(i).AnalogData,'Eye2') && ~isempty(data(i).AnalogData.Eye2)
eyeXY = data(i).AnalogData.Eye2;
elseif isfield(data(i).AnalogData,'Eye') && ~isempty(data(i).AnalogData.Eye)
eyeXY = data(i).AnalogData.Eye;
end
if isempty(eyeXY) || size(eyeXY,2) < 2
continue;
end

    ex = eyeXY(:,1);
ey = eyeXY(:,2);

    in_UL = (ex >= UL_x_min & ex <= UL_x_max) & (ey >= UL_y_min & ey <= UL_y_max);
in_UR = (ex >= UR_x_min & ex <= UR_x_max) & (ey >= UR_y_min & ey <= UR_y_max);
in_DL = (ex >= DL_x_min & ex <= DL_x_max) & (ey >= DL_y_min & ey <= DL_y_max);
in_DR = (ex >= DR_x_min & ex <= DR_x_max) & (ey >= DR_y_min & ey <= DR_y_max);

    in_down = in_DL | in_DR;
in_up   = in_UL | in_UR;

    if ~any(in_down | in_up)
continue;
end

    down_starts = find(~[false; in_down(1:end-1)] & in_down);
down_ends   = find(in_down & ~[in_down(2:end); false]);
down_durs   = down_ends - down_starts + 1;
valid_down  = find(down_durs >= min_dwell_samp);

    up_starts = find(~[false; in_up(1:end-1)] & in_up);
up_ends   = find(in_up & ~[in_up(2:end); false]);
up_durs   = up_ends - up_starts + 1;
valid_up   = find(up_durs >= min_dwell_samp);

    all_times  = [];
all_labels = [];

    for idx = valid_down(:)'
all_times(end+1,1)  = down_starts(idx);
all_labels(end+1,1) = 1;
end
for idx = valid_up(:)'
all_times(end+1,1)  = up_starts(idx);
all_labels(end+1,1) = 2;
end

    if isempty(all_times)
continue;
end

    [~, ord]      = sort(all_times);
sorted_labels = all_labels(ord);
n_to_take = min(max_saccades_to_count, numel(sorted_labels));
sacc_seq(i,1:n_to_take) = sorted_labels(1:n_to_take);
end

first_sacc_down  = sum(sacc_seq(:,1) == 1);
first_sacc_up    = sum(sacc_seq(:,1) == 2);
second_sacc_down = sum(sacc_seq(:,2) == 1);
second_sacc_up   = sum(sacc_seq(:,2) == 2);
third_sacc_down  = sum(sacc_seq(:,3) == 1);
third_sacc_up    = sum(sacc_seq(:,3) == 2);

n_trials_first  = sum(~isnan(sacc_seq(:,1)));
n_trials_second = sum(~isnan(sacc_seq(:,2)));
n_trials_third  = sum(~isnan(sacc_seq(:,3)));

p_first_down  = 100 * first_sacc_down  / max(1, n_trials_first);
p_first_up    = 100 * first_sacc_up    / max(1, n_trials_first);
p_second_down = 100 * second_sacc_down / max(1, n_trials_second);
p_second_up   = 100 * second_sacc_up   / max(1, n_trials_second);
p_third_down  = 100 * third_sacc_down  / max(1, n_trials_third);
p_third_up    = 100 * third_sacc_up    / max(1, n_trials_third);

total_sacc_to_down = nansum(n_entries_down);
total_sacc_to_up   = nansum(n_entries_up);
total_sacc_all     = total_sacc_to_down + total_sacc_to_up;

p_sacc_down_all = 100 * total_sacc_to_down / max(1, total_sacc_all);
p_sacc_up_all   = 100 * total_sacc_to_up   / max(1, total_sacc_all);

mean_sacc_up   = total_sacc_to_up   / max(1,total_trials);
mean_sacc_down = total_sacc_to_down / max(1,total_trials);

fprintf('Saccade (150 ms dwell) summary within touch ROIs:\n');
fprintf('First saccade to UP   : %d trials (%.1f %%)\n', first_sacc_up,    p_first_up);
fprintf('First saccade to DOWN : %d trials (%.1f %%)\n', first_sacc_down,  p_first_down);
fprintf('Second saccade to UP  : %d trials (%.1f %%)\n', second_sacc_up,   p_second_up);
fprintf('Second saccade to DOWN: %d trials (%.1f %%)\n', second_sacc_down, p_second_down);
fprintf('Third saccade to UP   : %d trials (%.1f %%)\n', third_sacc_up,    p_third_up);
fprintf('Third saccade to DOWN : %d trials (%.1f %%)\n\n', third_sacc_down, p_third_down);

fprintf('Total saccades to UP   (entries) : %.0f (%.1f %%)\n', total_sacc_to_up, p_sacc_up_all);
fprintf('Total saccades to DOWN (entries) : %.0f (%.1f %%)\n', total_sacc_to_down, p_sacc_down_all);
fprintf('Mean saccades to UP    : %.2f per trial\n', mean_sacc_up);
fprintf('Mean saccades to DOWN  : %.2f per trial\n\n', mean_sacc_down);

%% Face eye (Eye1) analysis: pre, post, and total

FIX_POINT = 10;
CUE_ON    = 20;
CHOICE_ON = 30;
REWARD    = 90;
PUFF      = 91;

face_x_min = -10;
face_x_max =  10;
face_y_min =   0;
face_y_max =  15;

time_face_pre   = nan(1,ntr);
time_face_post  = nan(1,ntr);
n_face_sacc_pre = nan(1,ntr);
n_face_sacc_post= nan(1,ntr);
mean_dur_pre    = nan(1,ntr);
mean_dur_post   = nan(1,ntr);

any_face_pre    = false(1,ntr);
any_face_post   = false(1,ntr);

time_face_all   = nan(1,ntr);
n_face_sacc_all = nan(1,ntr);
mean_dur_all    = nan(1,ntr);

for i = 1:ntr
if ~isfield(data(i),'AnalogData') || ~isfield(data(i).AnalogData,'Eye')
continue;
end
eyeXY = data(i).AnalogData.Eye;   % Eye1 (face)
if isempty(eyeXY) || size(eyeXY,2) < 2
continue;
end

    ex = eyeXY(:,1);
ey = eyeXY(:,2);
nsamp = size(eyeXY,1);

    in_face = (ex >= face_x_min & ex <= face_x_max) & ...
(ey >= face_y_min & ey <= face_y_max);

    codes = data(i).BehavioralCodes.CodeNumbers;
times = data(i).BehavioralCodes.CodeTimes;

    t_choice = NaN;
t_end    = nsamp - 1;

    idx_choice = find(codes == CHOICE_ON, 1, 'first');
if ~isempty(idx_choice), t_choice = times(idx_choice); end

    idx_rew_puff = find(codes == REWARD | codes == PUFF, 1, 'first');
if ~isempty(idx_rew_puff)
t_end = times(idx_rew_puff);
end

    if isnan(t_choice)
t_choice = 0;
end

    t_idx = (0:nsamp-1)';

    pre_mask  = (t_idx >= 0        & t_idx <  t_choice);
post_mask = (t_idx >= t_choice & t_idx <= t_end);

    in_face_pre  = in_face & pre_mask;
in_face_post = in_face & post_mask;

    time_face_pre(i)  = sum(in_face_pre);
time_face_post(i) = sum(in_face_post);
time_face_all(i)  = sum(in_face);

    if any(in_face_pre),  any_face_pre(i)  = true; end
if any(in_face_post), any_face_post(i) = true; end

    [n_pre,  mean_pre] = dwell_stats(in_face_pre,  min_dwell_samp);
[n_post, mean_post] = dwell_stats(in_face_post, min_dwell_samp);
[n_all,  mean_all] = dwell_stats(in_face,      min_dwell_samp);

    n_face_sacc_pre(i)  = n_pre;
n_face_sacc_post(i) = n_post;
n_face_sacc_all(i)  = n_all;

    mean_dur_pre(i)   = mean_pre  * sample_interval_ms;
mean_dur_post(i)  = mean_post * sample_interval_ms;
mean_dur_all(i)   = mean_all  * sample_interval_ms;
end

n_trials_any_pre  = sum(any_face_pre);
n_trials_any_post = sum(any_face_post);
n_trials_any_all  = sum(time_face_all > 0);

fprintf('Face eye (Eye1) ROI summary:\n');
fprintf('Trials with face-look BEFORE choice : %d/%d\n', n_trials_any_pre,  ntr);
fprintf('Trials with face-look AFTER  choice : %d/%d\n', n_trials_any_post, ntr);
fprintf('Trials with face-look (any time)    : %d/%d\n\n', n_trials_any_all, ntr);

if any(any_face_pre)
fprintf('Mean time in FACE ROI pre-choice  (ms): %.1f\n', ...
mean(time_face_pre(any_face_pre)));
fprintf('Total time in FACE ROI pre-choice (ms): %.1f\n', ...
nansum(time_face_pre));
fprintf('Mean # face saccades pre-choice        : %.2f\n', ...
mean(n_face_sacc_pre(any_face_pre)));
fprintf('Mean dwell per face saccade pre (ms)   : %.1f\n\n', ...
mean(mean_dur_pre(any_face_pre  & ~isnan(mean_dur_pre))));
else
fprintf('No valid face looks BEFORE choice.\n\n');
end

if any(any_face_post)
fprintf('Mean time in FACE ROI post-choice (ms): %.1f\n', ...
mean(time_face_post(any_face_post)));
fprintf('Total time in FACE ROI post-choice(ms): %.1f\n', ...
nansum(time_face_post));
fprintf('Mean # face saccades post-choice       : %.2f\n', ...
mean(n_face_sacc_post(any_face_post)));
fprintf('Mean dwell per face saccade post (ms)  : %.1f\n\n', ...
mean(mean_dur_post(any_face_post & ~isnan(mean_dur_post))));
else
fprintf('No valid face looks AFTER choice.\n\n');
end

if any(time_face_all > 0)
fprintf('Mean time in FACE ROI (all trial) (ms): %.1f\n', ...
mean(time_face_all(time_face_all>0)));
fprintf('Total time in FACE ROI (all trials)(ms): %.1f\n', ...
nansum(time_face_all));
fprintf('Mean # face saccades per trial (all)   : %.2f\n', ...
mean(n_face_sacc_all(time_face_all>0)));
fprintf('Mean dwell per face saccade (all ms)   : %.1f\n\n', ...
mean(mean_dur_all(n_face_sacc_all>0 & ~isnan(mean_dur_all))));
else
fprintf('No face looks in any trial.\n\n');
end

%% Build one-row combined summary table (performance + Eye2 + Eye1 + pupil)

[~, fname_noext, ~] = fileparts(bhvfile);
uscores = strfind(fname_noext, '_');
if numel(uscores) >= 2
base_name = fname_noext(1:uscores(2)-1);   % e.g. '260716_Sky1'
else
base_name = fname_noext;
end
session_name = base_name;

if total_trials > 0
percent_valid = 100 * n_valid / total_trials;
else
percent_valid = NaN;
end

behav_tbl = table;
behav_tbl.Session       = {session_name};
behav_tbl.N_Trials      = total_trials;
behav_tbl.N_Valid       = n_valid;
behav_tbl.Valid_pc      = percent_valid;
behav_tbl.N_Correct     = n_correct;
behav_tbl.Correct_pc    = percent_correct;
behav_tbl.RT_Cor_ms     = mean_rt_correct;
behav_tbl.RT_Incor_ms   = mean_rt_incorrect;

behav_tbl.FirstUp_N     = n_first_up;
behav_tbl.FirstUp_pc    = p_first_up;
behav_tbl.FirstDown_N   = n_first_down;
behav_tbl.FirstDown_pc  = p_first_down;

behav_tbl.DwellUpMean_ms    = mean_up_ms;
behav_tbl.DwellUpTotal_ms   = total_up_ms;
behav_tbl.DwellDownMean_ms  = mean_down_ms;
behav_tbl.DwellDownTotal_ms = total_down_ms;

behav_tbl.Sac2ndUp_N    = second_sacc_up;
behav_tbl.Sac2ndUp_pc   = p_second_up;
behav_tbl.Sac2ndDown_N  = second_sacc_down;
behav_tbl.Sac2ndDown_pc = p_second_down;

behav_tbl.Sac3rdUp_N    = third_sacc_up;
behav_tbl.Sac3rdUp_pc   = p_third_up;
behav_tbl.Sac3rdDown_N  = third_sacc_down;
behav_tbl.Sac3rdDown_pc = p_third_down;

behav_tbl.SacUpTotal_N     = total_sacc_to_up;
behav_tbl.SacUpTotal_pc    = p_sacc_up_all;
behav_tbl.SacUpMeanPerTr   = mean_sacc_up;

behav_tbl.SacDownTotal_N   = total_sacc_to_down;
behav_tbl.SacDownTotal_pc  = p_sacc_down_all;
behav_tbl.SacDownMeanPerTr = mean_sacc_down;

behav_tbl.FacePre_NTrials       = n_trials_any_pre;
behav_tbl.FacePost_NTrials      = n_trials_any_post;
behav_tbl.FaceAll_NTrials       = n_trials_any_all;

behav_tbl.FacePreTimeMean_ms    = mean(time_face_pre(any_face_pre));
behav_tbl.FacePreTimeTotal_ms   = nansum(time_face_pre);
behav_tbl.FacePostTimeMean_ms   = mean(time_face_post(any_face_post));
behav_tbl.FacePostTimeTotal_ms  = nansum(time_face_post);
behav_tbl.FaceAllTimeMean_ms    = mean(time_face_all(time_face_all>0));
behav_tbl.FaceAllTimeTotal_ms   = nansum(time_face_all);

behav_tbl.FacePreSacMean_N      = mean(n_face_sacc_pre(any_face_pre));
behav_tbl.FacePostSacMean_N     = mean(n_face_sacc_post(any_face_post));
behav_tbl.FaceAllSacMean_N      = mean(n_face_sacc_all(time_face_all>0));

behav_tbl.FacePreSacDurMean_ms  = mean(mean_dur_pre(any_face_pre  & ~isnan(mean_dur_pre)));
behav_tbl.FacePostSacDurMean_ms = mean(mean_dur_post(any_face_post & ~isnan(mean_dur_post)));
behav_tbl.FaceAllSacDurMean_ms  = mean(mean_dur_all(n_face_sacc_all>0 & ~isnan(mean_dur_all)));

% ---- Pupil extraction (per trial i) ----
pupil1_trial = nan(ntr,1);  % mean diameter in pixels
pupil2_trial = nan(ntr,1);

for i = 1:ntr
if isfield(data(i).AnalogData,'General')
G = data(i).AnalogData.General;

        % Pupil 1 (Gen1)
if isfield(G,'Gen1') && ~isempty(G.Gen1)
p1 = G.Gen1(:);
valid1 = p1 > 0.1;  % exclude invalid/near-zero
if any(valid1)
p1_valid = p1(valid1);
p1_px = p1_valid * 40 * 2;  % radius->px, then diameter
pupil1_trial(i) = mean(p1_px);
else
pupil1_trial(i) = NaN;
end
end

        % Pupil 2 (Gen2)
if isfield(G,'Gen2') && ~isempty(G.Gen2)
p2 = G.Gen2(:);
valid2 = p2 > 0.1;
if any(valid2)
p2_valid = p2(valid2);
p2_px = p2_valid * 40 * 2;
pupil2_trial(i) = mean(p2_px);
else
pupil2_trial(i) = NaN;
end
end
end
end

% Make is_valid a column vector to match pupil*_trial
is_valid_col = is_valid(:);

% Session-level summaries (one number per session)
pupil1_mean_session = mean(pupil1_trial(is_valid_col & ~isnan(pupil1_trial)));
pupil2_mean_session = mean(pupil2_trial(is_valid_col & ~isnan(pupil2_trial)));

% ---- Blinking (per trial) ----
% Fixed thresholds based on your observation:
% Gen1: blink when < 0.5
% Gen2: blink when < 1.0
blink_thresh1 = 0.5;
blink_thresh2 = 1.0;
min_blink_samp = 80;  % ~80 ms minimum blink duration at 1 kHz

n_blinks1_trial = nan(ntr,1);
n_blinks2_trial = nan(ntr,1);

for i = 1:ntr
if isfield(data(i).AnalogData,'General')
G = data(i).AnalogData.General;

        if isfield(G,'Gen1') && ~isempty(G.Gen1)
p1 = G.Gen1(:);
blink_mask1 = p1 < blink_thresh1;
[n_blinks1_trial(i), ~] = dwell_stats(blink_mask1, min_blink_samp);
end

        if isfield(G,'Gen2') && ~isempty(G.Gen2)
p2 = G.Gen2(:);
blink_mask2 = p2 < blink_thresh2;
[n_blinks2_trial(i), ~] = dwell_stats(blink_mask2, min_blink_samp);
end
end
end

n_blinks1_session = mean(n_blinks1_trial(is_valid_col & ~isnan(n_blinks1_trial)));
n_blinks2_session = mean(n_blinks2_trial(is_valid_col & ~isnan(n_blinks2_trial)));

% ---- Licking (AI 16 = General Input 3) ----
lick_thresh = 1;        % adjust after inspecting Gen3 trace
min_lick_samp = 15;       % ~20 ms minimum lick event

licks_per_trial = nan(ntr,1);

for i = 1:ntr
if isfield(data(i).AnalogData,'General')
G = data(i).AnalogData.General;

        if isfield(G,'Gen3') && ~isempty(G.Gen3)
lick_signal = G.Gen3(:);
lick_mask = lick_signal > lick_thresh;
[n_licks, ~] = dwell_stats(lick_mask, min_lick_samp);
licks_per_trial(i) = n_licks;
end
end
end

licks_mean_session = mean(licks_per_trial(is_valid_col & ~isnan(licks_per_trial)));
behav_tbl.Licks_Mean = licks_mean_session;

% ---- Build one-row combined summary table ----

[~, fname_noext, ~] = fileparts(bhvfile);
uscores = strfind(fname_noext, '_');
if numel(uscores) >= 2
base_name = fname_noext(1:uscores(2)-1);   % e.g. '260716_Sky1'
else
base_name = fname_noext;
end
session_name = base_name;

if total_trials > 0
percent_valid = 100 * n_valid / total_trials;
else
percent_valid = NaN;
end

behav_tbl = table;
behav_tbl.Session       = {session_name};
behav_tbl.N_Trials      = total_trials;
behav_tbl.N_Valid       = n_valid;
behav_tbl.Valid_pc      = percent_valid;
behav_tbl.N_Correct     = n_correct;
behav_tbl.Correct_pc    = percent_correct;
behav_tbl.RT_Cor_ms     = mean_rt_correct;
behav_tbl.RT_Incor_ms   = mean_rt_incorrect;

behav_tbl.FirstUp_N     = n_first_up;
behav_tbl.FirstUp_pc    = p_first_up;
behav_tbl.FirstDown_N   = n_first_down;
behav_tbl.FirstDown_pc  = p_first_down;

behav_tbl.DwellUpMean_ms    = mean_up_ms;
behav_tbl.DwellUpTotal_ms   = total_up_ms;
behav_tbl.DwellDownMean_ms  = mean_down_ms;
behav_tbl.DwellDownTotal_ms = total_down_ms;

behav_tbl.Sac2ndUp_N    = second_sacc_up;
behav_tbl.Sac2ndUp_pc   = p_second_up;
behav_tbl.Sac2ndDown_N  = second_sacc_down;
behav_tbl.Sac2ndDown_pc = p_second_down;

behav_tbl.Sac3rdUp_N    = third_sacc_up;
behav_tbl.Sac3rdUp_pc   = p_third_up;
behav_tbl.Sac3rdDown_N  = third_sacc_down;
behav_tbl.Sac3rdDown_pc = p_third_down;

behav_tbl.SacUpTotal_N     = total_sacc_to_up;
behav_tbl.SacUpTotal_pc    = p_sacc_up_all;
behav_tbl.SacUpMeanPerTr   = mean_sacc_up;

behav_tbl.SacDownTotal_N   = total_sacc_to_down;
behav_tbl.SacDownTotal_pc  = p_sacc_down_all;
behav_tbl.SacDownMeanPerTr = mean_sacc_down;

behav_tbl.FacePre_NTrials       = n_trials_any_pre;
behav_tbl.FacePost_NTrials      = n_trials_any_post;
behav_tbl.FaceAll_NTrials       = n_trials_any_all;

behav_tbl.FacePreTimeMean_ms    = mean(time_face_pre(any_face_pre));
behav_tbl.FacePreTimeTotal_ms   = nansum(time_face_pre);
behav_tbl.FacePostTimeMean_ms   = mean(time_face_post(any_face_post));
behav_tbl.FacePostTimeTotal_ms  = nansum(time_face_post);
behav_tbl.FaceAllTimeMean_ms    = mean(time_face_all(time_face_all>0));
behav_tbl.FaceAllTimeTotal_ms   = nansum(time_face_all);

behav_tbl.FacePreSacMean_N      = mean(n_face_sacc_pre(any_face_pre));
behav_tbl.FacePostSacMean_N     = mean(n_face_sacc_post(any_face_post));
behav_tbl.FaceAllSacMean_N      = mean(n_face_sacc_all(time_face_all>0));

behav_tbl.FacePreSacDurMean_ms  = mean(mean_dur_pre(any_face_pre  & ~isnan(mean_dur_pre)));
behav_tbl.FacePostSacDurMean_ms = mean(mean_dur_post(any_face_post & ~isnan(mean_dur_post)));
behav_tbl.FaceAllSacDurMean_ms  = mean(mean_dur_all(n_face_sacc_all>0 & ~isnan(mean_dur_all)));

% Pupil
behav_tbl.Pupil1_Mean = pupil1_mean_session;
behav_tbl.Pupil2_Mean = pupil2_mean_session;

% Blinking
behav_tbl.Blinks1_Mean = n_blinks1_session;
behav_tbl.Blinks2_Mean = n_blinks2_session;

% Licking
behav_tbl.Licks_Mean = licks_mean_session;

%% Save combined summary: global CSV/XLSX + per-session CSV/XLSX

out_folder = 'analysis_output';
if ~exist(out_folder, 'dir')
mkdir(out_folder);
end

global_csv  = fullfile(out_folder, 'MainTest3_eye_summary.csv');
global_xlsx = fullfile(out_folder, 'MainTest3_eye_summary.xlsx');

if exist(global_csv, 'file')
old_tbl = readtable(global_csv);
new_vars = behav_tbl.Properties.VariableNames;
old_vars = old_tbl.Properties.VariableNames;

    % Add new columns to old rows (e.g. Blinks1_Mean, Blinks2_Mean, Licks_Mean)
for v = 1:numel(new_vars)
vn = new_vars{v};
if ~ismember(vn, old_vars)
example_val = behav_tbl{1,v};
if iscell(example_val)
old_tbl.(vn) = repmat({''}, height(old_tbl), 1);
else
old_tbl.(vn) = nan(height(old_tbl), 1);
end
end
end

    % Add any old columns missing in new row (safety)
old_vars = old_tbl.Properties.VariableNames;
for v = 1:numel(old_vars)
vn = old_vars{v};
if ~ismember(vn, new_vars)
example_val = old_tbl{1,v};
if iscell(example_val)
behav_tbl.(vn) = {''};
else
behav_tbl.(vn) = nan(height(behav_tbl), 1);
end
end
end

    % Reorder columns to match
behav_tbl = behav_tbl(:, old_tbl.Properties.VariableNames);

    new_tbl = [old_tbl; behav_tbl];
writetable(new_tbl, global_csv);
writetable(new_tbl, global_xlsx);
else
writetable(behav_tbl, global_csv);
writetable(behav_tbl, global_xlsx);
end

session_csv  = fullfile(out_folder, [base_name '.csv']);
session_xlsx = fullfile(out_folder, [base_name '.xlsx']);

writetable(behav_tbl, session_csv);
writetable(behav_tbl, session_xlsx);

%% Helper: dwell-based stats for a boolean mask
function [n_dwell, mean_len] = dwell_stats(mask, min_len)
n_dwell  = 0;
mean_len = NaN;

    mask = mask(:);  % ensure column vector

    if ~any(mask), return; end

    starts = find(~[false; mask(1:end-1)] & mask);
ends   = find(mask & ~[mask(2:end); false]);
durs   = ends - starts + 1;

    good   = durs >= min_len;
if ~any(good), return; end

    durs_good = durs(good);
n_dwell   = numel(durs_good);
mean_len  = mean(durs_good);
end
