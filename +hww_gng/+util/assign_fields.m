function conf = assign_fields(conf, conf2)

fs = fieldnames( conf );

for i = 1:numel(fs)
  if ( ~isfield(conf2, fs{i}) )
    continue;
  end
  
  current = conf.(fs{i});
  
  if ( isstruct(current) )
    out = hww_gng.util.assign_fields( conf.(fs{i}), conf2.(fs{i}) );
    
  end
  
  conf.(fs{i}) = conf2.(fs{i});  
end

end