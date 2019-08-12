%% Only modify things in this section.
% Note: Figures were created on a 2560 x 1440 resolution screen. 
% Relative positions of figure elements to each other may shift at other 
% resolutions. 

% Set this to the location of your BrainSpace directory.
brainspace_path = '/data/mica1/03_projects/reinder/micasoft/BrainSpace';

% Set to true if you want to save .png files of the figures.
save_figures = true;

if save_figures
    % Set this to the location where you want to store your figures. 
    figure_path = '/data/mica1/03_projects/reinder/figures/2019-BrainSpace/figure_5';
    mkdir(figure_path)
end

% Set the desired kernel and manifold for figure 1A and 1B. 
% Use P (Pearson), SM (Spearman), CS (Cosine Similarity), 
% NA (Normalized Angle), or G (Gaussian) for the kernel and 
% PCA (Principal Component Analysis), LE (Laplacian Eigenmap)
% or DM (diffusion map embedding) for the manifold.
target_kernel = 'CS';
target_manifold = 'DM';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Do not modify the code below this %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load data
addpath(genpath([brainspace_path filesep 'matlab']));

% Load brain surfaces and mask
surface_path = [brainspace_path filesep 'shared' filesep 'surfaces' filesep];
left_sphere = convert_surface([surface_path 'conte69_32k_left_sphere.gii']);
right_sphere = convert_surface([surface_path 'conte69_32k_right_sphere.gii']);
left_surface_32k = convert_surface([surface_path 'conte69_32k_left_hemisphere.gii']);
right_surface_32k = convert_surface([surface_path 'conte69_32k_right_hemisphere.gii']);
left_surface_5k = convert_surface([surface_path 'conte69_5k_left_hemisphere.gii']);
right_surface_5k = convert_surface([surface_path 'conte69_5k_right_hemisphere.gii']);
mask = load([surface_path 'conte69_5k_midline_mask.csv']);

tmp = gifti('/data/mica1/03_projects/reinder/01_hcp/masks/temporalMask.label.gii');
temporal_mask = tmp.cdata > 0;

% Download the data if it doesn't exist. 
data_path = [brainspace_path filesep 'shared' filesep 'data' filesep 'online'];
data_file = [data_path filesep 'figure_data.mat'];
download_data(data_file)

% Load data
tmp = load(data_file,'figure1');
logi_m = tmp.figure1.manifolds == string(target_manifold);
logi_k = tmp.figure1.kernels == string(target_kernel);
G = tmp.figure1.G{logi_m,logi_k};

% Load cortical markers
main_group_directory = [brainspace_path filesep 'shared' filesep 'data' ...
                        filesep 'main_group' filesep]; 
thickness = load([main_group_directory 'conte69_32k_thickness.csv']);                  
t1wt2w = load([main_group_directory 'conte69_32k_t1wt2w.csv']);                  
t1wt2w(isnan(thickness)) = nan; % Midline is included in t1wt2w data. 
data = [thickness,t1wt2w];

% Vertex indices for downsampling 32k surfaces.
vertex_indices = load(string(brainspace_path) + filesep + 'shared' + filesep + "surfaces" + filesep + "conte69_5k_vertex_indices.csv");
data_5k = data(vertex_indices,:);
temporal_mask_5k = temporal_mask(vertex_indices,:);

%% Spin test
rng(0);
n_perm = 1000;
rand_data_spin = spintest({data(1:end/2,:),data(end/2+1:end,:)}, ...
                          {left_sphere,right_sphere},n_perm);
rand_data_spin_full = [rand_data_spin{1};rand_data_spin{2}];
rand_data_spin_5k = rand_data_spin_full(vertex_indices,:,:);

% Get F-stats
Y = nan(10000,1);
Y(~mask) = G.gradients{1}(:,1);

r_real = corr(Y,data_5k,'rows','pairwise','type','spearman');

for ii = 1:n_perm
    r_rand_spin(ii,:) = corr(Y,rand_data_spin_5k(:,:,ii),'rows','pairwise', 'type', 'spearman');
end

%% Plot figure
h = struct();
h.figure = figure('Units','Normalized','Position',[0 0 1 1],'Color','w');
plotSphere = @(x)trisurf(left_sphere.tri,left_sphere.coord(1,:),left_sphere.coord(2,:), ...
                    left_sphere.coord(3,:),x,'EdgeColor','None');
plotSurf_32k = @(x)trisurf(left_surface_32k.tri,left_surface_32k.coord(1,:),left_surface_32k.coord(2,:), ...
                    left_surface_32k.coord(3,:),x,'EdgeColor','None');
pos = [.1 .78 .15 .15;
       .1 .63 .15 .15];

real_plot = data;
real_plot(isnan(real_plot)) = -inf; 
   
rand_plot = rand_data_spin{1};
rand_plot(isnan(rand_plot)) = -inf; 
sel = [6,10,12];

% Build surfaces
for ii = 1:2
    h.axes(ii,1) = axes('Position',pos(ii,:));
    h.surf(ii,1) = plotSurf_32k(real_plot(1:end/2,ii));
    h.axes(ii,2) = axes('Position',pos(ii,:) + [.09 0 0 0]);
    h.surf(ii,2) = plotSphere(real_plot(1:end/2,ii));
    for jj = 2:-1:1 % Silhouette
        h.axsil(ii,jj) = axes('Position',pos(ii,:) + [.16 + .02*jj .02*jj -.01*jj -.01*jj]); 
        h.sil(ii,jj) = plotSphere(rand_plot(:,ii,sel(1+jj))); 
    end
    h.axes(ii,3) = axes('Position',pos(ii,:) + [.16 0 0 0]);
    h.surf(ii,3) = plotSphere(rand_plot(:,ii,sel(1))); 
    h.axes(ii,4) = axes('Position',pos(ii,:) + [.25 0 0 0]);
    h.surf(ii,4) = plotSurf_32k(rand_plot(:,ii,sel(1)));
end


set([h.axes(:);h.axsil(:)]                      , ...
    'DataAspectRatio'       , [1 1 1]           , ...
    'Visible'               , 'off'             , ...
    'FontName'              , 'DroidSans'       , ...
    'FontSize'              , 14                );
set(h.surf                                      , ...
    'AmbientStrength'       , 0.3               , ...
    'DiffuseStrength'       , 0.8               , ...
    'SpecularStrength'      , 0.0               , ...
    'SpecularExponent'      , 25                , ...
    'SpecularcolorReflectance', .5              );
set(h.axes(:,[1,4])                             , ...
    'View'                  , [-90 0]           );
set(h.sil(:,2),'FaceAlpha',0.3);
set(h.sil(:,1),'FaceAlpha',0.5);
set(h.axes(1,:),'CLim',[1.3 4])
set(h.axes(2,:),'CLim',[1.3 2.2]);
for ii = 1:numel(h.axes);camlight(h.axes(ii));end
for ii = 1:numel(h.axsil);camlight(h.axsil(ii));end

% Really get those positions right
h.axes(1,1).Position = [.11 .8 .12 .12];
h.axes(2,1).Position = [.11 .65 .12 .12];
h.axes(1,4).Position = [.37 .8 .12 .12];
h.axes(2,4).Position = [.37 .65 .12 .12];

% Build histograms
for ii = 1:2
    h.axhist(ii) = axes('Position',[.48 .975-ii*.15 .08 .08]);
    h.hist(ii) = histogram(r_rand_spin(:,ii),30);
    h.line(ii) = line([r_real(ii),r_real(ii)],[0,100]); 
    xlabel('Spearman Correlation')
end

% Set a whole bunch of histogram properties
set(h.axhist                                    , ...
    'PlotBoxAspectRatio'    , [1 1 1]           , ...
    'Box'                   , 'off'             , ...
    'XLim'                  , [-.60 .60]        , ...
    'XTick'                 , [-.60 0 .60]      , ...
    'YLim'                  , [0 100]           , ...
    'YTick'                 , [0 100]           , ...
    'FontName'              , 'DroidSans'       , ...
    'FontSize'              , 11                );

set(h.hist                                      , ...
    'FaceColor'             , [.7 .7 .7]        ); 

set(h.line                                      , ...
    'LineStyle'             , '--'              , ...
    'Color'                 , 'k'               , ...
    'LineWidth'             , 1.5               );

% Add text
t = {'Thickness','T1w/T2w'};
for ii = 1:2
    h.typetext(ii) = text(h.axes(ii,1),-.1,.4,t{ii},'Units','Normalized', ...
        'Rotation',90,'HorizontalAlignment','center');
end

t2 = {{'Data on','Cortex'},{'Data on','Sphere'},{'Rotated Data','on Sphere'}, ...
    {'Rotated Data', 'on Cortex'}};
for ii = 1:4
    if ismember(ii,[1,4])
        x = .6; y = 1.33;
    elseif ii == 3
        x = .69; y = 1.2;
    else
        x = .5; y = 1.2;
    end
    h.columntext(ii) = text(h.axes(1,ii),x, y ,t2{ii},'Units','Normalized', ...
        'HorizontalAlignment','Center');
end

set([h.typetext,h.columntext]                   , ...
    'FontName'              , 'DroidSans'       , ...
    'FontSize'              , 16                );

if save_figures
    export_fig([figure_path filesep 'figure5a.png'],'-m2','-png');
end
    