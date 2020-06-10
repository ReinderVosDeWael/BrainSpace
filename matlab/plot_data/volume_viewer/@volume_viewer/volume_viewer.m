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
        threshold_lower % Remove values below the overlay color limit
        threshold_upper % Remove values above the overlay color limit
        remove_zero % Remove zeros. 
    end
    
    properties(Dependent, Hidden)
        plotted_overlay % Thresholded overlay.
    end
    
    properties(Hidden, Access = private)
        threshold_overlay % Value at which to threshold the overlay. 
    end
    
    %% Methods of the class (i.e. functions). 
    methods
        function obj = volume_viewer(varargin)
            % Constructor function; this runs when the object is first
            % created. 
            
            % Parse the input.
            is_3d_numeric = @(x)numel(size(x)) == 3 && isnumeric(x); 
            is_image = @(x) ischar(x) || (isnumeric(x) && numel(size(x)) == 3);
            p = inputParser();
            addRequired(p,'image',is_image)  
            addOptional(p,'overlay',[],is_image)
            addParameter(p,'remove_zero',true, @islogical);
            addParameter(p,'threshold_lower',false);
            addParameter(p,'threshold_upper',false); 
            
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
                else
                    error('The overlay must be a 3D volume (file).');
                end
            end
            
            % Check data compatiblity
            if ~isempty(R.overlay)
                if ~all(size(obj.image) == size(obj.overlay))
                    error('Image and overlay must have the same dimensions.');
                end
            end

            % Set some object properties.
            obj.threshold_overlay = [1,2]; % Is changed in build_figure; just need to initialize with something. 
            obj.threshold_lower = R.threshold_lower;
            obj.threshold_upper = R.threshold_upper; 
            obj.remove_zero = R.remove_zero; 
            obj.slices = round(size(obj.image)/2);
                        
            % Initialize figure. 
            obj.build_figure();
            
            % After setting slices the first time, whenever the slices
            % property is changed we will replot the images. Also replot
            % when any of the other obserable properties is modified.
            addlistener(obj,'slices','PostSet',@(~,~)obj.replot);
            addlistener(obj,'threshold_lower','PostSet',@(~,~)obj.replot);
            addlistener(obj,'threshold_upper','PostSet',@(~,~)obj.replot);
            addlistener(obj,'remove_zero','PostSet',@(~,~)obj.replot);
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
        
        function plotted_overlay = get.plotted_overlay(obj)
            plotted_overlay = obj.overlay;
            if obj.threshold_lower
                plotted_overlay(plotted_overlay <= obj.threshold_overlay(1)) = nan; 
            end
            if obj.threshold_upper
                plotted_overlay(plotted_overlay >= obj.threshold_overlay(2)) = nan;
            end
            if obj.remove_zero
                plotted_overlay(plotted_overlay == 0) = nan;
            end
        end
    end
end
