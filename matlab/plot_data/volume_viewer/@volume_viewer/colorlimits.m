function colorlimits(obj,limits)
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

% Set color limits for the axes and colorbar. 
set([obj.handles.axes1,obj.handles.axes2,obj.handles.axes3],'CLim',limits);
drawnow
end