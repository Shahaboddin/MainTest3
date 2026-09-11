showcursor('off');
hotkey('x', 'escape_screen(); assignin(''caller'',''continue_'',false);');

% Trackers
touch_tracker = touch_;   % for touches (choices)
eye_tracker   = eye_;     % iRecHS2, Eye Cal #2 (used only for logging)

% Sounds
snd_cor = AudioSound(null_);
snd_err = AudioSound(null_);
snd_cor.List = 'load_waveform({''sin'', .1, 800})';
snd_err.List = 'load_waveform({''sin'', .2, 200})';
sndscene_cor = create_scene(snd_cor);
sndscene_err = create_scene(snd_err);

% Editable parameters
editable('fix_window','fix_wait','fix_hold','cue_period', ...
    'choice_wait','choice_hold','iti','reward');
fix_window     = 3;
fix_window_pic = [8 6];
fix_wait       = 5000;
fix_hold       = 200;
cue_period     = 300;
choice_wait    = 5000;
choice_hold    = 150;
iti            = 1000;
reward         = 40;

% Event codes
FIX_POINT = 10;
CUE_ON    = 20;
CHOICE_ON = 30;
REWARD    = 90;
PUFF      = 91;
bhv_code(FIX_POINT,'Fix',CUE_ON,'Cue',CHOICE_ON,'Choice',REWARD,'Reward',PUFF,'Puff');

% Reward/puff mapping
reward_ms = zeros(1,9);
puff_ms   = zeros(1,9);

reward_ms(1) = 50;  puff_ms(1) =   0;
reward_ms(2) = 50;  puff_ms(2) = 150;
reward_ms(3) = 50;  puff_ms(3) = 300;

reward_ms(4) = 80;  puff_ms(4) =   0;
reward_ms(5) = 80;  puff_ms(5) = 150;
reward_ms(6) = 80;  puff_ms(6) = 300;

reward_ms(7) = 120;  puff_ms(7) =   0;
reward_ms(8) = 120;  puff_ms(8) = 150;
reward_ms(9) = 120;  puff_ms(9) = 300;

% Trial-specific info from userloop
left_id    = TrialRecord.User.left_id;
right_id   = TrialRecord.User.right_id;
left_name  = TrialRecord.User.left_name;
right_name = TrialRecord.User.right_name;
fix_loc    = TrialRecord.User.fix_loc;
loc1       = TrialRecord.User.loc1;
loc2       = TrialRecord.User.loc2;

% -----------------------
% Scene 1: fixation (touch)
% -----------------------
fix1 = SingleTarget(touch_tracker);
fix1.Target    = 1;
fix1.Threshold = fix_window;

fst1 = FreeThenHold(fix1);
fst1.WaitTime = fix_wait;
fst1.HoldTime = fix_hold;

scene1 = create_scene(fst1, 1);

% -----------------------
% Scene 2: cue (touch)
% -----------------------
fix2 = SingleTarget(touch_tracker);
fix2.Target    = 2;
fix2.Threshold = fix_window;

fst2 = FreeThenHold(fix2);
fst2.WaitTime = fix_wait;
fst2.HoldTime = fix_hold;

scene2 = create_scene(fst2, 2);

% -----------------------
% Scene 3: choice (touch ONLY)
% -----------------------
mt = MultiTarget(touch_tracker);
mt.Target      = [3 4];
mt.Threshold   = fix_window_pic;
mt.WaitTime    = choice_wait;
mt.HoldTime    = 0;
mt.TurnOffUnchosen = true;

fth_choice = FreeThenHold(mt);
fth_choice.WaitTime = choice_wait;
fth_choice.HoldTime = choice_hold;

scene3 = create_scene(fth_choice, [3 4]);

% -----------------------
% TTL for puffs
% -----------------------
ttl1 = TTLOutput(null_);
ttl1.Trigger  = true;
ttl1.Port     = 1;
ttl1.Duration = 150;

ttl2 = TTLOutput(null_);
ttl2.Trigger  = true;
ttl2.Port     = 2;
ttl2.Duration = 150;

scene_ttl1 = create_scene(ttl1);
scene_ttl2 = create_scene(ttl2);

% -----------------------
% Run trial
% -----------------------
error_type = 0;
rt_fix     = NaN;
rt_choice  = NaN;
chosen_to  = NaN;
chosen_id  = NaN;

idle(500);

% Scene 1
run_scene(scene1, FIX_POINT);
rt_fix = fst1.AcquiredTime;

if ~fst1.Success
    error_type = 3;
end

% Scene 2
if error_type == 0
    run_scene(scene2, CUE_ON);
    if ~fst2.Success
        error_type = 3;
    end
end

% Scene 3
if error_type == 0
    run_scene(scene3, CHOICE_ON);
    
    % Robust RT (mt.RT -> fth_choice.RT -> AcquiredTime)
    rt_choice = mt.RT;
    if isempty(rt_choice) || isnan(rt_choice)
        rt_choice = fth_choice.RT;
    end
    if isempty(rt_choice) || isnan(rt_choice)
        rt_choice = fth_choice.AcquiredTime;
    end
    if isempty(rt_choice)
        rt_choice = NaN;
    end
    rt = rt_choice;
    
    if ~fth_choice.Success
        error_type = 1;
    else
        chosen_to = mt.ChosenTarget;    % 3 = left, 4 = right
        if chosen_to == 3
            chosen_id = left_id;
        elseif chosen_to == 4
            chosen_id = right_id;
        else
            error_type = 1;
        end
    end
end

% Reward / puff
if error_type ~= 0 || isnan(chosen_id)
    run_scene(sndscene_err);
else
    rwd = reward_ms(chosen_id);
    puf = puff_ms(chosen_id);
    
    run_scene(sndscene_cor);
    
    if chosen_id >= 1 && chosen_id <= 3
        num_pulses = 1;
    elseif chosen_id >= 4 && chosen_id <= 6
        num_pulses = 2;
    else
        num_pulses = 3;
    end
    
    % Puff first
    if puf > 0
        if puf <= 150
            ttl1.Duration = puf;
            eventmarker(PUFF);
            run_scene(scene_ttl1);
        else
            ttl1.Duration = 150;
            eventmarker(PUFF);
            run_scene(scene_ttl1);
            
            idle(100);
            
            ttl2.Duration = min(150, puf - 150);
            eventmarker(PUFF);
            run_scene(scene_ttl2);
        end
    end
    
    % Reward after puff
    for k = 1:num_pulses
        idle(150);
        goodmonkey(reward, 'numreward', 1, 'eventmarker', REWARD);
        
        if k < num_pulses
            idle(200);
        end
    end
end

idle(iti);

% Log
trialerror(error_type);

bhv_variable('left_id',    left_id);
bhv_variable('right_id',   right_id);
bhv_variable('left_name',  left_name);
bhv_variable('right_name', right_name);
bhv_variable('rt_fix',     rt_fix);
bhv_variable('rt_choice',  rt_choice);
bhv_variable('chosen_to',  chosen_to);
bhv_variable('chosen_id',  chosen_id);

if ~isnan(chosen_id)
    bhv_variable('chosen_reward_ms', reward_ms(chosen_id));
    bhv_variable('chosen_puff_ms',   puff_ms(chosen_id));
else
    bhv_variable('chosen_reward_ms', 0);
    bhv_variable('chosen_puff_ms',   0);
end
