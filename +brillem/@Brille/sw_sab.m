function Sab = sw_sab(obj, qh, qk, ql, V0, varargin)
% calculates spin correlation tensor Sab using the interpolated eigenvectors of a linear spin wave theory model
% Note that this function only works if the Brille object was initialised using a SpinW object.
%
% ### Syntax
%
% `Sab = sw_sab(brillobj, qh, qk, ql, V)`
%
% `Sab = spinwave(___,Name,Value)`
%
% ### Description
%
% qh, qk, ql  - input hkl vectors (needed for form factor calculation)
% V           - input interpolated eigenvectors
% Sab         - output S^{alpha,beta} tensor.
%
% Important options:
%
% formfact    - default: false - whether to calculate the form factor or not.
% gtensor     - default: false - whether to include (anisotropic) g-tensor in the Sab calculation
%
% Options which should be left to defaults:
%
% optmem      - default: 0 - use 0 for automatic memory chunking, >0 number of hkl chunks to use.
% formfactfun - default: @sw_mff - the function used to calculate the formfactor.
% tol         - default: 1e-4 - tolerance to determine if structure is incommensurate
% cmplxBase   - default: false - whether the local coordinate system is defined by a complex magnetic moment

if isempty(obj.baseobj) || ~strcmp(class(obj.baseobj), 'spinw')
    error(['This function only works if the Brille model is derived from a SpinW model.' ...
          'Please construct the Brille object using a SpinW object.'])
end
swobj = obj.baseobj;
hkl = cat(2, qh, qk, ql)';

d.names = {'optmem' 'tol'  'formfact' 'formfactfun' 'gtensor' 'cmplxBase'};
d.defaults = {0     1e-4   false      @sw_mff       false     false      };
param = brillem.readparam(d, varargin{:});

% generate magnetic structure in the rotating noation
magStr = swobj.magstr;

% size of the extended magnetic unit cell
nExt    = magStr.N_ext;
% magnetic ordering wavevector in the extended magnetic unit cell
km = magStr.k.*nExt;

% whether the structure is incommensurate
incomm = any(abs(km-round(km)) > param.tol);

% Transform the momentum values to the new lattice coordinate system
hkl = swobj.unit.qmat*hkl;

% Check for 2*km
tol = param.tol*2;
helical =  sum(abs(mod(abs(2*km)+tol,1)-tol).^2) > tol;

% number of Q points
nHkl0 = size(hkl,2);
nHkl = nHkl0;
hkl0 = hkl;
if incomm
    % TODO
    if ~helical
        warning('spinw:spinwave:Twokm',['The two times the magnetic ordering '...
            'wavevector 2*km = G, reciproc lattice vector, use magnetic supercell to calculate spectrum!']);
    end
    hkl = [bsxfun(@minus,hkl,km') hkl bsxfun(@plus,hkl,km')];
    nHkl  = nHkl*3;
    nHkl0 = nHkl0*3;
end

% Create the interaction matrix and atomic positions in the extended
% magnetic unit cell.
[~, SI, RR] = swobj.intmatrix('fitmode',true,'conjugate',true);

% q values without the +/-k_m value
hklExt0 = bsxfun(@times,hkl0,nExt')*2*pi;

% Calculates parameters eta and zed.
if isempty(magStr.S)
    error('spinw:spinwave:NoMagneticStr','No magnetic structure defined in swobj!');
end

M0 = magStr.S;
S0 = sqrt(sum(M0.^2,1));
% normal to rotation of the magnetic moments
n  = magStr.n;
nMagExt = size(M0,2);

% Local (e1,e2,e3) coordinate system fixed to the moments,
% e3||Si,ata
% e2 = Si x [1,0,0], if Si || [1,0,0] --> e2 = [0,0,1]
% e1 = e2 x e3
% Local (e1,e2,e3) coordinate system fixed to the moments.
% TODO add the possibility that the coordinate system is fixed by the
% comples magnetisation vectors: e1 = imag(M), e3 = real(M), e2 =
% cross(e3,e1)
if ~param.cmplxBase
    % e3 || Si
    e3 = bsxfun(@rdivide,M0,S0);
    % e2 = Si x [1,0,0], if Si || [1,0,0] --> e2 = [0,0,1]
    e2  = [zeros(1,nMagExt); e3(3,:); -e3(2,:)];
    e2(3,~any(abs(e2)>1e-10)) = 1;
    e2  = bsxfun(@rdivide,e2,sqrt(sum(e2.^2,1)));
    % e1 = e2 x e3
    e1  = cross(e2,e3);
else
    F0  = swobj.mag_str.F;
    RF0 = sqrt(sum(real(F0).^2,1));
    IF0 = sqrt(sum(imag(F0).^2,1));
    % e3 = real(M)
    e3  = real(F0)./repmat(RF0,[3 1]);
    % e1 = imag(M) perpendicular to e3
    e1  = imag(F0)./repmat(IF0,[3 1]);
    e1  = e1-bsxfun(@times,sum(e1.*e3,1),e3);
    e1  = e1./repmat(sqrt(sum(e1.^2,1)),[3 1]);
    % e2 = cross(e3,e1)
    e2  = cross(e3,e1);
end
% assign complex vectors that define the rotating coordinate system on
% every magnetic atom
zed = e1 + 1i*e2;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEMORY MANAGEMENT LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if param.optmem == 0
    freeMem = sw_freemem;
    if freeMem > 0
        nSlice = ceil(nMagExt^2*nHkl*6912/freeMem*2);
    else
        nSlice = 1;
    end
else
    nSlice = param.optmem;
end

if param.gtensor
    
    gtensor = SI.g;
    
    if incomm
        % keep the rotation invariant part of g-tensor
        nx  = [0 -n(3) n(2);n(3) 0 -n(1);-n(2) n(1) 0];
        nxn = n'*n;
        m1  = eye(3);
        gtensor = 1/2*gtensor - 1/2*mmat(mmat(nx,gtensor),nx) + 1/2*mmat(mmat(nxn-m1,gtensor),nxn) + 1/2*mmat(mmat(nxn,gtensor),2*nxn-m1);
    end
end

hklIdx = [floor(((1:nSlice)-1)/nSlice*nHkl)+1 nHkl+1];

% empty Sab
Sab = zeros(3,3,2*nMagExt,0);

% calculate all magnetic form factors
if param.formfact
    % Calculates momentum transfer in A^-1 units.
    hklA0 = 2*pi*(hkl0'/swobj.basisvector)';
    % store form factor per Q point for each atom in the magnetic supercell
    FF = repmat(param.formfactfun(permute(swobj.unit_cell.ff(1,:,swobj.matom.idx),[3 2 1]),hklA0),[prod(nExt) 1]);
end

for jj = 1:nSlice
    % q indices selected for every chunk
    hklIdxMEM  = hklIdx(jj):(hklIdx(jj+1)-1);
    % q values without the +/-k_m vector
    hklExt0MEM = hklExt0(:,hklIdxMEM);
    nHklMEM = size(hklIdxMEM,1);

    % Use Brille interpolated energy and eigenvectors
    V = permute(V0(hklIdxMEM,:,:), [2 3 1]);

    % Calculates correlation functions.
    % V right
    VExtR = repmat(permute(V  ,[4 5 1 2 3]),[3 3 1 1 1]);
    % V left: conjugate transpose of V
    VExtL = conj(permute(VExtR,[1 2 4 3 5]));
    
    % Introduces the exp(-ikR) exponential factor.
    ExpF =  exp(-1i*sum(repmat(permute(hklExt0MEM,[1 3 2]),[1 nMagExt 1]).*repmat(RR,[1 1 nHklMEM]),1));
    % Includes the sqrt(Si/2) prefactor.
    ExpF = ExpF.*repmat(sqrt(S0/2),[1 1 nHklMEM]);
    
    ExpFL =      repmat(permute(ExpF,[1 4 5 2 3]),[3 3 2*nMagExt 2]);
    % conj transpose of ExpFL
    ExpFR = conj(permute(ExpFL,[1 2 4 3 5]));
    
    zeda = repmat(permute([zed conj(zed)],[1 3 4 2]),[1 3 2*nMagExt 1 nHklMEM]);
    % conj transpose of zeda
    zedb = conj(permute(zeda,[2 1 4 3 5]));
    
    % calculate magnetic structure factor using the hklExt0 Q-values
    % since the S(Q+/-k,omega) correlation functions also belong to the
    % F(Q)^2 form factor
    
    if param.formfact
        % include the form factor in the z^alpha, z^beta matrices
        zeda = zeda.*repmat(permute(FF(:,hklIdxMEM),[3 4 5 1 2]),[3 3 2*nMagExt 2 1]);
        zedb = zedb.*repmat(permute(FF(:,hklIdxMEM),[3 4 1 5 2]),[3 3 2 2*nMagExt 1]);
    end
    
    if param.gtensor
        % include the g-tensor
        zeda = mmat(repmat(permute(gtensor,[1 2 4 3]),[1 1 1 2]),zeda);
        zedb = mmat(zedb,repmat(gtensor,[1 1 2]));
    end
    % Dynamical structure factor from S^alpha^beta(k) correlation function.
    % Sab(alpha,beta,iMode,iHkl), size: 3 x 3 x 2*nMagExt x nHkl.
    % Normalizes the intensity to single unit cell.
    Sab = cat(4,Sab,squeeze(sum(zeda.*ExpFL.*VExtL,4)).*squeeze(sum(zedb.*ExpFR.*VExtR,3))/prod(nExt));
end

% If number of formula units are given per cell normalize to formula
% unit
if swobj.unit.nformula > 0
    Sab = Sab/double(swobj.unit.nformula);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END MEMORY MANAGEMENT LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if incomm
    % resize matrices due to the incommensurability (k-km,k,k+km) multiplicity
    kmIdx = repmat(sort(repmat([1 2 3],1,nHkl0/3)),1,1);
    % Rodrigues' rotation formula.
    nx  = [0 -n(3) n(2); n(3) 0 -n(1); -n(2) n(1) 0];
    nxn = n'*n;
    K1 = 1/2*(eye(3) - nxn - 1i*nx);
    K2 = nxn;
    
    % keep the rotation invariant part of Sab
    %nx  = [0 -n(3) n(2);n(3) 0 -n(1);-n(2) n(1) 0];
    %nxn = n'*n;
    m1  = eye(3);
    
    % if the 2*km vector is integer, the magnetic structure is not a true
    if helical
        % integrating out the arbitrary initial phase of the helix
        Sab = 1/2*Sab - 1/2*mmat(mmat(nx,Sab),nx) + 1/2*mmat(mmat(nxn-m1,Sab),nxn) + 1/2*mmat(mmat(nxn,Sab),2*nxn-m1);
    end
    
    % exchange matrices
    Sab   = cat(3,mmat(Sab(:,:,:,kmIdx==1),K1), mmat(Sab(:,:,:,kmIdx==2),K2), ...
        mmat(Sab(:,:,:,kmIdx==3),conj(K1)));
    
    hkl   = hkl(:,kmIdx==2);
    nHkl0 = nHkl0/3;
else
    helical = false;
end

if ~param.gtensor && any(swobj.single_ion.g)
    warning('spinw:spinwave:NonZerogTensor',['The SpinW model defines a '...
        'g-tensor that is not included in the calculation. Anisotropic '...
        'g-tensor values cannot be applied afterwards as they change relative'...
        'spin wave intensities!'])
end

end
