function err = start()

%   START -- Attempt to setup and run the task.
%
%     OUT:
%       - `err` (double, MException) -- 0 if successful; otherwise, the
%         raised MException, if setup / run fails.

try
  opts = hww_gng.task.setup();
catch err
  hww_gng.task.cleanup();
  hww_gng.util.print_error_stack( err );
  return;
end

try
  err = 0;
  hww_gng.task.run( opts );
  hww_gng.task.cleanup();
catch err
  hww_gng.task.cleanup();
  hww_gng.util.print_error_stack( err );
end

end