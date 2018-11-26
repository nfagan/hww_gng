function v = get_blocked_condition_indices(n_blocks, block_size, n_conditions)

%   GET_BLOCKED_CONDITION_INDICES -- Get a permuted index vector
%     representing a condition sequence, in which the frequencies of
%     conditions are matched within a given block size, and across blocks.
%
%     v = ... get_blocked_condition_indices( BLOCKS, BLOCK_SIZE, CONDITIONS );
%     returns a vector `v` of length `BLOCKS * BLOCK_SIZE`, containing
%     permuted sequences of `1:CONDITIONS`. 
%
%     A given block will contain exactly `BLOCK_SIZE / CONDITIONS` 
%     repetitions of each condition index. 
%
%     Blocks are represented linearly in `v`, such that block 1 corresponds
%     to `v(1:BLOCK_SIZE)`, block 2 corresponds to `v(BLOCK_SIZE+1:BLOCK_SIZE*2)`, ...
%
%     `BLOCKS`, `BLOCK_SIZE` and `CONDITIONS` must be integer-valued double
%     scalars; `CONDITIONS` must be an integer factor of `BLOCK_SIZE`.
%
%     EX //
%
%     % get a condition index vector containing 3 blocks of 6 elements
%     % each, and for which each block contains 2 conditions:
%     v = shared_utils.general.get_blocked_condition_indices(3, 6, 2);
%
%     IN:
%       - `BLOCKS` (double) |SCALAR|
%       - `BLOCK_SIZE` (double) |SCALAR|
%       - `CONDITIONS` (double) |SCALAR|
%     OUT:
%       - `v` (double)

classes = { 'double', 'single' };
attrs = { 'scalar', 'positive', 'real', 'integer' };

try
  validateattributes( n_blocks, classes, attrs, mfilename, 'n_blocks' );
  validateattributes( block_size, classes, attrs, mfilename, 'block_size' );
  validateattributes( n_conditions, classes, attrs, mfilename, 'n_conditions' );

  assert( block_size >= n_conditions && mod(block_size, n_conditions) == 0 ...
    , 'Block size must be an integer multiple of the number of conditions.' );
catch err
  throw( err );
end

N = n_blocks * block_size;

n_perms = block_size / n_conditions;
assign_vec = 1:n_perms;

condition_vec = nan( block_size, 1 );

for i = 1:n_conditions
  assign_ind = assign_vec + (i-1) * n_perms;
  condition_vec(assign_ind) = i;
end

base_ind = 1:block_size;

v = nan( N, 1 );
stp = 0;

for i = 1:n_blocks  
  use_ind = randperm( block_size );
  assign_ind = base_ind + stp;
  
  v(assign_ind) = condition_vec(use_ind);
  
  stp = stp + block_size;  
end

end