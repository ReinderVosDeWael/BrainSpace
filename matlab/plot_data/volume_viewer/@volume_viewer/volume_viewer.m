classdef volume_viewer < handle
    
    %% Properties of the class (i.e. stored variables).
    % Properties that the user may not modify.
    properties(SetAccess = private)
        image % Anatomical image; Should only be defined at initialization.
        overlay % Gradient/Parcellation image. Could potentially be changed to a data vector + parcellation, and we generate the overlay internally. 
        handles % Graphics object handles. 
        metadata % For storing metadata with figures. 
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
            is_scalar_numeric = @(x)numel(x)==1 && isnumeric(x);
            p = inputParser();
            addRequired(p,'image')  
            addOptional(p,'overlay',[])
            addParameter(p,'gradient_nr',1,is_scalar_numeric);
            addParameter(p,'group_nr',1,is_scalar_numeric);
            addParameter(p,'aligned', [], @islogical);
            addParameter(p,'parcellation',[],is_3d_numeric); 
            
            parse(p, varargin{:}); 
            R = p.Results; 
            
            % Build the image. 
            if is_3d_numeric(R.image)
                % If a 3D volume is provided.
                obj.image = R.image;
            elseif ischar(R.image)
                % If a 3D volume file is provided. 
                obj.image = load_volume(R.image);             
            end
            
            % Build the overlay.
            if ~isempty(R.overlay)
                if is_3d_numeric(R.overlay)
                    % If a 3D volume is provided.
                    obj.overlay = R.overlay;
                elseif ischar(R.overlay)
                    % If a 3D volume file is provided. 
                    obj.overlay = load_volume(R.overlay); 
                elseif isa(R.overlay,'GradientMaps')
                    % If a GradientMaps object is provided. 

                    % Check if a parcellation is provided.
                    if isempty(R.parcellation)
                        error('If a GradientMaps object is provided, then a parcellation volume is obligatory.');
                    elseif ischar(R.parcellation)
                        R.parcellation = load_volume(R.parcellation);
                    elseif ~isnumeric(R.parcellation)
                        error('Parcellation must either be a volume file or a 3d matrix.');
                    end

                    % Grab the correct gradient.
                    if isempty(R.aligned)
                        R.aligned = isempty(overlay.aligned);
                    end
                    if R.aligned
                        field = aligned;
                    else
                        field = gradients;
                    end

                    % Convert gradient vector to volume. 
                    gradient = overlay.(field){R.group_nr}(:,r.gradient_nr);
                    obj.overlay = parcel2full(gradient,R.parcellation); 

                    % Store metadata. 
                    obj.metadata = overlay.methods;
                else
                    error('The overlay must be a GradientMaps object or 3D volume (file).');
                end
            end
            
            % Check data compatiblity
            if ~isempty(R.overlay)
                if ~all(size(obj.image) == size(obj.overlay))
                    error('Image and overlay must have the same dimensions.');
                end
            end

            % Set some object properties.
            %obj.image = R.image;
            %obj.overlay = R.overlay;
            obj.slices = round(size(obj.image)/2);
                        
            % Initialize figure. 
            obj.build_figure();
            
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
