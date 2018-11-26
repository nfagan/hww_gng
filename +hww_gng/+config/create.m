function opts = create(do_save)

%   CREATE -- Create the config file.
%
%     Set default values in this file; to edit them, load the config file
%     via opts = hww_gng.config.load(). Edit the loaded config file, then
%     save it with hww_gng.config.save( opts ).

if ( nargin < 1 )
  do_save = true;
end

% - STATES - %
STATES.sequence = { 'new_trial', 'fixation', 'display_go_nogo_cue' ...
  , 'delay_post_cue_display', 'go_nogo', 'error_go_nogo', 'reward', 'iti' ...
  , 'error_broke_cue_fixation' };

% - SCREEN + WINDOW - %
SCREEN.index = 2;
SCREEN.bg_color = [ 0 0 0 ];
SCREEN.rect = [];

% - IO - %
IO.repo_dir = hww_gng.util.get_repo_dir();
IO.edf_file = 'txst.edf';
IO.data_file = 'txst.mat';
IO.edf_folder = fullfile( IO.repo_dir, 'hww_gng', 'data' );
IO.data_folder = fullfile( IO.repo_dir, 'hww_gng', 'data' );
IO.stim_path = fullfile( IO.repo_dir, 'hww_gng', 'stimuli' );
IO.dependencies = struct( 'repositories', {{ 'ptb_helpers', 'serial_comm' }} );
IO.gui_fields.include = { 'data_file', 'edf_file' };

% - META - %
META.date = '';
META.session = '';
META.block = '';
META.monkey = '';
META.dose = '';
META.notes = '';

% - INTERFACE - %
KbName( 'UnifyKeyNames' );
INTERFACE.use_eyelink = true;
INTERFACE.use_arduino = true;
INTERFACE.save_data = true;
INTERFACE.allow_overwrite = false;
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.rwd_key = KbName( 'r' );
INTERFACE.skip_sync_tests = false;
INTERFACE.gui_fields.exclude = { 'stop_key', 'rwd_key' };

% - STRUCTURE - %
STRUCTURE.p_go = .7;
STRUCTURE.p_social = .5;
STRUCTURE.p_target_left = .5;
STRUCTURE.target_types = 'nonsocial';
STRUCTURE.use_reward_cue = 0;
STRUCTURE.reward_block_size = 9;
STRUCTURE.max_n_images = inf;

% - TIMINGS - %
time_in.task = Inf;
time_in.new_trial = 0;
time_in.fixation = 2;
time_in.display_go_nogo_cue = 0;
time_in.delay_post_cue_display = 0;
time_in.go_nogo = 2;
time_in.delay_post_go = 0.5;
time_in.error_go_nogo = 3;
time_in.error_broke_cue_fixation = 3;
time_in.reward = .5;
time_in.iti = 1;
time_in.display_reward_info_cue = 1;
time_in.reward_info_cue_error = 1;

fixations.fix_square = .3;
fixations.go_target = 1;
fixations.go_cue = 1;
fixations.nogo_cue = 1;

%delays.delay_post_cue_display = 0:.05:1.5;
delays.delay_post_cue_display = 0:.05:0.1;

TIMINGS.time_in = time_in;
TIMINGS.fixations = fixations;
TIMINGS.delays = delays;

% - STIMULI - %
images.go.social =            get_images( IO.stim_path, {'go', 'social'}, '.png' );
images.go.nonsocial =         get_images( IO.stim_path, {'go', 'nonsocial'}, '.png' );
images.nogo.social =          get_images( IO.stim_path, {'nogo', 'social'}, '.png' );
images.nogo.nonsocial =       get_images( IO.stim_path, {'nogo', 'nonsocial'}, '.png' );
images.error =                get_images( IO.stim_path, {'err'}, '.png' );
images.reward =               get_images( IO.stim_path, {'reward'}, '.png' );
images.targets.social =       get_images( IO.stim_path, {'targets', 'social'}, '.png' );
images.targets.nonsocial =    get_images( IO.stim_path, {'targets', 'nonsocial'}, '.png' );

STIMULI.setup.images = images;
STIMULI.setup.gui_fields.exclude = { 'images' };

non_editable_properties = {{ 'placement', 'has_target', 'image_matrix' }};
STIMULI.setup.fix_square = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 75, 75 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.fix_square ...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.reward_size_border = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 1600, 900 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'pen_width',        100 ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);  

STIMULI.setup.go_target = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 75, 75 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'displacement',     [ 150 0 ] ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.go_target...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.go_cue = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     images.go.social.matrices{1} ...
  , 'size',             [ 400, 400 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.go_cue ...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.nogo_cue = struct( ...
    'class',            'Image' ...
  , 'image_matrix',     images.nogo.social.matrices{1} ...
  , 'size',             [ 400, 400 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.nogo_cue ...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.error_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 800, 800 ] ...
  , 'color',            [ 204, 247, 131 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.error_cue_broke_cue_fixation = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 800, 800 ] ...
  , 'color',            [ 204, 247, 131 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.rwd_drop = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 800, 800 ] ...
  , 'color',            [ 8, 56, 214 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.reward_size_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 800, 800 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  1 ...
  , 'target_padding',   50 ...
  , 'non_editable',     non_editable_properties ...
);

% STIMULI.setup.error_cue = struct( ...
%     'class',            'Image' ...
%   , 'image_matrix',     images.error.matrices{1} ...
%   , 'size',             [ 200, 200 ] ...
%   , 'color',            [ 255, 255, 255 ] ...
%   , 'placement',        'center' ...
%   , 'has_target',       false ...
%   , 'non_editable',     non_editable_properties ...
% );
% 
% STIMULI.setup.rwd_drop = struct( ...
%     'class',            'Image' ...
%   , 'image_matrix',     images.reward.matrices{1} ...
%   , 'size',             [ 200, 200 ] ...
%   , 'color',            [ 255, 255, 255 ] ...
%   , 'placement',        'center' ...
%   , 'has_target',       false ...
%   , 'non_editable',     non_editable_properties ...
% );

% - SERIAL - %
SERIAL.reward_port = 'COM5';
SERIAL.plex_port = 'COM7';
SERIAL.messages = struct();
SERIAL.channels = { 'A' };
SERIAL.gui_fields.include = { 'reward_port', 'plex_port' };

% - REWARDS - %
REWARDS.main = 200;
REWARDS.key_press = 200;
REWARDS.color_map = containers.Map( 'keytype', 'double', 'valuetype', 'any' );
REWARDS.small = 100;
REWARDS.medium = 200;
REWARDS.large = 300;
REWARDS.gui_fields.exclude = { 'color_map' };

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

if ( do_save )
  hww_gng.config.save( opts );
  hww_gng.config.save( opts, '-default' );
end

end

function images = get_images( stim_path, subdirs, extension )

stim_path =         fullfile( stim_path, subdirs{:} );
image_names =       hww_gng.util.dirstruct( stim_path, extension );
image_names =       { image_names(:).name };
images.matrices =   cellfun( @(x) imread(fullfile(stim_path, x)) ...
                      , image_names, 'un', false );
images.filenames =  image_names;

end