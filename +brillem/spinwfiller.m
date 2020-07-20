function [eigval, eigvec] = spinwfiller(swobj, Qh, Qk, Ql, varargin)

hkl = [Qh(:) Qk(:) Ql(:)]';

spec = swobj.spinwave(hkl, varargin{:}, 'saveV', true, 'sortMode', false);
eigval = permute(real(spec.omega), [2 1]);
eigvec = permute(spec.V, [3 1 2]);
