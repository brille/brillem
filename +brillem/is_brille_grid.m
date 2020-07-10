function dim = is_brille_grid(in)
  % Returns the dimensionality of a valid py.brille generalised grid or 0
  types3d = {'BZTrellisQ', 'BZMeshQ', 'BZNestQ'};
  exts = {'dd','dc','cd','cc'};

  dim = 3*any(cellfun(...
	  @(y)any(cellfun(...
	  	@(x)isa(in,x), strcat(y,exts))...
	  ), types3d));

end
