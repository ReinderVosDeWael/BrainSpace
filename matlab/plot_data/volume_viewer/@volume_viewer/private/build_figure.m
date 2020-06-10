%% Figure initialization. 
function varargout = build_figure(varargin)
% VIEWER MATLAB code for viewer.fig
%      VIEWER, by itself, creates a new VIEWER or raises the existing
%      singleton*.
%
%      H = VIEWER returns the handle to a new VIEWER or the handle to
%      the existing singleton*.
%
%      VIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEWER.M with the given input arguments.
%
%      VIEWER('Property','Value',...) creates a new VIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to viewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help viewer

% Last Modified by GUIDE v2.5 07-Apr-2020 11:42:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @viewer_OpeningFcn, ...
                   'gui_OutputFcn',  @viewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before viewer is made visible.
function viewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to viewer (see VARARGIN)
%
% RV: I've added the main figure generation here. Specifically, we grab the
% viewer.fig, modify the figure properties, insert the image data, modify
% the axis properties, and set listeners for mouse clicks and mouse
% scrolls. 

% Choose default command line output for viewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Grab the object. 
obj = varargin{1};
obj.handles = handles; 

% Modify some figure parameters. 
set(obj.handles.figure1                 , ...
    'Units'             , 'pixels'      , ... % Needed to detect cursor location. 
    'Name'              , 'BrainSpace Volume Viewer'); % Default name set to BrainSpace Volume Viewer.

% Initialize images. 
for ii = 1:3
    axes_name = ['axes' num2str(ii)];
    image_name = ['imagesc' num2str(ii)];
    
    % Plots the image and sets a callback for mouse clicks. 
    obj.handles.(image_name) = imagesc(obj.handles.(axes_name), ...
        obj.get_slice(ii,1), ...
        'ButtonDownFcn', @(~,evt) image_press_callback(evt,obj,ii));
 
    % Add a listener to always set missing data to transparant and trigger it. 
    addlistener(obj.handles.(image_name), 'CData', 'PostSet', ...
        @(~,evt)image_transparency(evt));
    obj.handles.(image_name).CData = obj.handles.(image_name).CData; % Trigger the listener.  
end

% Add colorbars.
obj.handles.image_colorbar = colorbar(obj.handles.axes1);
obj.handles.image_colorbar.Position = [.07 .3 .02 .4];
obj.handles.image_colorbar.FontSize = 16;

% Default color limits is 2.5th/97.5th percentile. Only set it here so the
% overlay colorbar string color is changed too. 
limits_image = vpa(prctile(obj.image(:),[2.5,97.5]),3);
obj.colorlimits(double(limits_image),'image');

% Initialize overlay.
for ii = 1:3
    axes_name = ['axes' num2str(ii+3)];
    if ~isempty(obj.overlay)
        image_name = ['imagesc' num2str(ii+3)];
        
        % Plots the image.
        obj.handles.(image_name) = imagesc(obj.handles.(axes_name), ...
            obj.get_slice(ii,2), ...
            'ButtonDownFcn', @(~,evt) image_press_callback(evt,obj,ii));
        
        % Add a listener to always set missing data to transparant and trigger it.
        addlistener(obj.handles.(image_name), 'CData', 'PostSet', ...
            @(~,evt)image_transparency(evt));
        obj.handles.(image_name).CData = obj.handles.(image_name).CData; % Trigger the listener.
        obj.handles.(axes_name).Visible = 'off';
        
        obj.handles.overlay_colorbar = colorbar(obj.handles.axes4);
        obj.handles.overlay_colorbar.Position = [.9 .3 .02 .4];
        obj.handles.overlay_colorbar.FontSize = 16;

        % Default colormap is autumn; could make it a property.
        obj.colormap(parula,'overlay');
        limits_overlay = vpa(prctile(obj.overlay(:),[2.5,97.5]),3);
        obj.colorlimits(double(limits_overlay),'overlay');
    else
        obj.handles.(axes_name).Visible = 'off';
    end
end

% Default colormap is gray. Could make it a property. 
obj.colormap(gray,'image')

% Set axes properties.
set([obj.handles.axes1,obj.handles.axes2,obj.handles.axes3, obj.handles.axes4,obj.handles.axes5,obj.handles.axes6], ...
    'DataAspectRatio'   , [1 1 1]           , ... % Square voxel sizes.
    'PlotBoxAspectRatio', [1 1 1]           , ... % Square plot boxes.
    'XTick'             , []                , ... % Remove tick marks
    'YTick'             , []                , ...
    'Units'             , 'pixels'          );    % Needed to detect cursor location.

% Do a replot to update the text.
obj.replot();

% Set listener for mouse scroll
set(obj.handles.figure1, 'WindowScrollWheelFcn',  ...
    @(~,evt)mouse_scroll_callback(evt,obj));

% Do not return user control until the figure is done drawing.
drawnow
end

% --- Outputs from this function are returned to the command line.
% RV: This is the default generated by GUIDE. I haven't touched it.
function varargout = viewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

%% Callbacks
function image_press_callback(evt,obj,idx)
% This callback executes when a the user clicks anywhere within one of the
% slices. It will move the point of focus to the clicked area. 

% Get mouse click coordinates. 
coord = round(evt.IntersectionPoint);

% Due to image rotation in get_slice, we have to invert the second coordinate. 
%coord([1,2]) = coord([2,1]);
if idx == 3 
    coord_max = size(obj.image,2);
else
    coord_max = size(obj.image,3);
end
coord(2) = coord_max-coord(2)+1; 

% Compute the new slices.
new_slices = [coord(1:idx-1),obj.slices(idx),coord(idx:2)]; % Change the slices, the clicked image remains on the same slice.

% Make sure the new slices are within bounds (1:size(image)).
new_slices = min(max([new_slices;1,1,1]),size(obj.image)); % Make sure the new slices don't round to just outside the image.

% Set the new slices. 
obj.slices = new_slices;
end

function mouse_scroll_callback(evt,obj)
% This callback executes whenever the user uses the mousewheel anywhere in
% the figure. If the mousewheel is hovering over an image, it will change
% the slice of that image. 

% Determine if mouse is hovering over an axis.
current_axis = overobj('Axes');
if isempty(current_axis)
    return
end
    
% Determine over which axis the cursor is hanging by equality of the axis
% positions.
for idx = 1:3
    axes_name = ['axes' num2str(idx)];
    if all(current_axis.Position == obj.handles.(axes_name).Position)
        break
    end
end

% Modify the slice number. Check whether the new slice is within bounds.
new_slice = obj.slices(idx) + evt.VerticalScrollCount;
if new_slice < 1 || new_slice > size(obj.image,idx)
    return
else
    obj.slices(idx) = new_slice;
end           
end

function image_transparency(evt)
% Sets missing data (=nan) to transparant when its CData is changed. 
evt.AffectedObject.AlphaData = ~isnan(evt.AffectedObject.CData);
end