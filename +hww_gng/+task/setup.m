function opts = setup()

%   SETUP -- Prepare to run the task based on the saved config file.
%
%     Opens windows, starts EyeTracker, initializes Arduino, etc.
%
%     OUT:
%       - `opts` (struct) -- Config file, with additional parameters
%         appended.

%   make sure Psychtoolbox is on the search path
hww_gng.util.try_add_ptoolbox();
hww_gng.util.update_images();

opts = hww_gng.config.load();
opts = hww_gng.config.reconcile( opts );

IO =        opts.IO;
INTERFACE = opts.INTERFACE;
TIMINGS =   opts.TIMINGS;
STIMULI =   opts.STIMULI;
SERIAL =    opts.SERIAL;

Screen( 'Preference', 'SkipSyncTests', double(INTERFACE.skip_sync_tests) );

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

% - IMAGES - %
images = STIMULI.setup.images;

image_categories = shared_utils.io.dirnames( fullfile(opts.IO.stim_path, 'targets', 'social'), 'folders' );
img_exts = { '.png', '.jpg', '.jpeg', '.JPG' };
max_n_images = opts.STRUCTURE.max_n_images;

fprintf( '\n Loading images ...' );

for i = 1:numel(image_categories)
  c = image_categories{i};
  images.targets.social.(c) = get_images( opts.IO.stim_path, {'targets', 'social', c}, img_exts, max_n_images );
  images.targets.nonsocial.(c) = get_images( opts.IO.stim_path, {'targets', 'nonsocial', c}, img_exts, max_n_images );
end

size_categories = shared_utils.io.dirnames( fullfile(opts.IO.stim_path, 'reward', 'size_cues'), 'folders' );

for i = 1:numel(size_categories)
  c = size_categories{i};
  images.reward_size_cues.(c) = get_images( opts.IO.stim_path, {'reward', 'size_cues', c}, img_exts, max_n_images );
end

fprintf( ' Done.' );

STIMULI.setup.target_image_categories = image_categories;
STIMULI.setup.images = images;

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
      if ( isfield(stim, 'image_matrix') )
        im = stim.image_matrix;
      else
        im = [];
      end
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
  
  if ( isfield(stim, 'pen_width') )
    stim_.pen_width = stim.pen_width;
  end
  
  STIMULI.(stim_fs{i}) = stim_;
end

% - SERIAL - %

SERIAL.plex_comm = hww_gng.arduino.plex_comm( SERIAL.plex_port );
SERIAL.plex_comm.bypass = ~INTERFACE.use_arduino;

if ( INTERFACE.use_arduino )
  reward_port = SERIAL.reward_port;
  messages = SERIAL.messages;
  channels = SERIAL.channels;
  SERIAL.comm = serial_comm.SerialManager( reward_port, messages, channels );
  SERIAL.comm.start();
  SERIAL.plex_comm.start();
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

function images = get_images( stim_path, subdirs, extension, max_n )

stim_path = fullfile( stim_path, subdirs{:} );

if ( ischar(extension) ), extension = { extension }; end

image_names = cellfun( @(x) get_image_names_one_ext(stim_path, x), extension(:)', 'un', 0 );
image_names = horzcat( image_names{:} );

if ( ~isinf(max_n) )
  use_n = min( numel(image_names), max_n );
  image_names = image_names(1:use_n);
end

images.matrices = cellfun( @(x) imread(fullfile(stim_path, x)), image_names, 'un', false );
images.filenames = image_names;

end

function image_names = get_image_names_one_ext(stim_path, ext)
image_names = hww_gng.util.dirstruct( stim_path, ext );
image_names = { image_names(:).name };
end