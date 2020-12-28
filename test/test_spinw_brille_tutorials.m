% Runs through SpinW models in the published tutorials and compares running with and without Brille
% For more accurate results change the frac value here to a smaller number (e.g. 1e-5)
% To print out pdfs change the flag
print_flag = false;  % false = don't produce pdf
frac = 1e-4;

tutorials = arrayfun(@(x) fullfile(x.folder, x.name), dir(fullfile(sw_rootdir, 'tutorials', 'publish', 'tutorial*.m')), 'UniformOutput', false);
fails = {};
errs = {};

for iii = 1:numel(tutorials)
    currvals = arrayfun(@(s) s.name, whos, 'UniformOutput', false);
    run(tutorials{iii}); close all;
    newvals = arrayfun(@(s) is_new_var(s, currvals), whos, 'UniformOutput', false);
    newvals(cellfun(@(c) isempty(c), newvals)) = [];
    for jj = 1:numel(newvals)
        is_spinw(jj) = isa(eval(newvals{jj}), 'spinw');
    end
    if any(is_spinw)
        swo_names = newvals(is_spinw);
        [~, modname] = fileparts(tutorials{iii});
        for jj = 1:numel(swo_names)
            swo = eval(swo_names{jj});
            mname = [modname '-' swo_names{jj}];
            try
                run_brille(swo, mname, frac, print_flag);
            catch err
                fails = [fails{:} tutorials(iii)];
                errs = {errs{:} {err tutorials(iii)}};
            end
        end
    end
    clearvars('-except', 'iii', 'tutorials', 'fails', 'errs');
end

function out = is_new_var(val, oldvals)
    if any(cellfun(@(c) strcmp(c, val.name), oldvals))
        out = [];
    else
        out = val.name;
    end
end

function hf = run_brille(swo, model, frac, print_flag)
    if nargin < 2
        model = 'Model';
    end
    if swo.symbolic; swo.symbolic(false); end
    nQ = 200; emx = 50; nE = 100;
    qln = {[0 0 0] [1 -1 1] [1 1 0] [1 0 0.5] [0 1 0] [0 0.5 0] [1 0 0] [0.5 0 1] [0 0 0] nQ};
    sm = false; ff = true;

    hf = figure;
    hermit = true;
    try
        swo.spinwave(qln, 'formfact', ff, 'use_brille', true, 'node_volume_fraction', frac*100, 'use_vectors', true, 'sortMode', sm, 'optmem', 2);
    catch err
        if strcmp(err.identifier, 'spinw:spinwave:NonPosDefHamiltonian')
            hermit = false;
        end
    end
    spci = sw_neutron(swo.spinwave(qln, 'formfact', ff, 'use_brille', true, 'node_volume_fraction', frac, 'use_vectors', true, 'sortMode', sm, 'optmem', 2, 'hermit', hermit));
    swo.brille.Qtrans
    hermit
    spcu = sw_neutron(swo.spinwave(qln, 'formfact', ff, 'sortMode', sm, 'hermit', hermit));
    spcj = sw_neutron(swo.spinwave(qln, 'formfact', ff, 'use_brille', true, 'node_volume_fraction', frac, 'use_vectors', false, 'sortMode', sm, 'optmem', 2, 'hermit', hermit));
    if iscell(spcu.omega)
        emx = max(cellfun(@(c) max(c(:)), spcu.omega));
    else
        emx = max(spcu.omega(:));
    end
    spcu = sw_instrument(sw_egrid(spcu, 'Evect', linspace(0,emx,nE)), 'dE', emx/10);
    spci = sw_instrument(sw_egrid(spci, 'Evect', linspace(0,emx,nE)), 'dE', emx/10);
    spcj = sw_instrument(sw_egrid(spcj, 'Evect', linspace(0,emx,nE)), 'dE', emx/10);
    intv = abs(spcu.swConv); imx = mean(intv((intv>min([max(intv(:))/10 0.1])) & ~isnan(intv))) * 2;
    subplot(311); sw_plotspec(spcu); caxis([0 imx]); set_mksize(gca, 2); legend off; title([model ' - SpinW'])
    subplot(312); sw_plotspec(spci); caxis([0 imx]); set_mksize(gca, 2); legend off; title([model ' - Interpolated Eigevectors'])
    subplot(313); sw_plotspec(spcj); caxis([0 imx]); set_mksize(gca, 2); legend off; title([model ' - Interpolated Sab'])
    if hermit == false
        ann = annotation(gcf, 'textbox', [0.8 0.9 0.1 0.1], 'String', 'nonhermit', 'FitBoxToText', 'on', 'LineStyle', 'none');
    end
    set(gcf, 'PaperPosition', [0.25 0.25 7.75 11.2]);
    if nargin > 3 && print_flag
        print('-dpdf', ['brille_test_' model '.pdf']);
    end
end

function set_mksize(ax, sz)
    chld = get(ax, 'Children');
    for ii = 1:numel(chld);
        set(chld, 'MarkerSize', sz);
    end
end
