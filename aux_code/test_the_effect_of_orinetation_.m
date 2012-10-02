function [angle1,angle2,angle3,xx_,trajectory_,cov_info_]=test_the_effect_of_orinetation_(snapshot_step,h_figure)
global myCONFIG
persistent done xx trajectory cov_info

% create_step_in_source(2500)
if nargin==0
    close all
    snapshot_step = 200
    h_figure = figure
end
VRO_result_file = [myCONFIG.PATH.SOURCE_FOLDER,'VRO_result/VRO_result.mat'];
PM_result_file = [myCONFIG.PATH.SOURCE_FOLDER,'PM_result/PM_result.mat'];
nFiles = data_file_counting(myCONFIG.PATH.SOURCE_FOLDER,'d1')-1;


if isempty(xx)
    if ~exist(VRO_result_file,'file')
        [xx,varargout] = Test_RANSAC_dead_reckoning_dr_ye(1,nFiles);
        save(VRO_result_file,'xx')
        done =1;
        xx_ =xx;
        
    else
        load(VRO_result_file)
        xx_ =xx;
        done =1;
    end
end


if isempty(trajectory)
    if ~exist(PM_result_file,'file')
        i=5;
        while (i)<nFiles
            [x_k_k,p_k_k,dT1,dq1,q_expected] = read_snapshot(i);
            trajectory(:,i) = x_k_k;
            cov_info(:,:,i) = p_k_k;
            i = i+1
        end
        
        save(PM_result_file,'trajectory','cov_info');
        done=1;
        trajectory_ =trajectory;
        cov_info_ = cov_info;
    else
        load(PM_result_file)
        done =1;
        trajectory_ =trajectory;
        cov_info_ = cov_info;
    end
end
 trajectory_ =trajectory;
        cov_info_ = cov_info;
          xx_ =xx;
% if snapshot_step>=375
%      load(PM_result_file)
%      load(VRO_result_file)
% else
%     xx_ = [];
%     trajectory_ = [];
%     cov_info_ = [];
% end

% % % % % % % % % % figure;plot3(trajectory(1,4:snapshot_step-1),...
% % % % % % % % % %              trajectory(2,4:snapshot_step-1),...
% % % % % % % % % %              trajectory(3,4:snapshot_step-1),'b')
% % % % % % % % % %          hold on;
% % % % % % % % % % plot3(xx(1,4:snapshot_step-1),...
% % % % % % % % % %              xx(2,4:snapshot_step-1),...
% % % % % % % % % %              xx(3,4:snapshot_step-1),'r')
% % % % % % % % % % axis equal
% % % % % % % % % % grid on
% % % % % % % % % % legend('proposed method','VRO')
% % % % % % % % % % figure(h_figure)

% draw_camera( [trajectory(1:3,snapshot_step); trajectory(4:7,snapshot_step)], 'r' );hold on;
% draw_camera( [xx(1:3,snapshot_step); xx(4:7,snapshot_step)], 'b' );

% % % % % % % % % draw_camera( [[0;0;0]; trajectory(4:7,snapshot_step-1)], 'b' );hold on;
% % % % % % % % % draw_camera( [[0;0;0]; xx(4:7,snapshot_step-1)], 'r' );


% draw_camera( [[0;0;0]; [1;0;0;0]], 'g' );
% % % % % % % % % % axis equal
% % % % % % % % % % grid on
% legend('a','b')
% % % % % % % % % % legend('PM','VRO')

% first plane
R_PM  = q2r(trajectory(4:7,snapshot_step-1));
p1_1 = [0 0 0];p2_1= [1 0 0];p3_1= [0 0 1];
[ a_0, b_0, c_0, d_0 ] = plane_exp2imp_3d ( p1_1, p2_1, p3_1 );
%%% normalize the representation
norm1 = norm([a_0,b_0,c_0]);
a_0 = a_0/norm1; b_0 = b_0/norm1; c_0 = c_0/norm1; d_0 = d_0/norm1;
f1 = R_PM(1,3);
g1 = R_PM(2,3);
h1 = R_PM(3,3);
angle1 = planes_imp_angle_line_3d ( a_0, b_0, c_0, d_0, f1, g1, h1 )*(180/pi);
%%%
R_VRO  = q2r(xx(4:7,snapshot_step-1));
f2 = R_VRO(1,3);
g2 = R_VRO(2,3);
h2 = R_VRO(3,3);

angle2 = planes_imp_angle_line_3d ( a_0, b_0, c_0, d_0, f2, g2, h2 )*(180/pi);

[R_PF,T_PF] = plane_fit_to_data_save(snapshot_step);
R_PF = R_PF';
f3 = R_PF(1,3);
g3 = R_PF(2,3);
h3 = R_PF(3,3);
OUTPUT=SpinCalc('DCMtoEA231',R_PM,0.01,0);
temp = (180/pi)*normilize_angle_(OUTPUT*(pi/180))
R_compensate = e2R([0 OUTPUT(1)*pi/180 0]);
angle3 = planes_imp_angle_line_3d ( a_0, b_0, c_0, d_0, f3, g3, h3 )*(180/pi);
% % % % % % % % % %  drawSpan(R_compensate'*R_PF(:,[1,3]), 'g');
disp('-------------')
disp(['proposed method = ',num2str(angle1)])
disp(['VRO = ',num2str(angle2)])
disp(['Plane fitting = ',num2str(angle3)])

% OUTPUT=SpinCalc('DCMtoEA123',R_VRO,0.01,1)
% OUTPUT=SpinCalc('DCMtoEA231',R_VRO,0.01,1)
% OUTPUT=SpinCalc('DCMtoEA213',R_VRO,0.01,1)
% OUTPUT=SpinCalc('DCMtoEA321',R_VRO,0.01,1)
end
function p = normilize_angle_(p)
for i=1:length(p)
    if p(i)>pi
        p(i) = p(i) - 2*pi;
    end
    
end
end


% [cov_pose_shift,q_dpose,T_pose] = bootstrap_cov_calc(100,103);
% [d_euler,E] = q2eG(q_dpose,cov_pose_shift(4:7,4:7));
% euler_cov = (sqrt(diag(E))*180/pi);
% t_cov = sqrt(diag(cov_pose_shift(1:3,1:3)));
% disp((180/pi)*d_euler')
% disp(euler_cov')
%
% disp(T_pose')
% disp(t_cov')

% close all;test_the_effect_of_orinetation(120,figure)