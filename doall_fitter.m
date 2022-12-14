fitter_data_file_name = 'fitter_from_bubble_h0p067.mat';
%fitter_data_file_name = 'fitter_from_bubble_nn818nt1501.mat';
folder_name = 'depth_3'; istamp = 250;
%bubble_model = load('bubble_model_h0p067.mat');

p_BC = [0; 0; -0.1040]; % Position of the camera C in bubble frame B.

% =========================================================================
% Read calibration data.
% =========================================================================
sprintf('Reading calibration data...')
tic
file = sprintf('../Experiments/reference_configuration/reference_configuration_offset.dat');
dist_offset = dlmread(file);
toc

% =========================================================================
% Read point cloud.
% =========================================================================
sprintf('Reading point cloud...')
tic
%file = sprintf('../Experiments/%s/point_cloud_%03d.dat', folder_name, istamp);
file = sprintf('../Experiments/point_cloud_with_contact.dat');
%file = '../Experiments/reference_configuration/reference_point_cloud_38304points_073.dat';
p_CY = dlmread(file);
dist = sqrt(sum(p_CY.^2,2));
p_BY = p_CY  + p_BC';

% Corrected point cloud. (Both dist and dist_offset will contribute to
% NaNs)
dist_corr = dist + dist_offset;
toc

% =========================================================================
% Solve inverse problem.
% =========================================================================

% Randomly draw a number of rays to ignore.
%nrays_to_ignore = 500; % We'll ignore this many rays.
%nrays = length(dist_corr);
%idx = min(nrays, ceil(nrays*rand([nrays_to_ignore, 1])));
idx = isnan(dist_corr);
weight = ones(size(dist_corr));
weight(idx) = 0;  % "Turn off" these rays.
dist_corr(idx) = -999;

[ufit, pcfit, pvfit, p_BPfit, pcray, fitter] = fit_bubble_model(fitter_data_file_name, dist_corr, weight);

% Correct point cloud.
rhat_B = fitter.rhat_B;  % Camera ray directions.
p_BY_corr = rhat_B .* dist_corr + p_BC';
p_BY_corr(idx,:) = 0;

% =========================================================================
% Write files
% =========================================================================
% Experimental point cloud, after applyig calibration correction.
file = sprintf('point_cloud_corrected_%03d.vtk', istamp);
fid = fopen(file, 'w');
vtk_write_header(fid, 'point_cloud');
vtk_write_scattered_points(fid, p_BY_corr);
vtk_write_point_data_header(fid, p_BY_corr);
vtk_write_scalar_data(fid, 'Distance', dist_corr);
vtk_write_scalar_data(fid, 'ContactPressure', pcray);
fclose(fid);

% Best fit to point cloud.
file = sprintf('bubble_fit_%03d.vtk', istamp);
fid = fopen(file, 'w');
vtk_write_header(fid, 'bubble_fit');
vtk_write_unstructured_grid(fid, p_BPfit, fitter.tris);
vtk_write_point_data_header(fid, p_BPfit);
vtk_write_scalar_data(fid, 'Displacement', ufit);
vtk_write_scalar_data(fid, 'Pressure', pcfit);
fclose(fid);
