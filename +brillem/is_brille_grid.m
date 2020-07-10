function out = is_brille_grid(in)
  types = {'BZTrellisQ', 'BZMeshQ', 'BZNestQ'};
  exts = {'dd','dc','cd','cc'};
  
  out = any(cellfun(...
	  @(y)any(cellfun(...
	  	@(x)isa(in,x), strcat(y,exts))...
	  ), types));

end

