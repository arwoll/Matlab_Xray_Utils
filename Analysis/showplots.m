function varargout = showplots(varargin)
% SHOWPLOTS M-file for showplots.fig
%
%      function varargout = showplots(x,y, bkgd) 
%           is a matlab GUI-style function designed for interactive
%           inspection of a series of x vs. y fits. It displays x vs y (as
%           open circles) and x vs bkgd (as a solid red line). Different
%           colums 1..M are accessed via a slider.
%
%        A minimum of 3 input arguments are required:
%           x : a Nx1 vector   
%           y, bkgd : a NxM matrices
%
%           An optional (double) Mx1 fourth input argument "chi" provides
%           labels for each plot. (these are interpreted as the sum of
%           the squared differences between data and model).
%
%           If the fifth argument, 'marks', is provided, then the 6th
%           argument should be an Mx1 vector of doubles corresponding to
%           signficant positions on each plot, e.g. the position of the
%           centroid determined by a fit. This position is plotted as a
%           dashed line.
%
%           is d
%
%      SHOWPLOTS, by itself, creates a new SHOWPLOTS or raises the existing
%      singleton*.
%
%      H = SHOWPLOTS returns the handle to a new SHOWPLOTS or the handle to
%      the existing singleton*.
%
%      SHOWPLOTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SHOWPLOTS.M with the given input arguments.
%
%      SHOWPLOTS('Property','Value',...) creates a new SHOWPLOTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before showplots_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to showplots_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help showplots

% Last Modified by GUIDE v2.5 17-Apr-2006 14:43:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @showplots_OpeningFcn, ...
                   'gui_OutputFcn',  @showplots_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

%gui_State

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before showplots is made visible.
function showplots_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to showplots (see VARARGIN)

% Choose default command line output for showplots
handles.output = hObject;

nvargin = length(varargin);
if nvargin < 3
    errordlg('Oops, showplots must be called with at least three arguments', 'showplots');
end

handles.x = varargin{1};
handles.y = varargin{2};
handles.comp = varargin{3};

if nvargin >= 4
    handles.chi = varargin{4};
else
    handles.chi = [];
end

if nvargin == 6 && strcmp(varargin{5},'marks')
    handles.marks = varargin{6};
else
    handles.marks = [];
end

nplots = size(handles.y, 2);
if nplots == 1
    set(handles.plotselect, 'Visible', 'off');
else
    set(handles.plotselect,'Max', nplots);
    set(handles.plotselect,'Min', 1);
    minstep = 1/(nplots-1);
    set(handles.plotselect,'SliderStep', [minstep minstep*floor(nplots/2)]);
    set(handles.plotselect, 'Visible', 'on');
end
set(handles.plotselect, 'Value', 1);

% Update handles structure
guidata(hObject, handles);

set(handles.showfit, 'FontSize', 18);
%set((get(gca, 'Title')), 'FontSize', 18);
%set((get(gca, 'XLabel')), 'FontSize', 18);
%set((get(gca, 'YLabel')), 'FontSize', 18);


showplots('plotselect_Callback', hObject, eventdata, handles);

% UIWAIT makes showplots wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = showplots_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function plotselect_Callback(hObject, eventdata, handles)
% hObject    handle to plotselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

axes(handles.showfit);

checked = strcmp(get(handles.menu_options_log, 'Checked') , 'on');
if checked
    yscale = 'log';
else
    yscale = 'lin';
end
current = round(get(handles.plotselect, 'Value'));
plot(handles.x, handles.y(:,current), 'bo', handles.x, handles.comp(:, current), 'r-');
set(gca,'YScale', yscale);

a  = axis;
xpos = a(1)+.8*(a(2)-a(1));
ypos = a(3)+.5*(a(4)-a(3));
if ~isempty(handles.chi)
    %title(sprintf('Panel %d, {\\chi}^2 = %g', current, handles.chi(current)));
    text(xpos, ypos, sprintf('Panel %d\n{\\chi}^2 = %6.2g', ...
        current, handles.chi(current)));
end

if ~isempty(handles.marks)
    for k = 1:length(handles.marks)
        line([handles.marks(k) handles.marks(k)], [a(3) a(4)], 'LineStyle', '--');
    end
end


% --- Executes during object creation, after setting all properties.
function plotselect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plotselect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function menu_options_Callback(hObject, eventdata, handles)
% hObject    handle to menu_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_options_log_Callback(hObject, eventdata, handles)
% hObject    handle to menu_options_log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checked = strcmp(get(hObject, 'Checked') , 'on');
if checked
    set(hObject, 'Checked', 'off');
    set(handles.showfit, 'YScale', 'lin');
else
    set(hObject, 'Checked', 'on');
    set(handles.showfit, 'YScale', 'log');
end

