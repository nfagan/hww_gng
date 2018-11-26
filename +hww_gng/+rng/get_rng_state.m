function s = get_rng_state()

fname = hww_gng.rng.get_rng_filename();

if ( exist(fname, 'file') ~= 2 )
  hww_gng.rng.make_rng();
end

s = shared_utils.io.fload( fname );

end