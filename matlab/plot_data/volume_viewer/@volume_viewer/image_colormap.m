function image_colormap(obj,cmap)
% Have the figure background blend in with the image background by setting
% figure/axis colors to the minimum color in the colormap.

% Get colormap info.
min_color = cmap(1,:);

% Set figure color
obj.handles.figure1.Color = min_color;

% Set axis color
set([obj.handles.axes1,obj.handles.axes2,obj.handles.axes3], ...
    'Color'             , min_color         , ...
    'XColor'            , min_color         , ...
    'YColor'            , min_color         , ...
    'ColorMap'          , cmap              ); % Listener is not recursive. 

% Set text color to inverse of figure color
set([obj.handles.text1,obj.handles.text2,obj.handles.text3], ...
    'BackgroundColor'   , min_color         , ...
    'ForegroundColor'   , 1-min_color       ); 
drawnow
end