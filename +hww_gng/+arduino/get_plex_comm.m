function obj = get_plex_comm(conf)

%   GET_PLEX_COMM -- Get an instantiated interface to the Plex sync
%     arduino.
%
%     See also hww_gng.arduino.plex_comm

if ( nargin < 1 || isempty(conf) )
  conf = hww_gng.config.load();
end

obj = hww_gng.arduino.plex_comm( conf.SERIAL.plex_port );

end