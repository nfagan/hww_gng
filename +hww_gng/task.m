function task(opts)

IO =        opts.IO;
TIMINGS =   opts.TIMINGS;
TIMER =     opts.TIMER;
TRACKER =   opts.TRACKER;
STRUCTURE = opts.STRUCTURE;
STIMULI =   opts.STIMULI;
REWARDS =   opts.REWARDS;
WINDOW =    opts.WINDOW;

cstate = 'new_trial';

do_once = true;

DATA = struct();
TRIAL_NUMBER = 0;

while ( true )
  
  if ( isequal(cstate, 'new_trial') )
    if ( do_once )
      %   RECORD DATA
      if ( TRIAL_NUMBER > 0 )
        tn = TRIAL_NUMBER;
        DATA(tn).trial_type =             trial_type;
        DATA(tn).cue_type =               cue_type;
        DATA(tn).image_file =             current_image_file;
        DATA(tn).target_placement =       target_placement;
        DATA(tn).cue_delay =              cue_delay;
        DATA(tn).reaction_time =          reaction_time;
        DATA(tn).error__no_fixation =     error__no_fixation;
        DATA(tn).error__wrong_go_nogo =   error__wrong_go_nogo;
      end
      TRIAL_NUMBER = TRIAL_NUMBER + 1;
      TIMER.reset_timers( cstate );
      %   establish go v no go, social v. nonsocial
      is_go = rand() < STRUCTURE.p_go;
      is_social = rand() < STRUCTURE.p_social;
      is_target_left = rand() < STRUCTURE.p_target_left;
      images = STIMULI.images;
      go_cue = STIMULI.go_cue;
      nogo_cue = STIMULI.nogo_cue;
      %   establish variable cue display time
      delays = TIMINGS.delays.delay_post_cue_display;
      n_delays = numel( delays );
      delays = delays( randperm(n_delays) );
      cue_delay = delays(1);
      %   establish cue placement
      if ( is_target_left )
        target_placement = 'center-left';
      else target_placement = 'center-right';
      end
      %   reset reaction time
      reaction_time = 0;
      %   reset errors
      error__no_fixation = false;
      error__wrong_go_nogo = false;
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
      %   get current image file
      select_images = images.(trial_type).(cue_type).matrices;
      select_files = images.(trial_type).(cue_type).filenames;
      n_images = numel( select_images );
      perm_index = randperm( n_images );
      select_images = select_images( perm_index );
      select_files = select_files( perm_index );
      cue.image = select_images{1};
      current_image_file = select_files{1};
      do_once = false;
    end
    if ( TIMER.duration_met('new_trial') )
      %   MARK: goto: new_trial
      cstate = 'fixation';
      do_once = true;
    end
  end
  
  if ( isequal(cstate, 'fixation') )
    if ( do_once )
      TIMER.reset_timers( cstate );
      fix_square = STIMULI.fix_square;
      fix_square.reset_targets();
      do_once = false;
    end
    TRACKER.update_coordinates();
    fix_square.update_targets();
    fix_square.draw();
    Screen( 'Flip', WINDOW.index );
    if ( fix_square.duration_met() )
      %   MARK: goto: display_go_nogo_cue
      cstate = 'display_go_nogo_cue';
      do_once = true;
    end
    if ( TIMER.duration_met('fixation') )
      %   MARK: goto: fixation
      error__no_fixation = true;
      cstate = 'new_trial';
      do_once = true;
    end
  end
  
  if ( isequal(cstate, 'display_go_nogo_cue') )
    if ( do_once )
      TIMER.reset_timers( cstate );
      cue.put( 'center' );
      do_once = false;
    end
    TRACKER.update_coordinates();
    cue.draw();
    Screen( 'Flip', WINDOW.index );
    if ( TIMER.duration_met('display_go_nogo_cue') )
      %   MARK: goto: delay_post_cue_display
      cstate = 'delay_post_cue_display';
      do_once = true;
    end
  end
  
  if ( isequal(cstate, 'delay_post_cue_display') )
    if ( do_once )
      TIMER.set_durations( cstate, cue_delay );
      TIMER.reset_timers( cstate );
      do_once = false;
    end
    cue.draw();
    Screen( 'Flip', WINDOW.index );
    if ( TIMER.duration_met('delay_post_cue_display') )
      %   MARK: goto: go_nogo
      cstate = 'go_nogo';
      do_once = true;
    end
  end
  
  if ( isequal(cstate, 'go_nogo') )
    if ( do_once )
      TIMER.reset_timers( cstate );
      go_target = STIMULI.go_target;
      go_target.put( target_placement );
      cue.put( 'center' );
      targ_duration = go_target.targets{1}.duration;
      awaiting_next_state = true;
      next_state = [];
      state_entry_time = TIMER.get_time( cstate );
      do_once = false;
    end
    TRACKER.update_coordinates();
    go_target.update_targets();
    go_target.draw();
    cue.draw();
    Screen( 'Flip', WINDOW.index );
    if ( ~is_go )
      %   if they look at the go target ...
      if ( awaiting_next_state )
        if ( go_target.in_bounds() )
          next_state = 'error_go_nogo';
          current_time = TIMER.get_time( 'go_nogo' );
          reaction_time = current_time - state_entry_time - targ_duration;
          awaiting_next_state = false;
        else
          next_state = 'reward';
        end
      end
    else
      if ( awaiting_next_state && go_target.duration_met() )
        current_time = TIMER.get_time( 'go_nogo' );
        reaction_time = current_time - state_entry_time - targ_duration;
        next_state = 'reward';
        awaiting_next_state = false;
      end
    end
    if ( TIMER.duration_met('go_nogo') )
      %   MARK: goto: error_go_nogo OR reward
      if ( isequal(next_state, []) )
        next_state = 'error_go_nogo'; 
      end
      cstate = next_state;
      do_once = true;
    end
  end
  
  if ( isequal(cstate, 'error_go_nogo') )
    if ( do_once )
      TIMER.reset_timers( cstate );
      error_cue = STIMULI.error_cue;
      error__wrong_go_nogo = true;
      do_once = false;
    end
    error_cue.draw();
    Screen( 'Flip', WINDOW.index );
    if ( TIMER.duration_met('error_go_nogo') )
      %   MARK: goto: iti
      cstate = 'iti';
      do_once = true;
    end
  end
  
  if ( isequal(cstate, 'reward') )
    if ( do_once )
      TIMER.reset_timers( cstate );
      rwd_drop = STIMULI.rwd_drop;
      do_once = false;
    end
    rwd_drop.draw();
    Screen( 'Flip', WINDOW.index );
    if ( TIMER.duration_met('reward') )
      %   MARK: goto: iti
      cstate = 'iti';
      do_once = true;
    end
  end
  
  if ( isequal(cstate, 'iti') )
    if ( do_once )
      TIMER.reset_timers( cstate );
      Screen( 'Flip', WINDOW.index );
      do_once = false;
    end
    if ( TIMER.duration_met('iti') )
      %   MARK: goto: new_trial
      cstate = 'new_trial';
      do_once = true;
    end
  end
  
  %   Quit if error in EyeLink
  err = TRACKER.check_recording();
  if ( err ~= 0 ), break; end;
  
  %   Quit if key is pressed
  [key_pressed, ~, ~] = KbCheck();
  if ( key_pressed ), break; end
  
  %   Quit if time exceeds total time
  if ( TIMER.duration_met('task') ), break; end;  
end

save( fullfile(IO.data_folder, IO.data_file), 'DATA' );

end