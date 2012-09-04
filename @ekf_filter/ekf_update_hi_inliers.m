%-----------------------------------------------------------------------
% 1-point RANSAC EKF SLAM from a monocular sequence
%-----------------------------------------------------------------------

% Copyright (C) 2010 Javier Civera and J. M. M. Montiel
% Universidad de Zaragoza, Zaragoza, Spain.

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation. Read http://www.gnu.org/copyleft/gpl.html for details

% If you use this code for academic work, please reference:
%   Javier Civera, Oscar G. Grasa, Andrew J. Davison, J. M. M. Montiel,
%   1-Point RANSAC for EKF Filtering: Application to Real-Time Structure from Motion and Visual Odometry,
%   to appear in Journal of Field Robotics, October 2010.

%-----------------------------------------------------------------------
% Authors:  Javier Civera -- jcivera@unizar.es
%           J. M. M. Montiel -- josemari@unizar.es

% Robotics, Perception and Real Time Group
% Arag�n Institute of Engineering Research (I3A)
% Universidad de Zaragoza, 50018, Zaragoza, Spain
% Date   :  May 2010
%-----------------------------------------------------------------------

function filter = ekf_update_hi_inliers( filter, features_info )

% mount vectors and matrices for the update
z = [];
h = [];
H = [];
%%% TAMADD
dbg_high_innovation_count = 0;
for i=1:length( features_info )
    
    if features_info(i).high_innovation_inlier == 1
        dbg_high_innovation_count = dbg_high_innovation_count + 1;
    end
    
end
% disp(['dbg_high_innovation_count = ',num2str(dbg_high_innovation_count)]);
%%%

for i=1:length( features_info )
    
    if features_info(i).high_innovation_inlier == 1
        z = [z; features_info(i).z(1); features_info(i).z(2)];
        h = [h; features_info(i).h(1); features_info(i).h(2)];
        H = [H; features_info(i).H];
    end
    
end

R_z = eye(length(z));
if ~isempty(z)
    [z_dpose,h_dpose,H_dpose,R_dpose] = observe_dpose(filter.x_k_k);
    R_agg = blkdiag(R_z,R_dpose);
    H_agg = [H;[H_dpose,zeros(7,size(H,2)-13)]];
    z_agg = [z;z_dpose];
    h_agg = [h;h_dpose];
    [ filter.x_k_k, filter.p_k_k ] = update( filter.x_k_k, filter.p_k_k, H_agg,...
        R_agg, z_agg, h_agg );
end

