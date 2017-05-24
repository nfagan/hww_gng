function opts = setup()

%   SETUP -- Prepare to run the task based on the saved config file.
%
%     Opens windows, starts EyeTracker, initializes Arduino, etc.
%
%     OUT:
%       - `opts` (struct) -- Config file, with additional parameters
%         appended.

opts = hww_gng.config.load();

IO =        opts.IO;
INTERFACE = opts.INTERFACE;
TIMINGS =   opts.TIMINGS;
STIMULI =   opts.STIMULI;
SERIAL =    opts.SERIAL;

KbName( 'UnifyKeyNames' );

addpath( genpath(fullfile(IO.repo_dir, 'ptb_helpers')) );
addpath( genpath(fullfile(IO.repo_dir, 'serial_comm')) );

if ( INTERFACE.save_data && ~INTERFACE.allow_overwrite )
  hww_gng.util.assert__file_does_not_exist( fullfile(IO.data_folder, IO.data_file) );
  hww_gng.util.assert__file_does_not_exist( fullfile(IO.edf_folder, IO.edf_file) );
end

% - SCREEN + WINDOW - %
SCREEN = ScreenManager();

index = opts.SCREEN.index;
bg_color = opts.SCREEN.bg_color;
rect = opts.SCREEN.rect;

WINDOW = SCREEN.open_window( index, bg_color, rect );

% - TRACKER - %
TRACKER = EyeTracker( IO.edf_file, IO.edf_folder, WINDOW.index );
TRACKER.bypass = ~INTERFACE.use_eyelink;
TRACKER.init();

% - TIMERS - %
TIMER = Timer();
TIMER.register( TIMINGS.time_in );

% - STIMULI - %
stim_fs = fieldnames( STIMULI.setup );
for i = 1:numel(stim_fs)
  stim = STIMULI.setup.(stim_fs{i});
  if ( ~isstruct(stim) ), continue; end;
  if ( ~isfield(stim, 'class') ), continue; end
  switch ( stim.class )
    case 'Rectangle'
      stim_ = WINDOW.Rectangle( stim.size );
    case 'Image'
      im = stim.image_matrix;
      stim_ = WINDOW.Image( stim.size, im );
  end
  stim_.color = stim.color;
  stim_.put( stim.placement );
  if ( stim.has_target )
    duration = stim.target_duration;
    padding = stim.target_padding;
    stim_.make_target( TRACKER, duration );
    stim_.targets{1}.padding = padding;
  end
  STIMULI.(stim_fs{i}) = stim_;
end

% - SERIAL - %
if ( INTERFACE.use_arduino )
  port = SERIAL.port;
  messages = SERIAL.messages;
  channels = SERIAL.channels;
  SERIAL.comm = serial_comm.SerialManager( port, messages, channels );
else
  SERIAL.comm = [];
end

% - STORE - %
opts.SCREEN =     SCREEN;
opts.WINDOW =     WINDOW;
opts.TRACKER =    TRACKER;
opts.TIMER =      TIMER;
opts.STIMULI =    STIMULI;
opts.SERIAL =     SERIAL;

end