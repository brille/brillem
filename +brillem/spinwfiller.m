function [eigval, eigvec] = spinwfiller(swobj, Qh, Qk, Ql, varargin)

d.names = {'usevectors'};
d.defaults = {false};
[kwds, extras] = brillem.readparam(d, varargin{:});
keys = fieldnames(extras);
for ik = 1:numel(keys)
    vars{2*(ik-1)+1} = keys{ik};
    vars{2*(ik-1)+2} = extras.(keys{ik});
end

hkl = [Qh(:) Qk(:) Ql(:)]';

if kwds.usevectors
    spec = swobj.spinwave(hkl, varargin{:}, 'saveV', true, 'sortMode', false);
    eigvec = permute(spec.V, [3 1 2]);
else
    spec = swobj.spinwave(hkl, varargin{:}, 'sortMode', false, 'formfact', false);
    eigvec = permute(real(spec.Sab), [4 3 1 2]);
end
eigval = permute(real(spec.omega), [2 1]);
