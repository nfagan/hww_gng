function update_images()

%   UPDATE_IMAGES -- Reload image matrices and filenames.
%
%     The config file will be modified.

conf = hww_gng.config.load();

stim_path = fullfile( conf.IO.repo_dir, 'hww_gng', 'stimuli' );

hww_gng.util.assert__is_dir( stim_path );

go_types = { 'go', 'nogo' };
soc_types = { 'social', 'nonsocial' };

images = struct();

for i = 1:numel(go_types)
  for j = 1:numel(soc_types)
    full_stim_path = fullfile( stim_path, go_types{i}, soc_types{j} );
    
    hww_gng.util.assert__is_dir( full_stim_path );
    
    files = dir( full_stim_path );
    
    assert( ~isempty(files), 'No image files found in ''%s''.', full_stim_path );
    files = files( arrayfun(@(x) ~strcmp(x.name, '.') && ~strcmp(x.name, '..'), files) );
    files = { files(:).name };
    
    matrices = cell( 1, numel(files) );
    
    for k = 1:numel(files)
      matrices{k} = imread( fullfile(full_stim_path, files{k}) );
    end
    
    images.(go_types{i}).(soc_types{j}).matrices = matrices;
    images.(go_types{i}).(soc_types{j}).filenames = files;
  end
end

conf.STIMULI.setup.images = images;

hww_gng.config.save( conf );

end