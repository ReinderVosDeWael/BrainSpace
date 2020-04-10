classdef volume_viewer < handle
    
    %% Properties of the class (i.e. stored variables).
    % Properties that the user may not modify.
    properties(SetAccess = private)
        image % Anatomical image; Should only be defined at initialization.
        overlay % Gradient/Parcellation image. Could potentially be changed to a data vector + parcellation, and we generate the overlay internally. 
        handles % Graphics object handles. 
    end
    
    % Properties that the user may modify. SetObservable allows us to call
    % functions whenever either of these properties is changed. I've used
    % this a lot to call a function that plots new slices whenever the
    % slice property changes.
    properties(SetObservable)
        slices % Lets advanced users programatically set slice numbers. 
    end
    
    %% Methods of the class (i.e. functions). 
    methods
        function obj = volume_viewer(varargin)
            % Constructor function; this runs when the object is first
            % created. 
            
            % Parse the input.
            is_3d_numeric = @(x)numel(size(x)) == 3 && isnumeric(x); 
            p = inputParser();
            addRequired(p,'image',is_3d_numeric)  
            addOptional(p,'overlay',[],is_3d_numeric)  
            parse(p, varargin{:}); 
            
            % Check data compatiblity
            if ~isempty(p.Results.overlay)
                if ~all(size(p.Results.image) == size(p.Results.overlay))
                    error('Image and overlay must have the same dimensions.');
                end
            end
            
            % Set some object properties.
            obj.image = p.Results.image;
            obj.overlay = p.Results.overlay;
            obj.slices = round(size(obj.image)/2);
                        
            % Initialize figure. 
            obj.build_figure(obj.image);
            
            % After setting slices the first time, whenever the slices
            % property is changed we will replot the images.
            addlistener(obj,'slices','PostSet',@(~,~)obj.replot);
        end
        
        %% Set/Get functions. 
        function set.slices(obj,new_slices)
            % Check for correct input. This vector can be modified by the
            % user so there's quite a few checks.
            if numel(new_slices) ~= 3
                error('The slices vector must consist of 3 elements.');
            end
            if any(new_slices > size(obj.image)) % Can ignore this warning - we guarantee that image is set before slices in the constructor. 
                error('Slice number may not exceed image dimensions.');
            end
            if any(new_slices < 1)
                error('Slice number may not be lower than 1.');
            end
            if any(round(new_slices) ~= new_slices)
                error('Slice numbers must be integers.');
            end
            
            % Set slices. 
            obj.slices = new_slices; 
        end
    end
end
