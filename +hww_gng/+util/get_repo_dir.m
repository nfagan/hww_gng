function repo_dir = get_repo_dir()

%   GET_REPO_DIR -- Get the repositories directory in which the hww_gng
%     package resides.
%
%     OUT:
%       - `repo_dir` (char)

if ( ispc() )
  slash = '\';
else slash = '/';
end

file_parts = strsplit( which('hww_gng.task.setup'), slash );
hww_ind = strcmp( file_parts, 'hww_gng' );
assert( any(hww_ind), 'Expected this function to reside in %s' ...
  , strjoin({'hww_gng', '+hww_gng', '+task'}, slash) );
repo_ind = find(hww_ind) - 1;
repo_dir = strjoin( file_parts(1:repo_ind), slash );

end