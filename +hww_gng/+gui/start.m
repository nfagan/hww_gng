function varargout = start(varargin)

%   START -- Create the HWW_GNG GUI.
%
%     IN:
%       - `varargin` (/any/) |OPTIONAL| -- Optionally pass in a
%         figure handle in which to create the GUI. If unspecified, a new
%         figure window will be created.
%     OUT:
%       - `varargout` (cell) -- Handle to the GUI figure, and optionally
%         the config file.

narginchk( 0, 1 );

config = hww_gng.config.reconcile( hww_gng.config.load() );

persistent figure_handle;

if ( nargin == 1 )
  F = varargin{1};
  set_position = false;
else
  if ( isempty(figure_handle) || ~isvalid(figure_handle) )
    F = figure;
    set_position = true;
    figure_handle = F;
  else
    F = figure_handle;
    set_position = false;
  end
end

F_W = .75;
F_L = .8;
F_X = (1-F_W)/2;
F_Y = (1-F_L)/2;

N = 3;    %   n panels
W = .9;
Y = 0.05;
X = (1 - W) / 2;
L = (1 / N) - Y/2;

set( F, 'visible', 'off' );
set( F, 'resize', 'on' );
set( F, 'menubar', 'none' );
set( F, 'toolbar', 'none' );
set( F, 'units', 'normalized' );
set( F, 'name', 'go-nogo' );

% - INTERFACE - %
panels.interface = uipanel( F ...
  , 'Title', 'Interface' ...
  , 'Position', [ X, Y, W, L ] ...
);

% - Check boxes
interface_fs = get_gui_fields( config.INTERFACE );

w = .5;
l = 1 / numel(interface_fs);
x = 0;
y = 0;

for i = 1:numel(interface_fs)
  check_name = interface_fs{i};
  position = [ x, y, w, l ];
  uicontrol( panels.interface ...
    , 'Style', 'checkbox' ...
    , 'String', check_name ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
    , 'Value', config.INTERFACE.(check_name) ...
    , 'Callback', @handle_checkbox ...
  );
  y = y + l;
end

% - IO
panels.io = uipanel( panels.interface ...
  , 'Title', 'IO' ...
  , 'Position', [ .25, 0, .25, .5 ] ...
);
text_pos =  struct( 'x', 0, 'y',  0, 'w', .5 );
field_pos = struct( 'x', .5, 'y', 0, 'w', .5 );
text_field_creator( panels.io, 'IO', {}, text_pos, field_pos );

% - SCREEN
panels.screen = uipanel( panels.interface ...
  , 'Title', 'Screen/Window' ...
  , 'Position', [ .25, .5, .25, .5 ] ...
);
text_pos =  struct( 'x', 0, 'y',  0, 'w', .5 );
field_pos = struct( 'x', .5, 'y', 0, 'w', .5 );
text_field_creator( panels.screen, 'SCREEN', {}, text_pos, field_pos );

% - Delays

panels.delays = uipanel( panels.interface ...
  , 'Title', 'Delays' ...
  , 'Position', [ .5, 0, .25, .33 ] ...
);
text_pos =  struct( 'x', 0, 'y',  0, 'w', .5 );
field_pos = struct( 'x', .5, 'y', 0, 'w', .5 );
text_field_creator( panels.delays, 'TIMINGS', {'delays'}, text_pos, field_pos );

% - Serial port specifiers
panels.serial = uipanel( panels.interface ...
  , 'Title', 'Serial' ...
  , 'Position', [ .5, .33, .25, .33 ] ...
);
text_pos =  struct( 'x', 0, 'y',  0, 'w', .5 );
field_pos = struct( 'x', .5, 'y', 0, 'w', .5 );
text_field_creator( panels.serial, 'SERIAL', {}, text_pos, field_pos );

% - Rewards - %
panels.reward = uipanel( panels.interface ...
  , 'Title', 'Reward' ...
  , 'Position', [ .5, .66, .25, .33 ] ...
);

reward_panel = shared_utils.gui.TextFieldDropdown();
reward_panel.parent = panels.reward;
reward_panel.on_change = @handle_reward_change;
reward_panel.set_data( config.REWARDS );

% - STRUCTURE - %
panels.structure = uipanel( panels.interface ...
  , 'Title', 'Structure' ...
  , 'Position', [ .75, 0, .25, 1 ] ...
);

structure_panel = shared_utils.gui.TextFieldDropdown();
structure_panel.parent = panels.structure;
structure_panel.orientation = 'vertical';
structure_panel.on_change = @handle_structure_change;
structure_panel.set_data( config.STRUCTURE );

Y = Y + L;

% - STIMULI - %
panels.stimuli = uipanel( F ...
  , 'Title', 'Stimuli' ...
  , 'Position', [ X, Y, W/2, L ] ...
);
% - pop ups
stimuli_fs = get_gui_fields( config.STIMULI.setup );
handle_stimuli_popup();

% - TASK TIMES
panels.time_in = uipanel( F ...
  , 'Title', 'Time in states' ...
  , 'Position', [ X+W/2, Y, W/2, L ] ...
);
text_pos = struct( 'x', 0, 'y', 0, 'w', .5 );
field_pos = struct( 'x', .5, 'y', 0, 'w', .5 );
text_field_creator( panels.time_in, 'TIMINGS', {'time_in'}, text_pos, field_pos );

Y = Y + L;

% - Buttons
panels.run = uipanel( F ...
  , 'Title', 'Run' ...
  , 'Position', [ X, Y, W, L ] ...
);

funcs = { 'hard reset', 'reset to default', 'make default', 'check latest edf' ...
  , 'clean-up', 'setup reward sizes', 'start' };
w = .5;
l = 1 / numel(funcs);
x = 0;
y = 0;

for i = 1:numel(funcs)
  func_name = funcs{i};
  position = [ x, y, w, l ];
  uicontrol( panels.run ...
    , 'Style', 'pushbutton' ...
    , 'String', func_name ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
    , 'Callback', @handle_button ...
  );
  y = y + l;
end

% - Meta
text_pos = struct( 'x', .5, 'y', 0, 'w', .1 );
field_pos = struct( 'x', .6, 'y', 0, 'w', .4 );
text_field_creator( panels.run, 'META', {}, text_pos, field_pos );

% - COMPLETE
if ( set_position )
  set( F, 'position', [F_X, F_Y, F_W, F_L] );
end

if ( nargout == 1 )
  varargout{1} = F;
elseif ( nargout == 2 )
  varargout{1} = F;
  varargout{2} = config;
end

set( F, 'visible', 'on' );

%{
    EVENT HANDLERS
%}

function handle_checkbox(source, event)
  
  %   HANDLE_CHECKBOX -- Handle checkbox clicks.

  chk_name = source.String;
  config.INTERFACE.(chk_name) = ~config.INTERFACE.(chk_name);
  hww_gng.config.save( config );
end

function handle_button(source, event)
  
  %   HANDLE_BUTTON -- Handle button clicks.
  
  func = source.String;
  switch ( func )
    case 'start'
      hww_gng.config.save( config );
      hww_gng.task.start();
    case 'setup reward sizes'
      handle_reward_size_setup();
    case 'clean-up'
      hww_gng.config.save( config );
      hww_gng.task.cleanup();
    case 'reset to default'
      config = hww_gng.config.load( '-default' );
      hww_gng.config.save( config );
      clf( F );
      hww_gng.gui.start( F );
    case 'check latest edf'
      hww_gng.config.save( config );
      hww_gng.util.check_latest_edf();
    case 'make default'
      hww_gng.config.save( config, '-default' );
    case 'hard reset'
      hww_gng.config.create();
      clf( F );
      hww_gng.gui.start( F );
    otherwise
      error( 'Unrecognized identifier ''%s''', source.String );
  end
end

function handle_textfields(source, event)
  
  %   HANDLE_TEXTFIELDS -- Respond to new data in a text-field.
  
  val = source.String;
  is_numeric = source.UserData.is_numeric;
  field = source.UserData.config_field;
  subfields = source.UserData.subfields;
  all_fields = [ {'config'}, {field}, subfields ];
  identifier = strjoin( all_fields, '.' );
  if ( is_numeric )
    eval( sprintf( '%s = [%s];', identifier, val ) );
    source.String = num2str( eval(sprintf('[%s]', val)) );
  else
    eval( sprintf( '%s = ''%s'';', identifier, val ) );  
  end
  hww_gng.config.save( config );
end

% - STIMULI - %

function handle_stimuli_popup(source, event)
  
  %   HANDLE_STIMULI_POP -- Create or update the stimuli drop-down selector
  %     + text-field interface.
  
  if ( nargin > 0  )
    panel_children = panels.stimuli.Children;
    stim_ind = source.Value;
    stim_name = source.String{ stim_ind };  
    delete( panel_children );
  else
    stim_ind = 1;
    stim_name = stimuli_fs{ stim_ind };
  end
  stim = config.STIMULI.setup.(stim_name);
  props = fieldnames( stim );
  non_editable = [ stim.non_editable, {'non_editable'} ];
  props = exclude_values( props, non_editable );
  
  n_controls = numel( props ) + 1;
  w_ = .5;
  l_ = 1 / n_controls;
  x_ = 0;
  y_ = 0;
  
  position_ = [ x_, y_, w_, l_ ];
  uicontrol( panels.stimuli ...
    , 'Style',  'text' ...
    , 'String', 'Stimulus name' ...
    , 'Units',  'normalized' ...
    , 'Position', position_ ...
  );
  position_ = [ x_+w_, y_, w_, l_ ];
  uicontrol( panels.stimuli ...
    , 'Style',      'popup' ...
    , 'String',     stimuli_fs ...
    , 'Value',      stim_ind ...
    , 'Units',      'normalized' ...
    , 'Tag',        'stim_selector' ...
    , 'Position',   position_ ...
    , 'Callback',   @handle_stimuli_popup ...
  );
  y_ = y_ + l_;

  for ii = 2:n_controls
    position_ = [ x_, y_, w_, l_ ];    
    prop = props{ii-1};
    uicontrol( panels.stimuli ...
      , 'Style',    'text' ...
      , 'String',   prop ...
      , 'Units',    'normalized' ...
      , 'Position', position_ ...
    );
    prop_val = stim.(prop);
    original_class = class( prop_val );
    switch ( original_class )
      case { 'double', 'logical' }
        prop_val = num2str( prop_val );
      case 'char'
      otherwise
        error( 'Unsupported datatype ''%s''', original_class );
    end
    position_ = [ x_+w_, y_, w_, l_ ];
    uicontrol( panels.stimuli ...
      , 'Style', 'edit' ...
      , 'String', prop_val ...
      , 'UserData', struct( ...
            'prop', prop ...
          , 'class', original_class ...
          , 'stim_name', stim_name ...
          ) ...
      , 'Units', 'normalized' ...
      , 'Position', position_ ...
      , 'Callback', @handle_stimuli_textfield ...
    );
    y_ = y_ + l_;
  end
  function handle_stimuli_textfield(source, event)
    
    %   HANDLE_STIMULI_TEXTFIELD -- Special subroutine for handling changes
    %     to stimuli text changes.
    
    prop_name = source.UserData.prop;
    prop_val_ = source.String;
    orig_class = source.UserData.class;
    stim_name_ = source.UserData.stim_name;
    
    if ( isequal(orig_class, 'double') || isequal(orig_class, 'logical') )
      prop_val_ = strsplit( prop_val_, ' ' );
      prop_val_( strcmp(prop_val_, '') ) = [];
      prop_val_ = cellfun( @str2double, prop_val_ );
      if ( isequal(orig_class, 'logical') )
        prop_val_ = logical( prop_val_ );
      end
    end
    
    need_update = false;
    
    if ( isequal(prop_name, 'class') )
      original_val = config.STIMULI.setup.(stim_name_).(prop_name);
      if ( ~isequal(original_val, prop_val_) )
        need_update = true;
        switch ( prop_val_ )
          case 'Rectangle'
            try
              config.STIMULI.setup.(stim_name_) = ...
                rmfield( config.STIMULI.setup.(stim_name_), 'image_file' );
            catch err
              warning( err.message );
            end
          case 'Image'
            config.STIMULI.setup.(stim_name_).image_file = '';
          otherwise
            error( 'Unrecognized class value ''%s''', prop_val_ );
        end
      end
    end
    
    config.STIMULI.setup.(stim_name_).(prop_name) = prop_val_;
    hww_gng.config.save( config );
    
    if ( need_update )
      parent_ind = arrayfun( @(x) strcmp(x.Tag, 'stim_selector') ...
        , source.Parent.Children );
      parent = source.Parent.Children( parent_ind );
      handle_stimuli_popup( parent, [] );
    end
  end
end

function text_field_creator( parent, basefield, subfields, text_pos, field_pos )
  
  %   TEXT_FIELD_CREATOR -- Create a text-field set.
  %
  %     EX: //
  %
  %     F = figure();
  %     config = brains.config.load();
  %     basefield = 'IO';
  %     subfields = {}; % none
  %     text_pos  = struct( 'x', 0, 'y', 0, 'w', .5 );
  %     field_pos = struct( 'x', .5, 'y', 0, 'w', .5 );
  %
  %     text_field_creator( F, basefield, subfields, text_post, field_pos );
  %
  %     IN:
  %       - `parent` (graphics object) -- Handle to a panel object.
  %       - `basefield` (char) -- Field of `config` from which to draw.
  %       - `subfields` (cell array) -- Subfields of basefield.

  config_path = strjoin( [{'config'}, {basefield}, subfields], '.' );
  fs = get_gui_fields( eval(config_path) );

  tx = text_pos.x;
  tw = text_pos.w;

  fx = field_pos.x;
  fw = field_pos.w;

  y_ = 0;
  l_ = 1 / numel(fs);

  for ii = 1:numel( fs )
    field = fs{ii};
    position_ = [ tx, y_, tw, l_ ];
    uicontrol( parent ...
      , 'Style', 'text' ...
      , 'String', field ...
      , 'Units', 'normalized' ...
      , 'Position', position_ ...
    );    
    position_ = [ fx, y_, fw, l_ ];
    val = eval( sprintf('%s.(''%s'')', config_path, field) );
    is_num = isnumeric( val );
    if ( is_num ), val = num2str( val ); end
    uicontrol( parent ...
      , 'Style', 'edit' ...
      , 'String', val ...
      , 'UserData', struct( ...
            'config_field', basefield ...
          , 'subfields', { [subfields, {field}] } ...
          , 'is_numeric', is_num ...
          ) ...
      , 'Units', 'normalized' ...
      , 'Position', position_ ...
      , 'Callback', @handle_textfields ...
    );
    y_ = y_ + l_;
  end

end

function handle_reward_size_setup()
  
  persistent active_size;
  
  sizes = config.REWARDS.main;
  sizes = arrayfun( @num2str, sizes, 'un', false );
  
  if ( numel(sizes) == 0 )
    warning( 'No rewards have been specified!' );
    return;
  end
  
  reward_panel = figure();
  set( reward_panel, 'units', 'pixels' );
  set( reward_panel, 'position', [0, 0, 400, 100] );
  
  color_map = config.REWARDS.color_map;
  
  rwd_popup = uicontrol( reward_panel ...
    , 'Style',      'popup' ...
    , 'String',     sizes ...
    , 'Value',      1 ...
    , 'Units',      'normalized' ...
    , 'Tag',        'reward_selector' ...
    , 'Position',   [0, 0, 0.5, 1] ...
    , 'Callback',   @handle_reward_size_popup ...
  );

  txt_field = uicontrol( reward_panel ...
      , 'Style', 'edit' ...
      , 'String', '' ...
      , 'Units', 'normalized' ...
      , 'Position', [0.5, 0, 0.5, 1] ...
      , 'Callback', @handle_reward_size_selection ...
  );

  handle_reward_size_popup( rwd_popup );
  
  function handle_reward_size_selection(source, event)
    
    value = [];
    
    try
      eval( sprintf('value = [%s];', source.String) );
    catch err
      warning( err.message );
      return;
    end
    
    if ( isempty(value) || ~isnumeric(value) || numel(value) ~= 3 )
      warning( 'Specify color as 3 element numeric vector' );
      return;
    end
    
    if ( isempty(active_size) )
      warning( 'Activate a size before entering a value.' );
      return;
    end
    
    color_map(active_size) = value;
    
    hww_gng.config.save( config );
  end

  function handle_reward_size_popup(source, event)
    
    selection_str = source.String{source.Value};
    selection = str2double( selection_str );
    
    active_size = selection;
    
    if ( ~isKey(config.REWARDS.color_map, selection) )
      warning( 'Unrecognized reward size "%s"', selection_str );
    else
      value = color_map(selection);
      txt_field.String = num2str( value );
    end
  
  end
end

  function handle_reward_change(old, new, target)
    config.REWARDS = new;
    
    hww_gng.config.save( config );
  end

  function handle_structure_change(old, new, target)
    config.STRUCTURE = new;
    
    hww_gng.config.save( config );
  end

end

function fs = get_gui_fields( S )

%   GET_GUI_FIELDS -- Get the fields of S that should be fields in a GUI
%     panel.
%
%     If S does not have a 'gui_fields' field, fs is the fieldnames of S.
%     If S has a 'gui_fields' field whose value is a struct with an
%     'include' field, fs is S.gui_fields.include;
%     If S has a 'gui_fields' field whose value is a struct with an
%     'exclude' field, fs is the fields of S that are not present in
%     S.gui_fields.exclude (and not 'gui_fields')
%
%     IN:
%       - `S` (struct)
%     OUT:
%       - `fs` (cell array of strings)

fs = fieldnames( S );
if ( ~any(strcmp(fs, 'gui_fields')) ), return; end;
if ( ~isfield(S.gui_fields, 'include') )
  if ( ~isfield(S.gui_fields, 'exclude') )
    return;
  end
  excludes = [ S.gui_fields.exclude, {'gui_fields'} ];
  fs = exclude_values( fs, excludes );
else
  fs = S.gui_fields.include;
end

end

function arr1 = exclude_values( arr1, arr2 )

%   EXCLUDE_VALUES -- Exclude char values in arr1 that are present in arr2.

if ( ~iscell(arr2) ), arr2 = { arr2 }; end;
to_rm = false( size(arr1) );
for i = 1:numel( arr1 )
  to_rm(i) = any( strcmp(arr2, arr1{i}) );
end

arr1(to_rm) = [];

end