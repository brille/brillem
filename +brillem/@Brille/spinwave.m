function spectra = spinwave(obj, hkl, varargin)
% calculates a SpinW-style spectra object using BZ interpolation
%
% ### Syntax
%
% `spectra = spinwave(obj,Q)`
%
% `spectra = spinwave(___,Name,Value)`
%
% ### Arguments
%
% `Q` - a $[3\times n_{Q}]$ matrix of q-points or a cell array of points
%       defining lines in Q-space (in SpinW notation).
%

if iscell(hkl) && length(hkl)>1
    hkl = qscanlines(hkl);
elseif iscell(hkl)
    hkl = hkl{1};
end
if size(hkl,1) > 3 || size(hkl,3)>1
    error('sw_qscan:WrongInput','The dimensions of the q-vector list are wrong!')
end

bv = (inv(brillem.p2m(obj.pygrid.BrillouinZone.lattice.lattice_matrix)) * 2 * pi) / obj.Qtrans(1:3,1:3);
hklA = 2*pi*(hkl'/bv)';
if ~isempty(obj.twin) && (numel(obj.twin.vol) > 1 || sum(sum(abs(obj.twin.rotc(:,:,1) - eye(3)))) > 0)
    hkl = obj.twinq(hkl);
    istwinned = true;
else
    hkl = {hkl};
    istwinned = false;
end

for ic = 1:numel(hkl)
    qh = hkl{ic}(1,:)'; qk = hkl{ic}(2,:)'; ql = hkl{ic}(3,:)'; en = ql*0;
    intres = {};
    for i=1:numel(obj.sab_calc)
        newintres = cell(1, 2); % Assume first return value is omega, and second is Sab
        [newintres{:}] = obj.sab_calc{i}(qh,qk,ql,en,intres{:},varargin{:});
        intres = newintres;
    end
    omega{ic} = permute(intres{1}, [2 1]); % Convert to SpinW convention
    Sab{ic} = permute(intres{2}, [3 4 2 1]);
end

if istwinned
    % Rotate the calculated correlation function into the twin coordinate system using rotC
    nTwin = numel(obj.twin.vol);
    SabAll = cell(1,nTwin);
    for ii = 1:nTwin
        sSabT  = size(Sab{ii});                % size of the correlation function matrix
        SabT   = reshape(Sab{ii},3,3,[]);      % convert the matrix into cell of 3x3 matrices
        rotC   = obj.twin.rotc(:,:,ii);        % select the rotation matrix of twin ii
        SabRot = arrayfun(@(idx)(rotC*SabT(:,:,idx)*(rotC')),1:size(SabT,3),'UniformOutput',false);
        SabRot = cat(3,SabRot{:});             % rotate correlation function using arrayfun
        SabAll{ii} = reshape(SabRot,sSabT);    % resize back the correlation matrix
    end
    Sab = SabAll;
else
    omega = omega{1};
    Sab = Sab{1};
end
    
spectra.title = 'Interpolated Spectra';
spectra.omega    = omega;
spectra.Sab      = Sab;
spectra.hkl      = hkl{1};
spectra.hklA     = hklA;
spectra.norm     = false;
spectra.nformula = 1;
if ~isempty(obj.baseobj)
    spectra.obj = obj.baseobj;
else
    spectra.obj = obj;
end

end


function qOut = qscanlines(qLim)
if numel(qLim{end}) == 1
    nQ = qLim{end};
    qLim = qLim(1:end-1);
else
    nQ = 100;
    end
    qOut = zeros(length(qLim{1}),0);
    for ii = 2:length(qLim)
        q1 = reshape(qLim{ii-1},[],1);
        q2 = reshape(qLim{ii},  [],1);
        if nQ > 1
            qOut = [qOut bsxfun(@plus,bsxfun(@times,q2-q1,linspace(0,1,nQ)),q1)]; %#ok<AGROW>
        else
            qOut = (q2+q1)/2;
        end
        if ii<length(qLim)
            qOut = qOut(:,1:end-1);
        end
    end
end
