function colormap(obj,cmap,image)
% Have the figure background blend in with the image background by setting
% figure/axis colors to the minimum color in the colormap.

if ~exist('image','var')
    image = "image";
end

if lower(image) == "image"
    % Get colormap info.
    min_color = cmap(1,:);

    % Set figure color
    obj.handles.figure1.Color = min_color;

    % Set axis color
    set([obj.handles.axes1,obj.handles.axes2,obj.handles.axes3], ...
        'Color'             , min_color         , ...
        'XColor'            , min_color         , ...
        'YColor'            , min_color         , ...
        'ColorMap'          , cmap              ); 

    % Set text color to inverse of figure color
    set([obj.handles.text1,obj.handles.text2,obj.handles.text3], ...
        'BackgroundColor'   , min_color         , ...
        'ForegroundColor'   , 1-min_color       ); 
    
    % Set colors of colorbar
    obj.handles.image_colorbar.Color = 1-min_color;
    if ~isempty(obj.overlay)
        obj.handles.overlay_colorbar.Color = 1-min_color;
    end
    
elseif lower(image) == "overlay"
    % Set axis color
    set([obj.handles.axes4,obj.handles.axes5,obj.handles.axes6], ...
        'ColorMap'          , cmap              ); 
else
    error('Unknown image. Valid options are "image" and "overlay".')
end
drawnow
end