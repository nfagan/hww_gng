function check_latest_edf()

%   CHECK_LATEST_EDF -- Check whether the latest .edf file is valid.
%
%     ... check_latest_edf() attempts to load the .edf file as defined in
%     the config file. Loading the .edf file depends on the external
%     class @Edf2Mat; an error is thrown if this class is not found on
%     Matlab's search path.

conf = hww_gng.config.load();

edf_file = fullfile( conf.IO.data_folder, conf.IO.edf_file );

try
  edf = hww_gng.util.get_latest_edf();
  if ( isempty(edf) )
    fprintf( '\n File ''%s'' is invalid; see above.', edf_file );
  else
    fprintf( '\n File ''%s'' is OK.', edf_file );
  end
catch err
  fprintf( '\n %s', err.message );
  fprintf( '\n File ''%s'' is invalid; see above', edf_file );
end

end