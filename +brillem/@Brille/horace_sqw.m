function sqw = horace_sqw(obj, qh, qk, ql, en, pars, varargin)
  % Input:
  % ------
  %   qh,qk,ql,en Arrays containing points at which to evaluate sqw from the
  %               broadened dispersion
  %
  %   pars        Arguments needed by the function.
  %               - pars = [model_pars scale_factor resolution_pars]
  %               - Should be a vector of parameters
  %               - The first N parameters relate to the spin wave dispersion
  %                 and correspond to spinW matrices in the order defined by
  %                 the 'mat' option [N=numel(mat)]
  %               - The next M parameters relate to the convolution parameters
  %                 corresponding to the convolution function defined by the
  %                 'resfun' option (either one or two parameters depending
  %                 on function type.
  %               - The last parameter is a scale factor for the intensity
  %                 If this is omitted, a scale factor of 1 is used;
  %
  %   kwpars      - A series of 'keywords' and parameters. Specific to this
  %                 function is:
  %
  %               - 'resfun' - determines the convolution / resolution
  %                    function to get S(q,w). It can be either a string:
  %                      'gauss' - gaussian with single fixed (fittable) FWHM
  %                      'lor' - lorentzian with single fixed (fittable) FWHM
  %                      'voigt' - pseudo-voigt with single fixed (fittable) FWHM
  %                      @fun - a function handle satisfying the requirements of
  %                             the 'fwhm' parameter of disp2sqw.
  %                    NB. For 'gauss' and 'lor' only one fwhm parameter may be
  %                    specified. For 'voigt', fwhm = [width lorz_frac]
  %                    contains two parameters - the fwhm and lorentzian fraction
  %                    [default: 'gauss']
  %               - 'partrans' - a function to transform the fit parameters
  %                    This transformation will be applied before each iteration
  %                    and the transformed input parameter vector passed to
  %                    spinW and the convolution function.
  %                    [default: @(y)y  % identity operation]
  %               - 'coordtrans' - a matrix to transform the input coordinates
  %                    (qh,qk,ql,en) before being sent to SpinW.
  %                    [default: eye(4) % identity]
  %
  %               In addition, the following parameters are used by this function
  %                    and will also be passed on to spinw.matparser which will
  %                    do the actual modification of spinW model parameters:
  %
  %               - 'mat' - A cell array of labels of spinW named 'matrix' or
  %                    matrix elements. E.g. {'J1', 'J2', 'D(3,3)'}. These will
  %                    be the model parameters to be varied in a fit, their
  %                    order in this cell array will be the same as in the
  %                    fit parameters vector.
  %                    [default: [] % empty matrix - no model parameters]
  %
  %                 All other parameters will be passed to spinW. See the help
  %                    for spinw/spinwave, spinw/matparser and spinw/sw_neutron
  %                    for more information.
  %
  %   swobj       The spinwave object which defines the magnetic system to be
  %               calculated.
  %
  % Output:
  % -------
  %   weight      Array with spectral weight at the q,e points
  %               If q and en given:  weight is an nq x ne array, where nq
  %                                   is the number of q points, and ne the
  %                                   number of energy points
  %               If qw given together: weight has the same size and dimensions
  %                                     as q{1} i.e. qh
  %

  % handle Q/parameter transformation(s)
  inpForm.names    = {'partrans' 'coordtrans' 'mat'};
  inpForm.defaults = {@(y)y      eye(4)       []};
  inpForm.sizes    = {[1 1]      [4 4]        [1 -1]};
  inpForm.soft     = {false      false        false};
  [kwds, dict] = brillem.readparam(inpForm, varargin{:});

  % dict is a struct with any extra name-value pairs, we want to turn this
  % back into a cellarray of {'name', value} pairs
  names = fieldnames(dict);
  values = struct2cell(dict);
  passon = reshape(cat(2, names, values)',1,2*numel(names));

  % Sets the number of spinW model parameters. All others are interpreter pars.
  n_horace_pars = numel(kwds.mat);
  if isempty(n_horace_pars)
      n_horace_pars = 0;
  end
  fillerinpt = [{pars(1:n_horace_pars)} passon];
  interpinpt = [{'pars'} {pars((1+n_horace_pars):end)} passon];

  % The object holds one py.brille generalised grids
  % plus a hash of the last parameters used, and functions to fill the
  % grid and convert interpolated values from the function outputs to
  % what horace expects [a single intensity per (qh(i),qk(i),ql(i),en(i))
  % tuple].
  % This function needs to compare the inputs in varargin to the
  % parameter hash, fill the grid(s) if the hash is different,
  % interpolate the gridded Rank-N tensors ( 0<=N ) for the input Q [or
  % (Q,E)] points, and then call the interpreter function(s) to convert
  % the interpolated values into intensities for use by Horace/Tobyfit.

  % First, refill the grid(s) if the hashes differ
  obj.fill(fillerinpt{:});

  % We have one or more filled BZGrids. We want to interpolate their
  % stored values at the passed (qh,qk,ql) or (qh,qk,ql,en) points
  assert( numel(qh)==numel(qk) && numel(qk)==numel(en)...
       && numel(qh)==numel(en),    'Expected matching numel arrays');
  assert( all(size(qh)==size(qk)) && all(size(ql)==size(en)) ...
       && all(size(qh)==size(en)), 'Expected matching shaped arrays');
  reshaped = false;
  inshaped = size(qh);
  if numel(qh) ~= size(qh,1)
      reshaped = true;
      qh = qh(:);
      qk = qk(:);
      ql = ql(:);
      en = en(:);
  end
  % Transforms input coordinates if needed
  if sum(sum(abs(kwds.coordtrans - eye(4)))) > 0
      qc = [qh qk ql en];
      qh = sum(bsxfun(@times, kwds.coordtrans(1,:), qc),2);
      qk = sum(bsxfun(@times, kwds.coordtrans(2,:), qc),2);
      ql = sum(bsxfun(@times, kwds.coordtrans(3,:), qc),2);
      en = sum(bsxfun(@times, kwds.coordtrans(4,:), qc),2);
      clear qc;
  end

  % chunk the q points:
  no_pts = numel(qh);
  tmp_array_fudge = 15;
  pt_per_chunk = double(brillem.chunk_size(obj.pygrid, tmp_array_fudge));
  no_chunks = ceil(no_pts/pt_per_chunk);
  chunk_list = 0:pt_per_chunk:no_pts;
  if no_pts < pt_per_chunk * no_chunks
    chunk_list = [chunk_list no_pts];
  end
  sqw_chunk = cell(1, no_chunks);
  % call the inner function on the chunks
  wd = 1;
  if no_chunks > 1
    fprintf('Evaluate S(Q,W) split into %d chunks:\n',no_chunks);
    nd = floor(log10(no_chunks));
    fmt = sprintf('%%%dd',nd);
    wd = 10*floor(80/(9+nd));
  end
  for i=1:no_chunks
    if no_chunks > 1
      if mod(i,10)==0
        fprintf(fmt,i/10);
        if mod(i,wd)==0
            fprintf('\n');
        end
      else
        fprintf('.');
      end
    end
    ch = chunk_list(i)+1 : chunk_list(i+1);
    sqw_chunk{i} = horace_sqw_inner(obj, qh(ch), qk(ch), ql(ch), en(ch), dict);
  end
  if mod(no_chunks, wd) > 0
    fprintf('\n');
  end
  % combine the chunk results
  sqw = cat(1, sqw_chunk{:});

  % reshape the output to match the input
  if reshaped
      sqw = reshape(sqw,inshaped);
  end
end


function sqw = horace_sqw_inner(obj,qh,qk,ql,en,interpinpt) % split varagin into fill varargin, and interpreter varargin?

if ~isempty(obj.sab_calc)
    if ~isempty(obj.twin) && (numel(obj.twin.vol) > 1 || sum(sum(abs(obj.twin.rotc(:,:,1) - eye(3)))) > 0)
        [qht, qkt, qlt, ent] = obj.twinq(qh, qk, ql, en);
        istwinned = true;
    else
        qht = {qh}; qkt = {qk}; qlt = {ql}; ent = {en};
        istwinned = false;
    end
    for ic = 1:numel(qht)
        intres = {};
        for i=1:obj.nInt
            newintres = cell(1, 2);
            [newintres{:}] = obj.sab_calc{i}(qht{ic},qkt{ic},qlt{ic},ent{ic},intres{:},interpinpt{:});
            intres = newintres;
        end
        omega{ic} = intres{1};
        Sab{ic} = intres{2};
    end
    if istwinned
        % Rotate the calculated correlation function into the twin coordinate system using rotC
        nTwin = numel(obj.twin.vol);
        SabAll = cell(1,nTwin);
        for ii = 1:nTwin
            Sab{ii} = permute(Sab{ii}, [3 4 2 1]);
            sSabT  = size(Sab{ii});                % size of the correlation function matrix
            SabT   = reshape(Sab{ii},3,3,[]);      % convert the matrix into cell of 3x3 matrices
            rotC   = obj.twin.rotc(:,:,ii);        % select the rotation matrix of twin ii
            SabRot = arrayfun(@(idx)(rotC*SabT(:,:,idx)*(rotC')),1:size(SabT,3),'UniformOutput',false);
            SabRot = cat(3,SabRot{:});             % rotate correlation function using arrayfun
            SabAll{ii} = reshape(SabRot,sSabT);    % resize back the correlation matrix
            SabAll{ii} = permute(SabAll{ii}, [4 3 1 2]);
        end
        Sab = SabAll;
    end
    intres = {real(cell2mat(omega)) cell2mat(Sab)};
else
    intres = obj.interpolate(qh,qk,ql,en);
end

% and then use the interpreter function(s) to convert this to S(Q,E)
for i=1:obj.nInt
    newintres = cell(1,obj.nRet(i));
    [newintres{:}] = obj.interpreter{i}(qh,qk,ql,en,intres{:},interpinpt{:});
    intres = newintres;
end
% If no one has changed the interpreter cells then intres is cell(1,1).
% Check to be sure
assert( numel(intres) == 1 );
sqw = intres{1};

end
