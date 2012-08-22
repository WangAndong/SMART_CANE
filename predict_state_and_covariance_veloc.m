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

function [ X_km1_k, P_km1_k ] = predict_state_and_covariance( X_k, P_k, type, SD_A_component_filter, SD_alpha_component_filter )
persistent time_stamp
global myCONFIG

if isempty(time_stamp)
    load([myCONFIG.PATH.DATA_FOLDER,'/TimeStamp/TimeStamp.mat'],'time_stamp')
end

delta_t = 0.1;
% delta_t = 1/10;
% delta_t = 0.1205;
global step_global
% camera motion prediction
[Xv_km1_k,v_for_noise,w_for_noise,dq__,dX__] = fv( X_k(1:13,:), delta_t, type, SD_A_component_filter, SD_alpha_component_filter  );


previous_time_difference = ((time_stamp(1,step_global-1) - time_stamp(1,step_global-2) )/1000);
if previous_time_difference<0.001
    previous_time_difference=0.001;
    disp('Time stamp difference 0 ');
end

current_time_difference = ((time_stamp(1,step_global) - time_stamp(1,step_global-1) )/1000);
if current_time_difference<0.001
    current_time_difference=0.001;
    disp('Time stamp difference 0 ');
end

v__ = q2R( X_k(4:7))'*dX__/previous_time_difference;

[a__,u__]=q2au(dq__);
angular_velocity = (a__/previous_time_difference)*u__;



u = [v__-X_k(8:10);angular_velocity-X_k(11:13)];
[Xv_km1_k, Xo_x, Xo_u] = constVel(X_k(1:13,:), u, current_time_difference);


% features prediction
X_km1_k = [ Xv_km1_k; X_k( 14:end,: ) ];

% state transition equation derivatives
% F = sparse( dfv_by_dxv( X_k(1:13,:),zeros(6,1),delta_t, type ) );
F = Xo_x;
G = Xo_u;
% state noise
%% original motion model uncertainty (symetric)
linear_acceleration_noise_covariance = (SD_A_component_filter*current_time_difference)^2;
angular_acceleration_noise_covariance = (SD_alpha_component_filter*current_time_difference)^2;



Pn = sparse (diag( [linear_acceleration_noise_covariance linear_acceleration_noise_covariance linear_acceleration_noise_covariance...
    angular_acceleration_noise_covariance angular_acceleration_noise_covariance angular_acceleration_noise_covariance] ) );

% v_norm = (v_for_noise+1)/norm((v_for_noise+1));
% w_norm = (w_for_noise+1)/norm((w_for_noise+1));

% v_norm = (v_for_noise+1)/norm((v_for_noise+1));
% w_norm = (w_for_noise+1)/norm((w_for_noise+1));
% u
% 


% Pn = calc_cov_RANSAC_dr_ye(step_global-2,step_global-1);


Q = G*Pn*G';





% Q = func_Q( X_k(1:13,:), zeros(6,1), Pn, delta_t, type);

size_P_k = size(P_k,1);

P_km1_k = [ F*P_k(1:13,1:13)*F' + Q         F*P_k(1:13,14:size_P_k);
    P_k(14:size_P_k,1:13)*F'        P_k(14:size_P_k,14:size_P_k)];



% normalize the quaternion
Jnorm = normJac( X_km1_k( 4:7 ) );
size_P_km1_k = size(P_km1_k,1);
P_km1_k = [   P_km1_k(1:3,1:3)              P_km1_k(1:3,4:7)*Jnorm'               P_km1_k(1:3,8:size_P_km1_k);
    Jnorm*P_km1_k(4:7,1:3)        Jnorm*P_km1_k(4:7,4:7)*Jnorm'         Jnorm*P_km1_k(4:7,8:size_P_km1_k);
    P_km1_k(8:size_P_km1_k,1:3)     P_km1_k(8:size_P_km1_k,4:7)*Jnorm'      P_km1_k(8:size_P_km1_k,8:size_P_km1_k)];

X_km1_k( 4:7 ) = X_km1_k( 4:7 ) / norm( X_km1_k( 4:7 ) );



