% brillem -- a MATLAB interface for brille
% Copyright 2020 Greg Tucker
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

function plot3(bzSTAR,varargin)
    defs=struct('facecolor','none',...
                'facealpha',1,...
                'edgecolor','k',...
                'edgealpha',1,...
                'showgrid',true,...
                'fullgrid',false,...
                'units','invA',...
                'origin',[0,0,0]);
    [~,kwds]=brille.parse_arguments(varargin,defs,{'showgrid','fullgrid'});
    ph = ishold();
    hold on;

    isgrid = false;
    if isa(bzSTAR, 'py.brille._brille.BrillouinZone')
        bz = bzSTAR;
    elseif brillem.is_brille_grid(bzSTAR)
        bz = bzSTAR.BrillouinZone;
        isgrid = true;
    end
    assert( exist('bz','var')==1, 'The first input must be a brille.BrillouinZone or brille.BZ* object');

    % pull out MATLAB versions of python numpy arrays
    if strcmpi(kwds.units,'rlu')
        faces = double(bz.points);
        verts = double(bz.vertices);
    else
        faces = double(bz.points_invA);
        verts = double(bz.vertices_invA);
    end

    v_p_f = bz.vertices_per_face;
    for i=1:size(faces,1)
        perm = brillem.p2m(py.numpy.array(v_p_f(i))) + 1; % +1 converts indexing
        patch('faces', perm, 'vertices', verts+kwds.origin, ...
              'facecolor', kwds.facecolor, 'facealpha', kwds.facealpha, ...
              'edgecolor', kwds.edgecolor, 'edgealpha', kwds.edgealpha);
    end

    if (isgrid || ismesh) && kwds.showgrid
        if ismesh || kwds.fullgrid
            grid_points = double(bzSTAR.invA);
        else
            grid_points = double(bzSTAR.mapped_invA);
        end
        plotpoints3(grid_points+kwds.origin,[],[],{'Q_x','Q_y','Q_z'});
    end

    view(3)
    axis equal

    if ~ph
        hold off;
    end
end
