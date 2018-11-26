classdef plex_comm < serial_comm.SerialManager
  
  properties
    n_plex_pins = 1;
  end
  
  methods
    function obj = plex_comm(port)
      
      %   PLEX_COMM -- Instantiate an interface to the Plexon sync
      %     arduino.
      %
      %     See also serial_comm.SerialManager
      %
      %     IN:
      %       - `port` (char)
      
      messages = struct();
      channels = {};
      
      obj@serial_comm.SerialManager( port, messages, channels );
      
      obj.comm.BaudRate = 9600;
      obj.comm.Terminator = 'LF';
    end
    
    function sync_pulse(obj, ind)
      
      %   SYNC_PULSE -- Send a pulse to Plexon.
      %
      %     obj.sync_pulse( 0 ) sends a sync pulse to Plexon associated
      %     with output 0 of the Arduino.
      %
      %     IN:
      %       - `ind` (double)
      
      if ( obj.bypass ), return; end
      fprintf( obj.comm, sprintf('%d', ind) );
    end
  end
end