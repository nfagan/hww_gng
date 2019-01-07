function hww_gng_debug_eye_tracker()

KbName( 'UnifyKeyNames' );

screen_index = 0;
screen_rect = [0, 0, 800, 800];
% screen_rect = [];

bypass_tracker = false;

try
  debug_main( screen_index, screen_rect, bypass_tracker );
catch err
  warning( err.message );
end

cleanup();

end

function debug_main(screen_index, screen_rect, bypass_tracker)

window_handle = Screen( 'OpenWindow', screen_index, zeros(1, 3), screen_rect );

tracker = EyeTracker( '1.edf', pwd, window_handle );
tracker.bypass = bypass_tracker;

try
  tracker.init();

  debug_rects = get_three_rects( window_handle );

  Screen( 'FillRect', window_handle, [255, 0, 0], debug_rects );
  Screen( 'Flip', window_handle );

  n_rects = size( debug_rects, 2 );
  targets = cell( 1, n_rects );

  duration_crit = 0.1;

  for i = 1:n_rects
    targets{i} = Target( tracker, debug_rects(:, i), duration_crit );
  end

  while ( ~check_stop() )
    tracker.update_coordinates();

    none_in_bounds = true;

    for i = 1:n_rects
      targ = targets{i};

      targ.update();

      if ( targ.in_bounds )
        fprintf( '\n Target %d in bounds.', i );
        none_in_bounds = false;
      end

      if ( targ.duration_met() )
  %       fprintf( '\n\n\n Target %d met %0.2f duration criterion.\n\n', i, duration_crit );
        targ.reset();
      end
    end

    if ( none_in_bounds )
      fprintf( '\n None in bounds.' );
    end
  end
catch err
  warning( err.message );
end

try
  tracker.shutdown()
catch err
  warning( err.message );
end

end

function rects = get_three_rects(window_ptr)

screen_size = Screen( 'Rect', window_ptr );
screen_width = screen_size(3) - screen_size(1);
screen_height = screen_size(4) - screen_size(2);

rect_frac = 0.1;
base_rect = round( [0, 0, screen_width * rect_frac, screen_height * rect_frac] );

half_height = screen_height/2;

center_left = [screen_width * (1/16), half_height];
center = [screen_width * 1/2, half_height];
center_right = [screen_width - center_left(1), half_height];

left_rect = CenterRectOnPointd( base_rect, center_left(1), center_left(2) );
center_rect= CenterRectOnPointd( base_rect, center(1), center(2) );
right_rect = CenterRectOnPointd( base_rect, center_right(1), center_right(2) );

rects = [ left_rect(:), center_rect(:), right_rect(:) ];

end

function tf = check_stop()

tf = false;

[key_pressed, ~, key_code] = KbCheck();

if ( key_pressed )
  tf = key_code(KbName('escape'));
end

end

function cleanup()

sca();

end