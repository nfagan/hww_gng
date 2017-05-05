function err = start()

try
  opts = hww_gng.setup();
catch err
  hww_gng.cleanup();
  hww_gng.util.print_error_stack( err );
  return;
end

try
  err = 0;
  hww_gng.task( opts );
  hww_gng.cleanup();
catch err
  hww_gng.cleanup();
  hww_gng.util.print_error_stack( err );
end

end