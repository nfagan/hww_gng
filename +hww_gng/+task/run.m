function run(opts)

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

IO =        opts.IO;
INTERFACE = opts.INTERFACE;
TIMINGS =   opts.TIMINGS;
TIMER =     opts.TIMER;
TRACKER =   opts.TRACKER;
STRUCTURE = opts.STRUCTURE;
STIMULI =   opts.STIMULI;
REWARDS =   opts.REWARDS;
WINDOW =    opts.WINDOW;
comm =      opts.SERIAL.comm;
sync_comm =  opts.SERIAL.plex_comm;

cstate = 'new_trial';

first_entry = true;

is_social_targets = strcmp( STRUCTURE.target_types, 'social' );

DATA = struct();
PROGRESS = struct();
TRIAL_NUMBER = 0;

go_fs = { 'go', 'nogo' };
soc_fs = { 'social', 'nonsocial' };
n_correct = hww_gng.util.layeredstruct( {go_fs, soc_fs}, 0 );
n_incorrect = n_correct;

opts.PLEX_SYNC = struct();
opts.PLEX_SYNC.sync_frequency = 0.5;  % s
opts.PLEX_SYNC.sync_timer = NaN;
opts.PLEX_SYNC.sync_times = nan( 1e4, 1 );
opts.PLEX_SYNC.sync_iteration = 1;

reward_size_name = '';
reward_size_cue_filename = '';

while ( true )
  
  if ( isnan(opts.PLEX_SYNC.sync_timer) || ...
      toc(opts.PLEX_SYNC.sync_timer) >= opts.PLEX_SYNC.sync_frequency )
    sync_comm.sync_pulse( 0 );
    opts.PLEX_SYNC.sync_times( opts.PLEX_SYNC.sync_iteration ) = TIMER.get_time( 'task' );
    opts.PLEX_SYNC.sync_iteration = opts.PLEX_SYNC.sync_iteration + 1;
    opts.PLEX_SYNC.sync_timer = tic();
  end
  
  if ( isequal(cstate, 'new_trial') )
    if ( first_entry )
      %   RECORD DATA
      if ( TRIAL_NUMBER > 0 )
        tn = TRIAL_NUMBER;
        DATA(tn).trial_number =           tn;
        DATA(tn).trial_type =             trial_type;
        DATA(tn).trial_outcome =          trial_outcome;
        DATA(tn).cue_type =               cue_type;
        DATA(tn).image_file =             current_image_file;
        DATA(tn).target_placement =       target_placement;
        DATA(tn).target_displacement =    target_displacement;
        DATA(tn).target_image_category =  target_image_category;
        DATA(tn).target_type =            target_type;
        DATA(tn).cue_delay =              cue_delay;
        DATA(tn).reaction_time =          reaction_time;
        DATA(tn).error__no_fixation =     error__no_fixation;
        DATA(tn).error__broke_cue_fixation =   error__broke_cue_fixation;
        DATA(tn).error__wrong_go_nogo =   error__wrong_go_nogo;
        DATA(tn).events =                 PROGRESS;
        DATA(tn).reward =                 current_reward;
        DATA(tn).reward_size =            reward_size_name;
        DATA(tn).reward_size_cue_file =   reward_size_cue_filename;
        %   display progress
        for i = 1:numel(go_fs)
          for j = 1:numel(soc_fs)
            gof = go_fs{i};
            socf = soc_fs{j};
            corrv = n_correct.(gof).(socf);
            incorrv = n_incorrect.(gof).(socf);
            fprintf( '\n Correct   %s %s: %d', gof, socf, corrv );
            fprintf( '\n Incorrect %s %s: %d', gof, socf, incorrv );
            fprintf( '\n' );
          end
        end
        fprintf( '\n\n' );
        disp( DATA(tn) );
      end
      TRIAL_NUMBER = TRIAL_NUMBER + 1;
      TIMER.reset_timers( cstate );
      %   reset progress time
      PROGRESS = structfun( @(x) NaN, PROGRESS, 'un', false );
      PROGRESS.new_trial = TIMER.get_time( 'task' );
      %   send eyelink new trial message
      TRACKER.send( sprintf('TRIAL__%d', TRIAL_NUMBER) );
      %   establish go v no go, social v. nonsocial
      is_go = rand() < STRUCTURE.p_go;
      
      if ( is_social_targets )
        is_social = true;
      else
        is_social = rand() < STRUCTURE.p_social;
      end
      
      is_target_left = rand() < STRUCTURE.p_target_left;
      images = STIMULI.setup.images;
      go_cue = STIMULI.go_cue;
      nogo_cue = STIMULI.nogo_cue;
      %   establish variable cue display time
      delays = TIMINGS.delays.delay_post_cue_display;
      n_delays = numel( delays );
      delays = delays( randperm(n_delays) );
      cue_delay = delays(1);
      trial_outcome = '';
      %   establish cue placement
      if ( is_target_left )
        target_placement = 'center-left';
        target_displacement = -STIMULI.setup.go_target.displacement;
      else
        target_placement = 'center-right';
        target_displacement = STIMULI.setup.go_target.displacement;
      end
      %   reset reaction time
      reaction_time = 0;
      %   reset errors
      error__no_fixation = false;
      error__wrong_go_nogo = false;
      error__broke_cue_fixation = false;
      if ( is_go )
        cue = go_cue;
        trial_type = 'go';
      else
        cue = nogo_cue;
        trial_type = 'nogo';
      end
      if ( is_social )
        cue_type = 'social';
      else
        cue_type = 'nonsocial';
      end
      
      target_image_categories = STIMULI.setup.target_image_categories;
      
      if ( is_social_targets )
        target_image_category = get_target_image_category( target_image_categories );
        target_type = cue_type;
      else
        target_image_category = '';
        target_type = '';
      end
      
      %   get current image file
      if ( is_social_targets )
        select_images = images.targets.(target_type).(target_image_category).matrices;
        select_files = images.targets.(target_type).(target_image_category).filenames;
      else
        select_images = images.(trial_type).(cue_type).matrices;
        select_files = images.(trial_type).(cue_type).filenames;
      end
      
      n_images = numel( select_images );
      perm_index = randperm( n_images );
      select_images = select_images( perm_index );
      select_files = select_files( perm_index );
      current_image_file = select_files{1};
      
      if ( is_social_targets )
        go_target = STIMULI.go_target;
        
        if ( isa(go_target, 'Image') )
          go_target.image = select_images{1};
        else
          warning( 'Go target is not an image; not setting image file.' );
        end
      else
        cue.image = select_images{1};
      end
      
      if ( TRIAL_NUMBER == 1 || did_show_reward_info_cue )
        block_size = STRUCTURE.reward_block_size;
        n_conditions = 3;
        
        reward_size_index = get_next_reward_size_index( block_size, n_conditions );
        reward_size_name = get_reward_size_name( reward_size_index );
      end
      
      fprintf( 'REWARD SIZE INDEX: %d', reward_size_index );
      
      did_show_reward_info_cue = false;
      
      %   get current reward size
      if ( is_social_targets )
        current_reward = REWARDS.(reward_size_name);
      else
        all_rewards = REWARDS.main;
        reward_ind = randi( numel(all_rewards), 1 );
        current_reward = all_rewards(reward_ind);
      end
      
      if ( isKey(REWARDS.color_map, current_reward) )
        current_color = REWARDS.color_map(current_reward);
      else
        warning( 'No color associated with size "%s"!', num2str(current_reward) );
        current_color = zeros( 1, 3 );
      end
      
      first_entry = false;
    end
    if ( TIMER.duration_met('new_trial') )
      %   MARK: goto: new_trial
      cstate = 'fixation';
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'fixation') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      fix_square = STIMULI.fix_square;
      fix_square.reset_targets();
      log_progress = true;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    fix_square.update_targets();
    fix_square.draw();
    Screen( 'Flip', WINDOW.index );
    if ( log_progress )
      PROGRESS.fixation_on = TIMER.get_time( 'task' );
      log_progress = false;
    end
    if ( fix_square.duration_met() )
      %   MARK: goto: display_go_nogo_cue
      
      if ( STRUCTURE.use_reward_cue )
        cstate = 'display_reward_info_cue';
      else
        cstate = 'display_go_nogo_cue';
      end
      
      first_entry = true;
    end
    if ( TIMER.duration_met('fixation') )
      %   MARK: goto: fixation
      error__no_fixation = true;
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'display_reward_info_cue') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      
      reward_size_cue = STIMULI.reward_size_cue;
      
      log_progress = true;
      did_show_cue = false;
      first_entry = false;
      
      reward_size_cue_filename = configure_reward_size_cue( reward_size_cue, images.reward_size_cues, reward_size_name );
    end
    
    TRACKER.update_coordinates();
    
    if ( ~did_show_cue )
      reward_size_cue.draw();
      Screen( 'Flip', WINDOW.index );
      did_show_cue = true;
      did_show_reward_info_cue = true;
    end
    
    if ( log_progress )
      PROGRESS.reward_info_cue_onset = TIMER.get_time( 'task' );
      log_progress = false;
    end
    
    if ( TIMER.duration_met(cstate) )
      %   MARK: goto: display_go_nogo_cue
      cstate = 'display_go_nogo_cue';
      first_entry = true;
    end
  end
  
  
  if ( isequal(cstate, 'display_go_nogo_cue') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      rwd_border = STIMULI.reward_size_border;
      rwd_border.color = current_color;
      cue.put( 'center' );
      log_progress = true;
      did_show_cue = false;
      error__broke_cue_fixation = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    cue.update_targets();
    if ( ~did_show_cue )
      cue.draw();
      rwd_border.draw_frame();
      Screen( 'Flip', WINDOW.index );
      did_show_cue = true;
    end
    if ( ~cue.in_bounds() )
      %   MARK: goto: error_broke_cue_fixation
      error__broke_cue_fixation = true;
      cstate = 'error_broke_cue_fixation';
      first_entry = true;
    end
    if ( log_progress )
      PROGRESS.go_nogo_cue_onset = TIMER.get_time( 'task' );
      log_progress = false;
    end
    if ( TIMER.duration_met('display_go_nogo_cue') && ~error__broke_cue_fixation )
      %   MARK: goto: delay_post_cue_display
      cstate = 'delay_post_cue_display';
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'delay_post_cue_display') )
    if ( first_entry )
      TIMER.set_durations( cstate, cue_delay );
      TIMER.reset_timers( cstate );
      error__broke_cue_fixation = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    cue.update_targets();
    if ( ~cue.in_bounds() )
      %   MARK: goto: error_broke_cue_fixation
      error__broke_cue_fixation = true;
      cstate = 'error_broke_cue_fixation';
      first_entry = true;
    end
    if ( TIMER.duration_met('delay_post_cue_display') && ~error__broke_cue_fixation )
      %   MARK: goto: go_nogo
      cstate = 'go_nogo';
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'go_nogo') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      go_target = STIMULI.go_target;
      go_target.put( target_placement );
      go_target.shift( target_displacement(1), target_displacement(2) );
      %   added
      go_target.reset_targets();
      %  	end added
      cue.put( 'center' );
      targ_duration = go_target.targets{1}.duration;
      rect_cue_target = cue.targets{1};
%       w_rect = [ 0, 0, 1600, 900 ];
      w_rect = Screen( 'Rect', WINDOW.index );
      if ( is_target_left )
        trap_cue_placement = 'left';
      else
        trap_cue_placement = 'right';
      end
      trap_cue_target = TrapezoidTarget( rect_cue_target.tracker, w_rect ...
        , cue.vertices, rect_cue_target.duration, trap_cue_placement );
      next_state = [];
      state_entry_time = TIMER.get_time( cstate );
      log_progress = true;
      PROGRESS.go_target_acquired = NaN;
      targ_acquired = false;
      did_show_images = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    go_target.update_targets();
    cue.update_targets();
    trap_cue_target.update();
    if ( ~did_show_images )
      go_target.draw();
      cue.draw();
      rwd_border.draw_frame();
      Screen( 'Flip', WINDOW.index );
      did_show_images = true;
    end
    if ( log_progress )
      PROGRESS.go_target_onset = TIMER.get_time( 'task' );
      log_progress = false;
    end
%     if ( ~targ_acquired && trap_cue_target.in_bounds() )
    if ( ~targ_acquired && go_target.in_bounds() )
      PROGRESS.go_target_acquired = TIMER.get_time( 'task' );
      targ_acquired = true;
    end
    if ( ~is_go )
      %   if they look at the go target or look away from the cue ...
      if ( trap_cue_target.in_bounds )
        cstate = 'error_go_nogo';
        first_entry = true;
        trial_outcome = 'go';
        current_time = TIMER.get_time( 'go_nogo' );
        reaction_time = current_time - state_entry_time - targ_duration;
      else
        trial_outcome = 'nogo';
        next_state = 'reward';
      end
    else
      if ( go_target.duration_met() )
        current_time = TIMER.get_time( 'go_nogo' );
        reaction_time = current_time - state_entry_time - targ_duration;
        trial_outcome = 'go';
        cstate = 'reward';
%         cstate = 'delay_post_go';
        first_entry = true;
      end
    end
    if ( TIMER.duration_met('go_nogo') )
      %   MARK: goto: error_go_nogo OR reward
      if ( is_go && isequal(cstate, 'go_nogo') && isequal(next_state, []) )
        cstate = 'error_go_nogo';
        trial_outcome = 'nogo';
      else
        cstate = 'reward';
      end
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'delay_post_go') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      state_dur = TIMINGS.time_in.delay_post_go - reaction_time;
      
      if ( state_dur < 0 )
        state_dur = 0;
      end
      
      TIMER.set_durations( cstate, state_dur );
      log_progress = true;
      first_entry = false;
    end
    if ( TIMER.duration_met('delay_post_go') )
      %   MARK: goto: reward
      cstate = 'reward';
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'error_go_nogo') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      error_cue = STIMULI.error_cue;
      error__wrong_go_nogo = true;
      current_incorrect = n_incorrect.(trial_type).(cue_type);
      n_incorrect.(trial_type).(cue_type) = current_incorrect + 1;
      log_progress = true;
      first_entry = false;
    end
    error_cue.draw();
    Screen( 'Flip', WINDOW.index );
    if ( log_progress )
      PROGRESS.go_target_offset = TIMER.get_time( 'task' );
      log_progress = false;
    end
    if ( TIMER.duration_met('error_go_nogo') )
      %   MARK: goto: iti
      cstate = 'iti';
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'error_broke_cue_fixation') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      error_cue_broke = STIMULI.error_cue_broke_cue_fixation;
      first_entry = false;
      did_show = false;
    end
    if ( ~did_show )
      error_cue_broke.draw();
      Screen( 'Flip', WINDOW.index );
      did_show = true;
    end
    if ( TIMER.duration_met('error_broke_cue_fixation') )
      %   MARK: goto: iti
      cstate = 'iti';
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'reward') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      if ( INTERFACE.use_arduino )
        comm.reward( 'A', current_reward );
      end
      rwd_drop = STIMULI.rwd_drop;
      current_correct = n_correct.(trial_type).(cue_type);
      n_correct.(trial_type).(cue_type) = current_correct + 1;
      log_progress = true;
      first_entry = false;
    end
    rwd_drop.draw();
    rwd_border.draw_frame();
    Screen( 'Flip', WINDOW.index );
    if ( log_progress )
      PROGRESS.go_target_offset = TIMER.get_time( 'task' );
      PROGRESS.reward_onset = TIMER.get_time( 'task' );
      log_progress = false;
    end
    if ( TIMER.duration_met('reward') )
      %   MARK: goto: iti
      cstate = 'iti';
      first_entry = true;
    end
  end
  
  if ( isequal(cstate, 'iti') )
    if ( first_entry )
      TIMER.reset_timers( cstate );
      Screen( 'Flip', WINDOW.index );
      PROGRESS.iti = TIMER.get_time( 'task' );
      first_entry = false;
    end
    if ( TIMER.duration_met('iti') )
      %   MARK: goto: new_trial
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   Quit if error in EyeLink
  err = TRACKER.check_recording();
  if ( err ~= 0 ), break; end;
  
  % - Check if key is pressed
  [key_pressed, ~, key_code] = KbCheck();
  if ( key_pressed )
    % - Quit if stop_key is pressed
    if ( key_code(INTERFACE.stop_key) ), break; end;
    %   Deliver reward if reward key is pressed
    if ( key_code(INTERFACE.rwd_key) && INTERFACE.use_arduino )
      comm.reward( 'A', REWARDS.key_press );
    end
  end
  
  %   Quit if time exceeds total time
  if ( TIMER.duration_met('task') ), break; end;  
end

Screen( 'Flip', WINDOW.index );

TRACKER.shutdown();

if ( INTERFACE.save_data )
  data = struct();
  data.DATA = DATA;
  data.opts = opts;
  data.config = hww_gng.config.load();
  data.date = datestr( now );
  save( fullfile(IO.data_folder, IO.data_file), 'data' );
end

end

function fname = configure_reward_size_cue(reward_size_cue, reward_images, reward_size_name)

if ( ~isa(reward_size_cue, 'Image') )
  warning( 'Stimulus was not an image; returning ...' );
  return
end

if ( ~isfield(reward_images, reward_size_name) )
  warning( 'No images match reward size: "%s".', reward_size_name );
  return
end

images_this_size = reward_images.(reward_size_name);

N = numel( images_this_size.matrices );

if ( N == 0 )
  warning( 'No images were present.' );
  return
end

ind = randi( N, 1 );
fname = images_this_size.filenames{ind};

reward_size_cue.image = images_this_size.matrices{ind};

end

function name = get_reward_size_name(index)

switch ( index )
  case 1
    name = 'small';
  case 2
    name = 'medium';
  case 3
    name = 'large';
  otherwise
    error( 'Unrecognized reward index: %d', index );
end

end

function idx = get_next_reward_size_index(block_size, n_conditions)

persistent indices;
persistent stp;

if ( isempty(stp) || stp == block_size )
  stp = 1;
  indices = hww_gng.util.get_blocked_condition_indices( 1, block_size, n_conditions );  
else
  stp = stp + 1;
end

idx = indices(stp);

end

function c = get_target_image_category(categories)

if ( isempty(categories) )
  warning( 'No social image categories specified.' );
  c = '';
  return
end

inds = randperm( numel(categories) );
c = categories{inds(1)};

end