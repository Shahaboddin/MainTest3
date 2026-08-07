%% eye_position.m
% Part 1: Monitor eye (Eye2) in expanded 4 touch windows
% Part 2: Face eye (Eye1) in a face ROI

bhvfile = '260730_Sky_MainTest3_userloop.bhv2';  % <-- set your file
data    = mlread(bhvfile);

%% ---------- Part 1: Monitor eye (Eye2) ----------

trials_to_plot = [91 92 94 95 96];   % trials for monitor windows

% Expanded rectangle definitions in degrees (same as analysis)
UL_x_min = -13; UL_x_max = -3;
UL_y_min = -13; UL_y_max = -9;

UR_x_min =  3;  UR_x_max = 13;
UR_y_min = -13; UR_y_max = -9;

DL_x_min = -13; DL_x_max = -3;
DL_y_min = -17; DL_y_max = -13;

DR_x_min =  3;  DR_x_max = 13;
DR_y_min = -17; DR_y_max = -13;

for k = 1:numel(trials_to_plot)
    tr = trials_to_plot(k);

    if tr > numel(data)
        warning('Trial %d does not exist', tr);
        continue;
    end

    eyeXY = [];
    if isfield(data(tr).AnalogData,'Eye2') && ~isempty(data(tr).AnalogData.Eye2)
        eyeXY = data(tr).AnalogData.Eye2;
    elseif isfield(data(tr).AnalogData,'Eye') && ~isempty(data(tr).AnalogData.Eye)
        eyeXY = data(tr).AnalogData.Eye;
    end
    if isempty(eyeXY)
        warning('No monitor eye data in trial %d', tr);
        continue;
    end

    ex = eyeXY(:,1);
    ey = eyeXY(:,2);

    in_UL = (ex >= UL_x_min & ex <= UL_x_max) & (ey >= UL_y_min & ey <= UL_y_max);
    in_UR = (ex >= UR_x_min & ex <= UR_x_max) & (ey >= UR_y_min & ey <= UR_y_max);
    in_DL = (ex >= DL_x_min & ex <= DL_x_max) & (ey >= DL_y_min & ey <= DL_y_max);
    in_DR = (ex >= DR_x_min & ex <= DR_x_max) & (ey >= DR_y_min & ey <= DR_y_max);

    in_any = in_UL | in_UR | in_DL | in_DR;

    figure; clf; hold on;

    plot(ex(~in_any), ey(~in_any), '.', 'Color',[0.8 0.8 0.8], 'MarkerSize',3);
    plot(ex(in_UL), ey(in_UL), 'g.', 'MarkerSize',6); % up-left
    plot(ex(in_UR), ey(in_UR), 'c.', 'MarkerSize',6); % up-right
    plot(ex(in_DL), ey(in_DL), 'r.', 'MarkerSize',6); % down-left
    plot(ex(in_DR), ey(in_DR), 'm.', 'MarkerSize',6); % down-right

    axis equal;
    xlabel('X (deg)'); ylabel('Y (deg)');
    title(sprintf('Trial %d: Eye2 in expanded 4 sub-windows', tr));

    plot([UL_x_min UL_x_max UL_x_max UL_x_min UL_x_min], ...
         [UL_y_min UL_y_min UL_y_max UL_y_max UL_y_min], 'g-', 'LineWidth',1.5);
    plot([UR_x_min UR_x_max UR_x_max UR_x_min UR_x_min], ...
         [UR_y_min UR_y_min UR_y_max UR_y_max UR_y_min], 'c-', 'LineWidth',1.5);
    plot([DL_x_min DL_x_max DL_x_max DL_x_min DL_x_min], ...
         [DL_y_min DL_y_min DL_y_max DL_y_max DL_y_min], 'r-', 'LineWidth',1.5);
    plot([DR_x_min DR_x_max DR_x_max DR_x_min DR_x_min], ...
         [DR_y_min DR_y_min DR_y_max DR_y_max DR_y_min], 'm-', 'LineWidth',1.5);

    legend({'Outside 4 windows', ...
            'Up-left','Up-right','Down-left','Down-right'}, ...
           'Location','bestoutside');
end

%% ---------- Part 2: Face eye (Eye1) ----------

% Face ROI (must match MainTestResult3_eye.m face section)
face_x_min = -10;
face_x_max =  10;
face_y_min =   0;
face_y_max =  15;

trials_face_to_plot = [91 92 94 95 96];   % choose trials for face eye

for k = 1:numel(trials_face_to_plot)
    tr = trials_face_to_plot(k);

    if tr > numel(data)
        warning('Trial %d does not exist', tr);
        continue;
    end

    if ~isfield(data(tr).AnalogData,'Eye') || isempty(data(tr).AnalogData.Eye)
        warning('No Eye1 (face) data in trial %d', tr);
        continue;
    end

    eyeXY = data(tr).AnalogData.Eye;   % Eye1 = face
    if isempty(eyeXY) || size(eyeXY,2) < 2
        warning('Malformed Eye1 data in trial %d', tr);
        continue;
    end

    ex = eyeXY(:,1);
    ey = eyeXY(:,2);

    in_face = (ex >= face_x_min & ex <= face_x_max) & ...
              (ey >= face_y_min & ey <= face_y_max);

    figure; clf; hold on;

    plot(ex(~in_face), ey(~in_face), '.', 'Color',[0.8 0.8 0.8], 'MarkerSize',3);
    plot(ex(in_face),  ey(in_face),  'b.', 'MarkerSize',6);

    plot([face_x_min face_x_max face_x_max face_x_min face_x_min], ...
         [face_y_min face_y_min face_y_max face_y_max face_y_min], ...
         'b-', 'LineWidth',1.5);

    axis equal;
    xlabel('X (deg)'); ylabel('Y (deg)');
    title(sprintf('Trial %d: Eye1 (face) in face ROI', tr));
    legend({'Outside face ROI','Inside face ROI'}, 'Location','bestoutside');
end