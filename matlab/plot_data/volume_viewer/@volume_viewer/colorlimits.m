function colorlimits(obj,limits,image)
% Sets color limits for volume_viewer. Limits must be a 2-element
% numeric vector. The first element of limits denotes the minimum color limit and
% the second the maximum. 

% Check for correct input.
if numel(limits) ~=2
    error('Color limits must be a 2-element vector');
end
if limits(1) >= limits(2)
    error('The first element of limits must be lower than the second.');
end
if ~exist('image','var')
    image = "image";
end

% Set color limits for the axes and colorbar. 
if lower(image) == "image"
    set([obj.handles.axes1,obj.handles.axes2,obj.handles.axes3],'CLim',limits);
    obj.handles.image_colorbar.Limits = limits;
    obj.handles.image_colorbar.Ticks = limits;
elseif lower(image) == "overlay" 
    set([obj.handles.axes4,obj.handles.axes5,obj.handles.axes6],'CLim',limits);
    obj.handles.overlay_colorbar.Limits = limits;
    obj.handles.overlay_colorbar.Ticks = limits;
    obj.threshold_overlay = limits; 
end

obj.replot();
end