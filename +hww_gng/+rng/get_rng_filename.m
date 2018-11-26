function f = get_rng_filename()

rng_p = which( 'hww_gng.rng.get_rng_filename' );
f = fullfile( fileparts(rng_p), 'rng.mat' );

end