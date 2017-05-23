function opts = setup()

% - STATES - %
STATES.sequence = { 'new_trial', 'fixation', 'display_go_nogo_cue' ...
  , 'delay_post_cue_display', 'go_nogo', 'error_go_nogo', 'reward', 'iti' };

% - SCREEN + WINDOW - %
SCREEN = ScreenManager();
WINDOW = SCREEN.open_window( 0, [0 0 0] );

% - IO - %
IO.repo_dir = hww_gng.util.get_repo_dir();
IO.edf_file = 'txst.edf';
IO.data_file = 'txst.mat';
IO.edf_folder = fullfile( IO.repo_dir, 'hww_gng', 'data' );
IO.data_folder = fullfile( IO.repo_dir, 'hww_gng', 'data' );
IO.stim_path = fullfile( IO.repo_dir, 'hww_gng', 'stimuli' );

% - META - %
META.session = '';
META.data = '';
META.monkey = '';
META.etc = '';

% - INTERFACE - %
INTERFACE.use_eyelink = false;
INTERFACE.use_arduino = false;

assert__file_does_not_exist( fullfile(IO.data_folder, IO.data_file) );
assert__file_does_not_exist( fullfile(IO.edf_folder, IO.edf_file) );

% - EYE TRACKER - %
TRACKER = EyeTracker( IO.edf_file, IO.edf_folder, WINDOW.index );
TRACKER.bypass = ~INTERFACE.use_eyelink;

% - STRUCTURE - %
STRUCTURE.p_go = .7;
STRUCTURE.p_social = .5;
STRUCTURE.p_target_left = .5;

% - TIMINGS - %
time_in.task = Inf;
time_in.new_trial = 0;
time_in.fixation = 2;
time_in.display_go_nogo_cue = 0;
time_in.delay_post_cue_display = 0;
time_in.go_nogo = 2;
time_in.error_go_nogo = 1;
time_in.reward = 1;
time_in.iti = 1;

fixations.fix_square = .3;
fixations.go_target = 1;
fixations.go_cue = 1;
fixations.nogo_cue = 1;

delays.delay_post_cue_display = [ .5, 1, 2 ];

TIMINGS.time_in = time_in;
TIMINGS.fixations = fixations;
TIMINGS.delays = delays;

% - TIMERS - %
TIMER = Timer();
fs = fieldnames( time_in );
for i = 1:numel(fs)
  TIMER.add_timer( fs{i}, time_in.(fs{i}) );
end

% - STIMULI - %
images.go.social =        get_images( IO.stim_path, 'go', 'social', '.png' );
images.go.nonsocial =     get_images( IO.stim_path, 'go', 'nonsocial', '.png' );
images.nogo.social =      get_images( IO.stim_path, 'nogo', 'social', '.png' );
images.nogo.nonsocial =   get_images( IO.stim_path, 'nogo', 'nonsocial', '.png' );

fix_square = WINDOW.Rectangle( [200, 200] );
fix_square.color = [ 200, 200, 40 ];
fix_square.put( 'center' );
fix_square.make_target( TRACKER, fixations.fix_square );

go_target = WINDOW.Rectangle( [150, 150] );
go_target.color = [ 50, 200, 40 ];
go_target.put( 'center-right' );
go_target.make_target( TRACKER, fixations.go_target );

go_cue = WINDOW.Image( [200, 200], images.go.social.matrices{1} );
go_cue.color = [ 255 255 255 ];
go_cue.put( 'center' );
go_cue.make_target( TRACKER, fixations.go_cue );

nogo_cue = WINDOW.Image( [200, 200], images.nogo.social.matrices{1} );
nogo_cue.color = [ 255 255 255 ];
nogo_cue.pen_width = 4;
nogo_cue.put( 'center' );
nogo_cue.make_target( TRACKER, fixations.nogo_cue );

err_img = imread( fullfile(pathfor('hww_gng'), 'stimuli', 'err', 'err.png') );
error_cue = WINDOW.Image( [200, 200], err_img );
error_cue.put( 'center' );

drop_img = imread( fullfile(pathfor('hww_gng'), 'stimuli', 'reward', 'droplet.png') );
rwd_drop = WINDOW.Image( [200, 200], drop_img );
rwd_drop.put( 'center' );

STIMULI.fix_square = fix_square;
STIMULI.go_target = go_target;
STIMULI.go_cue = go_cue;
STIMULI.nogo_cue = nogo_cue;
STIMULI.images = images;
STIMULI.error_cue = error_cue;
STIMULI.rwd_drop = rwd_drop;

% - SERIAL - %

port = 'COM3';
messages = struct();
channels = { 'A' };

if ( INTERFACE.use_arduino )
  SERIAL.comm = serial_comm.SerialManager( port, messages, channels );
else
  SERIAL.comm = [];
end
SERIAL.port = port;
SERIAL.messages = messages;
SERIAL.channels = channels;

% - REWARDS - %
REWARDS.main = 100;

% - STORE - %
opts.STATES =     STATES;
opts.SCREEN =     SCREEN;
opts.WINDOW =     WINDOW;
opts.IO =         IO;
opts.META =       META;
opts.TRACKER =    TRACKER;
opts.STRUCTURE =  STRUCTURE;
opts.TIMINGS =    TIMINGS;
opts.TIMER =      TIMER;
opts.STIMULI =    STIMULI;
opts.REWARDS =    REWARDS;

end

function images = get_images( stim_path, go_nogo, soc_nonsoc, extension )

stim_path =         fullfile( stim_path, go_nogo, soc_nonsoc );
image_names =       hww_gng.util.dirstruct( stim_path, extension );
image_names =       { image_names(:).name };
images.matrices =   cellfun( @(x) imread(fullfile(stim_path, x)) ...
                      , image_names, 'un', false );
images.filenames =  image_names;

end

function assert__file_does_not_exist( file )

assert( exist(file, 'file') ~= 2, 'The file ''%s'' already exists.', file );

end