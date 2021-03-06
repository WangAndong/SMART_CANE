function [Xo, Xo_x, Xo_u] = odometry_model(X, u, dt)

% CONSTVEL  Constant velocity motion model.
%   X = CONSTVEL(X, U, DT) performs one time step to the constant velocity
%   model:
%       x = x + R(q)*(dX+n1)
%       q = q . dq
%
%   where 
%       X = [x;q] is the state consisting of position, orientation
%           quaternion
%       U = [uv;uw] are pose shift (position,orientation),
%       DT is the sampling time.
%
%   X = odometry_model(X, DT) assumes U = zeros(6,1).
%
%   [X, X_x, X_u] = CONSTVEL(...) returns the Jacobians wrt X and U.
%
%   See also RPREDICT, QPREDICT, V2Q, QUATERNION.

%   Copyright 2008-2009 Joan Sola @ LAAS-CNRS.



% split inputs
x = X(1:3);   % position
q = X(4:7);   % orientation


dx = u(1:3);  % linear vel. change (control)
dq = u(4:7);  % angular vel. change (control)
dRt_dq_ = dRt_dq__(q,[dx(1);dx(2);dx(3)]) ;
if nargout == 1


    x = x + q2R(q)*dx;
    q = qProd(q,dq);
  
    
    % new pose
    Xo = [x;q];

else % Jacobians
    x = x + q2R(q)*dx;
    [q,Qq1,Qq2] = qProd(q,dq);
  
    
    % new pose
    Xo = [x;q];
    
    
    % time step and Jacobians
        
    % some constants
    Z34 = zeros(3,4);
    Z43 = zeros(4,3);
    Z33 = zeros(3);

 

    % Full Jacobians
    Xo_x  = [...
        eye(3)  dRt_dq_
        Z43     Qq1 ]; % wrt state

    Xo_u  = [...
        q2R(X(4:7)) Z34
        Z43   Qq2 ];  % wrt control

end


% ========== End of function - Start GPL license ==========


%   # START GPL LICENSE

%---------------------------------------------------------------------
%
%   This file is part of SLAMTB, a SLAM toolbox for Matlab.
%
%   SLAMTB is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   SLAMTB is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with SLAMTB.  If not, see <http://www.gnu.org/licenses/>.
%
%---------------------------------------------------------------------

%   SLAMTB is Copyright 2007,2008,2009 
%   by Joan Sola, David Marquez and Jean Marie Codol @ LAAS-CNRS.
%   See on top of this file for its particular copyright.

%   # END GPL LICENSE

