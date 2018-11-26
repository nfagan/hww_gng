function file = get_latest_edf()

conf = hww_gng.config.load();

data_p = fullfile( conf.IO.data_folder, conf.IO.edf_file );

file = [];

if ( exist(data_p, 'file') ~= 2 )
  fprintf( '\n The file ''%s'' does not exist ...', data_p );
  return;
end

assert( ~isempty(which('Edf2Mat')), ['No Edf2Mat converter could be found.\n' ...
  , 'Search your computer for @Edf2Mat'] );

try
  file = Edf2Mat( data_p );
catch err
  fprintf( '\n The following error occurred when attempting to load ''%s''.\n\n' ...
    , data_p );
  fprintf( '\n%s', err.message );
end

end