function replot(obj)
% This replots the images when the user moves from one slice to another.

% If the figure has not been built yet, simply return. 
if ~contains(fieldnames(obj.handles),'figure1')
    return
end

% Change images to the clicked point. 
for ii = 1:3
    image_name = ['imagesc' num2str(ii)];
    obj.handles.(image_name).CData = obj.get_slice(ii);
end

% Change text coordinates.
labels = 'xyz';
for ii = 1:3
    text_name = ['text' num2str(ii)];        
    obj.handles.(text_name).String = [labels(ii) ' = ' num2str(obj.slices(ii))];
end