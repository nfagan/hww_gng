function p = get_project_folder()

fp = @fileparts;

p = fp( fp(fp(which('hww_gng.util.get_project_folder'))) );

end