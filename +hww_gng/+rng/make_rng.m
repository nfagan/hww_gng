function make_rng(overwrite)

if ( nargin < 1 ), overwrite = false; end

s = rng();
fname = hww_gng.rng.get_rng_filename();

if ( exist(fname, 'file') == 2 && ~overwrite )
  warning( 'File "%s" already exists; set overwrite=true to overwrite.', fname );
  return
end

save( fname, 's' );

end