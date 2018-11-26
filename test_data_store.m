repos = { 'eyelink', 'global', 'shared_utils' };

for i = 1:numel(repos)
  addpath( genpath(fullfile(pathfor('repositories'), repos{i})) );
end

%%

mat_p = '/Users/Nick/Downloads/0214.mat';
edf_p = '/Users/Nick/Downloads/0214.edf';

edf = Edf2Mat( edf_p );
mat = shared_utils.io.fload( mat_p );

%%

target_onsets = arrayfun( @(x) x.events.go_target_onset, mat.DATA );
target_acqs = arrayfun( @(x) x.events.go_target_acquired, mat.DATA );
trial_type = arrayfun( @(x) x.trial_type, mat.DATA, 'un', false );
trial_outcome = arrayfun( @(x) x.trial_type, mat.DATA, 'un', false );
target_placement = arrayfun( @(x) x.target_placement, mat.DATA, 'un', false );

is_error = false( size(target_placement) );

for i = 1:numel(is_error)
  dat = mat.DATA(i);
  is_error(i) = dat.error__broke_cue_fixation ...
    || dat.error__no_fixation || ...
    dat.error__wrong_go_nogo;
end

is_go = strcmp( trial_type, 'go' );
is_nogo = strcmp( trial_type', 'nogo' );

assert( all(is_go(:) == ~is_nogo(:)) );

is_right = strcmp( target_placement, 'center-right' );
is_left = strcmp( target_placement, 'center-left' );

assert( all(is_right == ~is_left) );

rts = target_acqs - target_onsets;

rt_right = rts( ~is_error & is_go & is_right );
rt_left = rts( ~is_error & is_go & is_left );

nanidx = isnan(rts) & ~is_error & is_go;
nanindices = find( nanidx );

assert( isempty(nanindices), 'Some non-error trials had a NaN reaction time' );

rt_right = rt_right( ~isnan(rt_right) );
rt_left = rt_left( ~isnan(rt_left) );

[H, P, CI] = ttest2( rt_right, rt_left );