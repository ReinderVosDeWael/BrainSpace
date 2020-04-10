function overlay_colormap(obj,cmap)
% Set the overlay colormaps. 

% Set axis color
set([obj.handles.axes4,obj.handles.axes5,obj.handles.axes6], ...
    'ColorMap'          , cmap              ); % Listener is not recursive. 

drawnow
end