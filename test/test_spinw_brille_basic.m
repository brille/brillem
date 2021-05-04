clear all; clear classes; close all;

% Some parameters
models = {'square', 'centredsquare', 'tricomm', 'incomm', 'squareincomm'};
nn = 4;
for im = 1:numel(models); model = models{im};
    nQ = 50; emx = 50; nE = 200;
    if strcmp(model, 'tricomm'); nQ=100; end
    
    lat = [4 4 8]; alf = [90 90 90]; spg = 'P 4';
    if strcmp(model, 'incomm') || strcmp(model, 'tricomm'); alf = [90 90 120]; spg = 'P 6'; end
    swo = spinw;
    swo.genlattice('lat_const', lat, 'angled', alf, 'spgr', spg);
    swo.addatom('label', 'MFe3', 'r', [0 0 0], 'S', 2.5);
    if strcmp(model, 'centredsquare') || strcmp(model, 'squareincomm');
        swo.addatom('label', 'MFe3', 'r', [0.5 0.5 0], 'S', 2.5);
    end
    swo.gencoupling('forcenosym', true, 'maxDistance', 8.5);
    swo.addmatrix('label', 'J1', 'value', 1, 'color', 'red');
    swo.addcoupling('mat', 'J1', 'bond', 1);
    swo.addmatrix('label', 'Jc', 'value', -0.1, 'color', 'green');
    tb = swo.table('bond', 1:100);
    c_bond = mode(tb.idx(tb.length==8));
    swo.addcoupling('mat', 'Jc', 'bond', c_bond);
    for ii = 2:min(nn, c_bond-1)
        swo.addmatrix('label', ['J' num2str(ii)], 'value', -1./double(ii), 'color', 'blue');
        swo.addcoupling('mat', ['J' num2str(ii)], 'bond', ii);
    end
    switch model
      case 'incomm'
        swo.genmagstr('mode', 'helical', 'k', [1/3 1/3 0], 'S', [1 0 0]', 'n', [0 0 1]);
        swo.addmatrix('label', 'D', 'value', diag([-0.1 -0.05 0.2]), 'color', 'blue'); swo.addaniso('D');
        pp = swo.optmagstr('func', @gm_planar, 'xmin', [0 0 0 0 0 0], 'xmax', [0 1/2 1/2 0 0 0], 'nRun', 10)
        swo = pp.obj
        frac = 1e-5;
      case 'tricomm'
        swo.genmagstr('mode', 'random', 'nExt', [3 3 1], 'k', [0 0 0]);
        swo.addmatrix('label', 'D', 'value', diag([0.1 -0.05 0.5]), 'color', 'blue'); swo.addaniso('D');
        pp = swo.optmagsteep('nRun', 2000);
        swo = pp.obj
        frac = 1e-5;
      case 'square'
        swo.genmagstr('mode', 'direct', 'nExt', [2 2 1], 'S', [0 0 1; 0 0 -1; 0 0 -1; 0 0 1]')
        swo.addmatrix('label', 'D', 'value', diag([0.3 0.5 -0.2]), 'color', 'blue'); swo.addaniso('D');
        pp = swo.optmagsteep('nRun', 500);
        swo = pp.obj
        frac = 1e-5;
      case 'centredsquare'
        swo.genmagstr('mode', 'direct', 'nExt', [1 1 1], 'S', [0 0 1; 0 0 -1]')
        swo.addmatrix('label', 'D', 'value', diag([0.3 0.5 -0.2]), 'color', 'blue'); swo.addaniso('D');
        frac = 1e-5;
      case 'squareincomm'
        swo.genmagstr('mode', 'fourier', 'k', [1/3 0 0], 'S', [1 0 0]', 'n', [0 0 1]);
        swo.addmatrix('label', 'D', 'value', diag([-5 0.2 0.5]), 'color', 'blue'); swo.addaniso('D');
        frac = 1e-4;
    end
    swpref.setpref('usemex',0);
    qln = {[0 0 0] [1 -1 1] [1 1 0] [1 0 0.5] [0 1 0] [0 0.5 0] [1 0 0] [0.5 0 1] [0 0 0] nQ};
    sm = false; ff = true;
    figure;
    spci = sw_neutron(swo.spinwave(qln, 'formfact', ff, 'use_brille', true, 'node_volume_fraction', frac*10, 'use_vectors', true, 'sortMode', sm, 'optmem', 2));
    %swo.brille.Qtrans  % brille property is private
    spcu = sw_neutron(swo.spinwave(qln, 'formfact', ff, 'sortMode', sm));
    subplot(211); sw_plotspec(sw_egrid(spcu, 'Evect', linspace(0,emx,nE))); legend off; title([model ' - SpinW'])
    subplot(212); sw_plotspec(sw_egrid(spci, 'Evect', linspace(0,emx,nE))); legend off; title([model ' - Interpolated Eigevectors'])
    set(gcf, 'PaperPosition', [0.25 0.25 7.75 11.2]);
    %print('-dpdf', ['brille_eig_' model '.pdf']);
    figure;
    spci = sw_neutron(swo.spinwave(qln, 'formfact', ff, 'use_brille', true, 'node_volume_fraction', frac*10, 'use_vectors', false, 'sortMode', sm, 'optmem', 2));
    %swo.brille.Qtrans  % brille property is private
    spcu = sw_neutron(swo.spinwave(qln, 'formfact', ff, 'sortMode', sm));
    subplot(211); sw_plotspec(sw_egrid(spcu, 'Evect', linspace(0,emx,nE))); legend off; title([model ' - SpinW'])
    subplot(212); sw_plotspec(sw_egrid(spci, 'Evect', linspace(0,emx,nE))); legend off; title([model ' - Interpolated Sab'])
    set(gcf, 'PaperPosition', [0.25 0.25 7.75 11.2]);
    %print('-dpdf', ['brille_sab_' model '.pdf']);
end
