function slice = get_slice(obj,dim,type)
% Grabs the current slice given a particular orientation (dim).
% Kept in a separate function to make sure any rotations/flips are
% identical across all calls.
%
% Could by improved by grabbing orientation info from the nifti header
% instead of hard-coding for MNI.

% If no third input argument, use obj.image. 
if nargin < 3 
    type = 1;
end

% Select the image or overlay.
if type == 1 
    img = obj.image;
elseif type == 2
    img = obj.plotted_overlay;
end

% Grab the slice. Rotate to have MNI image in correct orientation. 
if dim == 1
    slice = rot90(squeeze(img(obj.slices(dim),:,:)));
elseif dim == 2
    slice = rot90(squeeze(img(:,obj.slices(dim),:)));
elseif dim == 3
    slice = rot90(squeeze(img(:,:,obj.slices(dim))));
else 
    error('dim must be 1, 2, or 3');
end
end