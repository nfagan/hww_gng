function cleanup()

sca;
ListenChar( 0 );
hww_gng.util.close_ports();
try
  if ( Eyelink('CheckRecording') == 0 )
    Eyelink( 'StopRecording' );
  end
%   Eyelink( 'StopRecording' )
catch err
  fprintf( '\n The following error occurred when attempting to stop recording:' );
  fprintf( err.message );
end

end