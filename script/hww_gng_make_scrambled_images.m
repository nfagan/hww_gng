function hww_gng_make_scrambled_images(conf, overwrite)

if ( nargin < 1 || isempty(conf) )
  conf = hww_gng.config.load();
end

if ( nargin < 2 ), overwrite = false; end

orig_rng_state = rng();

try
  rng( hww_gng.rng.get_rng_state() );

  stim_p = conf.IO.stim_path;
  save_p = fullfile( fileparts(stim_p), 'scrambled' );

  im_size = [300, 300];
  img_exts = { '.jpeg', '.jpg', '.JPG', '.png' };

  is_recursive = true;
  img_files = shared_utils.io.find( stim_p, img_exts, is_recursive );


  for i = 1:numel(img_files)
    shared_utils.general.progress( i, numel(img_files) );
    
    img_file = img_files{i};

    assert( strfind(img_file, stim_p) == 1, 'Improperly formatted file str.' );

    remaining_p = img_file(numel(stim_p)+1:end);
    [remaining_p, name] = fileparts( remaining_p );
    
    full_save_p = fullfile( save_p, remaining_p );
    out_img_file = fullfile( full_save_p, sprintf('%s.png', name) );  
    
    if ( exist(out_img_file, 'file') == 2 && ~overwrite )
      fprintf( '\n Skipping "%s" because it already exists.', out_img_file );
      continue;
    end

    im = imresize( imread(img_file), im_size );
    out = hww_gng.util.imscramble( im );
    
    shared_utils.io.require_dir( full_save_p );
    imwrite( out, out_img_file, 'png' );
  end
  
catch err
  warning( err.message );
end

rng( orig_rng_state );

end