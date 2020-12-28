import brille
import numpy as np

def create_bz(*args, is_reciprocal=False, use_primitive=True, search_length=1,
              time_reversal_symmetry=False, wedge_search=True, **kwargs):
    """
    Construct a BrillouinZone object. 

    Parameters
    ----------
    a, b, c : float
        Lattice parameters as separate floating point values
    lens : (3,) :py:class:`numpy.ndarray` or list
        Lattice parameters as a 3-element array or list
    alpha, beta, gamma : float
        Lattice angles in degrees as separate floating point values
    angs : (3,) :py:class:`numpy.ndarray` or list
        Lattice angles in degrees as a 3-element array or list
    lattice_vectors : (3, 3) :py:class:`numpy.ndarray` or list of list
        The lattice vectors as a 3x3 matrix, array or list of list
    spacegroup: str or int
        The spacegroup in either International Tables (Hermann-Mauguin)
        notation or a Hall symbol or an integer Hall number.
    is_reciprocal : bool, keyword-only optional (default: False)
        Whether the lattice parameters or lattice vectors refers to a 
        reciprocal rather than direct lattice. If True, a/b/c/lens should
        be in reciprocal Angstrom, otherwise they should be in Angstrom
    use_primitive : bool, keyword-only optional (default: True)
        Whether the primitive (or conventional) lattice should be used
    search_length : int, keyword-only optional (default: 1)
        An integer to control how-far the vertex-finding algorithm should
        search in τ-index. The default indicates that (1̄1̄1̄), (1̄1̄0), (1̄1̄1),
        (1̄0̄1), ..., (111) are included.
    time_reversal_symmetry : bool, keyword-only optional (default: False)
        Whether to include time-reversal symmetry as an operation to
        determine the irreducible Brillouin zone
    wedge_search : bool, keyword-only optional (default: True)
        If true, return an irreducible first Brillouin zone,
        otherwise just return the first Brillouin zone

    Note that the required lattice parameters must be specified as:
        create_bz(a, b, c, alpha, beta, gamma, spacegroup, ...)
        create_bz(lens, angs, spacegroup, ...)
        create_bz(lattice_vectors, spacegroup, ...)
    E.g. you cannot mix specifing `a`, `b`, `c`, and `angs` etc.
    """
    # Take keyword arguments in preference to positional ones
    a, b, c, alpha, beta, gamma, lens, angs = (kwargs.pop(pname, None)
        for pname in ['a', 'b', 'c', 'alpha', 'beta', 'gamma', 'lens', 'angs'])
    no_lat_kw_s = any([v is None for v in [a, b, c, alpha, beta, gamma]])
    no_lat_kw_v = any([v is None for v in [lens, angs]])
    if no_lat_kw_v and not no_lat_kw_s:
        lens, angs = ([a, b, c], [alpha, beta, gamma])
    lattice_vectors = kwargs.pop('lattice_vectors', None)
    spacegroup = kwargs.pop('spacegroup', None)
    # Parse positional arguments
    spg_id = 0
    if no_lat_kw_s and no_lat_kw_v and lattice_vectors is None:
        if np.shape(args[0]) == ():
            lens, angs = (args[:3], args[3:6])
            spg_id = 6
        elif np.shape(args[0]) == (3,):
            lens, angs = tuple(args[:2])
            spg_id = 2
        elif np.shape(args[0]) == (3,1) or np.shape(args[0]) == (1,3):
            lens, angs = tuple(args[:2])
            lens = np.squeeze(np.array(lens))
            angs = np.squeeze(np.array(angs))
            spg_id = 2
        elif np.shape(args[0]) == (3,3):
            lattice_vectors = args[0]
            spg_id = 1
        else:
            raise ValueError('No lattice parameters or vectors given')
    if spacegroup is None:
        if len(args) > spg_id:
            spacegroup = args[spg_id]
        else:
            raise ValueError('Spacegroup not given')
    if not isinstance(spacegroup, str):
        spacegroup = int(spacegroup)

    if is_reciprocal:
        if lattice_vectors is not None:
            lattice = brille.Reciprocal(lattice_vectors, spacegroup)
        else:
            lattice = brille.Reciprocal(lens, angs, spacegroup)
    else:
        if lattice_vectors is not None:
            lattice = brille.Direct(lattice_vectors, spacegroup)
        else:
            lattice = brille.Direct(lens, angs, spacegroup)
        lattice = lattice.star

    return brille.BrillouinZone(lattice, use_primitive=use_primitive,
                                search_length=search_length,
                                time_reversal_symmetry=time_reversal_symmetry,
                                wedge_search=wedge_search)


def create_grid(bz, complex_values=False, complex_vectors=False,
                mesh=False, nest=False, **kwargs):
    """
    Constructs an interpolation grid for a given BrillouinZone object

    Brille provides three different grid implementations:
        BZTrellisQ: A hybrid Cartesian and tetrahedral grid, with 
            tetrahedral nodes on the BZ surface and cuboids inside. 
        BZMeshQ: A fully tetrahedral grid with a layered data structure
        BZNestQ: A fully tetrahedral grid with a nested tree data 
            structure.

    By default a BZTrellisQ grid will be used.

    Parameters
    ----------
    bz : :py:class: `BrillouinZone`
        A BrillouinZone object (required)
    complex_values : bool, optional (default: False)
        Whether the interpolated scalar quantities are complex
    complex_vectors : bool, optional (default: False)
        Whether the interpolated vector quantities are complex
    mesh: bool, optional (default: False)
        Whether to construct a BZMeshQ instead of a BZTrellisQ grid
    nest: bool, optional (default: False)
        Whether to construct a BZNestQ instead of a BZTrellisQ grid

    Note that if both `mesh` and `nest` are True, a BZTrellisQ grid
    will be constructed. Additional keyword parameters will be passed
    to the relevant grid constructors. They are:

    BZTrellisQ Parameters
    ---------------------
    node_volume_fraction : float, optional (default: 1e-5)
        The fractional volume of a tetrahedron in the mesh
        Smaller numbers will result in better interpolation 
        accuracy at the cost of greater computation time.
    always_triangulate : bool, optional (default: False)
        If set to True, we calculate a bounding polyhedron
        for each point in the grid, and triangulate this into
        tetrahedrons. If False, we set internal points to be 
        cuboid and compute tetrahedrons only for points near
        the surface of the Brillouin Zone.

    BZMeshQ Parameters
    ------------------
    max_size : float, optional (default: -1.0)
        The maximum volume of a tetrahedron in cubic reciprocal
        Angstrom. If set to a negative value, Tetgen will generate
        a tetrahedral mesh without a volume constraint.
    num_levels : int, optional (default: 3)
        The number of layers of triangulation to use.
    max_points : int, optional (default: -1)
        The maximum number of additional mesh points to add to
        improve the mesh quality. Setting this to -1 will allow
        Tetgen to create an unlimited number of additional points.

    BZNestQ Parameters
    ------------------
    max_volume: float
        Maximum volume of a tetrahedron in cubic reciprocal Angstrom.
    number_density: float 
        Number density of points in reciprocal space.
    max_branchings: int, optional (default: 5)
        Maximum number of branchings in the tree structure

    Note that one of the `max_volume` or `number_density` parameters
    must be provided to construct a BZNestQ.
    """
    if not isinstance(bz, brille._brille.BrillouinZone):
        raise ValueError('The `bz` input parameter is not a BrillouinZone object')
    if nest and mesh:
        nest, mesh = False, False

    def constructor(grid_type):
        if complex_values and complex_vectors:
            return getattr(brille, grid_type+'cc')
        elif complex_vectors:
            return getattr(brille, grid_type+'dc')
        else:
            return getattr(brille, grid_type+'dd')
 
    if nest:
        if 'max_volume' in kwargs:
            return constructor('BZNestQ')(bz, float(kwargs['max_volume']),
                                          kwargs.pop('max_branchings', 5))
        elif 'number_density' in kwargs:
            return constructor('BZNestQ')(bz, int(kwargs['number_density']), 
                                          kwargs.pop('max_branchings', 5))
        else:
            raise ValueError('Neither `max_volume` nor `number_density` provided')
    elif mesh:
        return constructor('BZMeshQ')(bz, float(kwargs.pop('max_size', -1.0)),
                                      int(kwargs.pop('num_levels', 3)),
                                      int(kwargs.pop('max_points', -1)))
    else:
        return constructor('BZTrellisQ')(bz, float(kwargs.pop('node_volume_fraction', 1.e-5)),
                                         bool(kwargs.pop('always_triangulate', False)))

