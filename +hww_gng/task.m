function task(opts)

TIMINGS =   opts.TIMINGS;
TIMER =     opts.TIMER;
TRACKER =   opts.TRACKER;
STRUCTURE = opts.STRUCTURE;
STIMULI =   opts.STIMULI;
REWARDS =   opts.REWARDS;
WINDOW =    opts.WINDOW;

cstate = 'new_trial';

do_once = true;

DATA.trial = nan( 1e3, 1 );

while ( true )
  
  if ( isequal(cstate, 'new_trial') )
    if ( do_once )
      TIMER.reset_timers( cstate );
      %   establish go v no go, social v. nonsocial
      is_go = rand() < STRUCTURE.p_go;
      is_social = rand() < STRUCTURE.p_social;
      images = STIMULI.images;
      go_cue = STIMULI.go_cue;
      nogo_cue = STIMULI.nogo_cue;
      %   establish variable cue display time
      delays = TIMINGS.delays.delay_post_cue_display;
      n_delays = numel( delays );
      delays = delays( randperm(n_delays) );
      cue_delay = delays(1);
      if ( is_go )
        cue = go_cue;
        kind = 'go';
      else
        cue = nogo_cue;
        kind = 'nogo';
      end
      if ( is_social )
        select_images = images.(kind).social;
      else
        select_images = images.(kind).nonsocial;
      end
      n_images = numel( select_images );
      select_images = select_images( randperm(n_images) );
      cue.image = select_images{1};
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
      cstate = 'fixation';
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
      go_target.put( 'center-right' );
      cue.put( 'center' );
      awaiting_next_state = true;
      next_state = [];
      do_once = false;
    end
    TRACKER.update_coordinates();
    go_target.update_targets();
    go_target.draw();
    cue.draw();
    if ( ~is_go )
      cue.draw_frame();
    end
    Screen( 'Flip', WINDOW.index );
    if ( ~is_go )
      %   if they look at the go target ...
      if ( awaiting_next_state )
        if ( go_target.in_bounds() )
          next_state = 'error_go_nogo';
          awaiting_next_state = false;
        else
          next_state = 'reward';
        end
      end
    else
      if ( awaiting_next_state && go_target.duration_met() )
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


end