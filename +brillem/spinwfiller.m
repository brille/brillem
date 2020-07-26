function [eigval, eigvec] = spinwfiller(swobj, Qh, Qk, Ql, varargin)

d.names = {'usevectors'};
d.defaults = {false};
[kwds, extras] = brillem.readparam(d, varargin{:});
keys = fieldnames(extras);
vars = cell(numel(keys)*2);
for ik = 1:numel(keys)
    
    vars{2*(ik-1)+1} = keys{ik};
    vars{2*(ik-1)+2} = extras.(keys{ik});
end

hkl = [Qh(:) Qk(:) Ql(:)]';

if kwds.usevectors
    spec = swobj.spinwave(hkl, vars{:}, 'saveV', true, 'sortMode', false);
    [omega, V] = parse_twin(spec);
    if (size(omega, 1) / size(V, 1)) == 3 && (size(V, 3) / size(omega, 2)) == 3
        % Incommensurate
        kmIdx = repmat(sort(repmat([1 2 3],1,size(omega, 2))),1,1);
        eigvec = permute(cat(1, V(:,:,kmIdx==1), V(:,:,kmIdx==2), V(:,:,kmIdx==3)), [3 1 2]);
    else
        eigvec = permute(V, [3 1 2]);
    end
else
    spec = swobj.spinwave(hkl, vars{:}, 'sortMode', false, 'formfact', false);
    [omega, Sab] = parse_twin(spec, 'Sab');
    eigvec = permute(real(Sab), [4 3 1 2]);
end
eigval = permute(real(omega), [2 1]);

end

function [omega, V] = parse_twin(spec, use_Sab)
    if iscell(spec.omega)
        % Has twins
        omega = spec.omega{1};
        if nargin > 1 && use_Sab
            V = spec.Sab{1};
        else
            V = spec.V{1};
        end
    else
        omega = spec.omega;
        if nargin > 1 && all(logical(use_Sab))
            V = spec.Sab;
        else
            V = spec.V;
        end
    end
end
