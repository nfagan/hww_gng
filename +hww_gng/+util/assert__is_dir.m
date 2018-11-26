function assert__is_dir( p )

assert( isa(p, 'char'), 'Path must be a char; was a ''%s''.', class(p) );
assert( exist(p, 'dir') == 7, 'Directory ''%s'' does not exist.', p );

end