function create()

%   CREATE -- Create the config file.
%
%     Set default values in this file; to edit them, load the config file
%     via opts = hww_gng.config.load(). Edit the loaded config file, then
%     save it with hww_gng.config.save( opts ).

% - STATES - %
STATES.sequence = { 'new_trial', 'fixation', 'display_go_nogo_cue' ...
  , 'delay_post_cue_display', 'go_nogo', 'error_go_nogo', 'reward', 'iti' };

% - SCREEN + WINDOW - %
SCREEN.index = 0;
SCREEN.bg_color = [ 0 0 0 ];
SCREEN.rect = [];

% - IO - %
IO.repo_dir = hww_gng.util.get_repo_dir();
IO.edf_file = 'txst.edf';
IO.data_file = 'txst.mat';
IO.edf_folder = fullfile( IO.repo_dir, 'hww_gng', 'data' );
IO.data_folder = fullfile( IO.repo_dir, 'hww_gng', 'data' );
IO.stim_path = fullfile( IO.repo_dir, 'hww_gng', 'stimuli' );
IO.gui_fields.include = { 'data_file', 'edf_file' };

% - META - %
META.session = '';
META.data = '';
META.monkey = '';
META.etc = '';
META.block = '';

% - INTERFACE - %
KbName( 'UnifyKeyNames' );
INTERFACE.use_eyelink = true;
INTERFACE.use_arduino = true;
INTERFACE.save_data = true;
INTERFACE.allow_overwrite = false;
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.rwd_key = KbName( 'r' );
INTERFACE.gui_fields.exclude = { 'stop_key', 'rwd_key' };

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

delays.delay_post_cue_display = 0:.05:1.5;

TIMINGS.time_in = time_in;
TIMINGS.fixations = fixations;
TIMINGS.delays = delays;

% - STIMULI - %
images.go.social =        get_images( IO.stim_path, {'go', 'social'}, '.png' );
images.go.nonsocial =     get_images( IO.stim_path, {'go', 'nonsocial'}, '.png' );
images.nogo.social =      get_images( IO.stim_path, {'nogo', 'social'}, '.png' );
images.nogo.nonsocial =   get_images( IO.stim_path, {'nogo', 'nonsocial'}, '.png' );
images.error =            get_images( IO.stim_path, {'err'}, '.png' );
images.reward =           get_images( IO.stim_path, {'reward'}, '.png' );

STIMULI.setup.images = images;
STIMULI.setup.gui_fields.exclude = { 'images' };

non_editable_properties = {{ 'placement', 'has_target', 'image_matrix' }};
STIMULI.setup.fix_square = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 200, 200 ] ...
  , 'color',            [ 200, 200, 40 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.fix_square ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.go_target = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 150, 150 ] ...
  , 'color',            [ 50, 200, 40 ] ...
  , 'placement',        'center-right' ...
  , 'displacement',     [ 0 0 ] ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.go_target...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.go_cue = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     images.go.social.matrices{1} ...
  , 'size',             [ 200, 200 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.go_cue ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.nogo_cue = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     images.nogo.social.matrices{1} ...
  , 'size',             [ 200, 200 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.nogo_cue ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.error_cue = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     images.error.matrices{1} ...
  , 'size',             [ 200, 200 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.rwd_drop = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     images.reward.matrices{1} ...
  , 'size',             [ 200, 200 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

% - SERIAL - %
SERIAL.port = 'COM5';
SERIAL.messages = struct();
SERIAL.channels = { 'A' };
SERIAL.gui_fields.include = { 'port' };

% - REWARDS - %
REWARDS.main = 200;

% - STORE - %
opts.STATES =     STATES;
opts.INTERFACE =  INTERFACE;
opts.SCREEN =     SCREEN;
opts.IO =         IO;
opts.META =       META;
opts.STRUCTURE =  STRUCTURE;
opts.TIMINGS =    TIMINGS;
opts.STIMULI =    STIMULI;
opts.SERIAL =     SERIAL;
opts.REWARDS =    REWARDS;

hww_gng.config.save( opts );
hww_gng.config.save( opts, '-default' );

end

function images = get_images( stim_path, subdirs, extension )

stim_path =         fullfile( stim_path, subdirs{:} );
image_names =       hww_gng.util.dirstruct( stim_path, extension );
image_names =       { image_names(:).name };
images.matrices =   cellfun( @(x) imread(fullfile(stim_path, x)) ...
                      , image_names, 'un', false );
images.filenames =  image_names;

end