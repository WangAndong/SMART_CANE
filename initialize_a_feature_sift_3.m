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

function [ filter, features_info, uv,flag_no_more_features ] = initialize_a_feature_sift_3(UV_GoodFeaturesToInitialize,...
    XYZ_GoodFeaturesToInitialize,...
    DESCRIPTOR_GoodFeaturesToInitialize,...
    step,...
    NS,...
    cam, im_k,...
    filter, features_info)
% numerical values
global myCONFIG
persistent current_step  idxInNormRand WeightedSample_idx
BoxLimX=[1 176];
BoxLimY=[1 144];

flag_no_more_features =0;

if isempty(current_step) || (~isempty(current_step)  && current_step ~= step )
    current_step = step;
      WeightedSample_idx = Weighted_Smpl_wo_replacement(UV_GoodFeaturesToInitialize,BoxLimX,BoxLimY);
    idxInNormRand = 1;
end
if idxInNormRand>size(UV_GoodFeaturesToInitialize,1)
     uv=[];
     flag_no_more_features = 1;
     return
end
half_patch_size_when_initialized = 20;
half_patch_size_when_matching = 6;
excluded_band = half_patch_size_when_initialized + 1;
max_initialization_attempts = 1;
%% DEBUG make the size smaller for SIFT
% initializing_box_size = [60,40]; ORIGINAL SIZE
initializing_box_size = [60,40]/2;
%%
initializing_box_semisize = initializing_box_size/2;

initial_rho = 1;
std_rho = 1;

std_pxl = get_std_z(filter);

% rand_attempt = 1;
not_empty_box = 1;
detected_new=0;


features_info = predict_camera_measurements( get_x_k_k(filter), cam, features_info );

uv_pred = [];
for i=1:length(features_info)
    uv_pred = [uv_pred features_info(i).h'];
end

imTemp=im_k(BoxLimY(1):BoxLimY(2),BoxLimX(1):BoxLimX(2));
search_region_center(2)=UV_GoodFeaturesToInitialize(WeightedSample_idx(idxInNormRand),1);
search_region_center(1)=UV_GoodFeaturesToInitialize(WeightedSample_idx(idxInNormRand),2);

all_uv = UV_GoodFeaturesToInitialize(WeightedSample_idx(idxInNormRand),1:2)';


nPoints=size(all_uv,2);

% Are there corners in theneighborId box?
are_there_corners = not(isempty(all_uv));

% Are there other features in the box?
if ~isempty(uv_pred)
    total_features_number = size(uv_pred,2);
    features_in_the_box =...
        (uv_pred(1,:)>ones(1,total_features_number)*(search_region_center(1)-initializing_box_semisize(1)))&...
        (uv_pred(1,:)<ones(1,total_features_number)*(search_region_center(1)+initializing_box_semisize(1)))&...
        (uv_pred(2,:)>ones(1,total_features_number)*(search_region_center(2)-initializing_box_semisize(2)))&...
        (uv_pred(2,:)<ones(1,total_features_number)*(search_region_center(2)+initializing_box_semisize(2)));
    are_there_features = (sum(features_in_the_box)~=0);
else
    are_there_features = false;
end

if(are_there_corners&&(~are_there_features))
    uv = all_uv;
    uv_integer = uv;
    uv = uv(:,1);% - [0.5,0.5]';
    detected_new = 1;
else
    uv=[];
end

if(~isempty(uv))
    % initialize the depth from laser
    %%% TAMADD
    Feature3d_in_code_coordinate = XYZ_GoodFeaturesToInitialize(:,WeightedSample_idx(idxInNormRand));
    initial_rho = 1/norm(Feature3d_in_code_coordinate);
    %%%
    % add the feature to the filter
    if isempty(initial_rho)
        uv = [];
        return
    end
    [ X_RES, P_RES, newFeature ] = add_features_inverse_depth( uv, get_x_k_k(filter),...
        get_p_k_k(filter), cam, std_pxl, initial_rho, std_rho );
    filter = set_x_k_k(filter, X_RES);
    filter = set_p_k_k(filter, P_RES);
    
    % add the feature to the features_info vector
    %         features_info = add_feature_to_info_vector( uv, im_k, X_RES, features_info, step, newFeature );
    features_info = add_feature_to_info_vector_my_version_sift( uv, im_k, X_RES, features_info, step,...
        newFeature,Feature3d_in_code_coordinate,DESCRIPTOR_GoodFeaturesToInitialize(:,WeightedSample_idx(idxInNormRand)) );
    
    
end
idxInNormRand = idxInNormRand + 1;
for j=1:length(features_info)
    features_info(j).h = [];
end





% %% Test scripts
% hh=figure;
% imshow(im_k,[])
% hold on
% plot(all_uv(1,:),all_uv(2,:),'or')
% %%