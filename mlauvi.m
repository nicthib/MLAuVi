function varargout = mlauvi(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @mlauvi_OpeningFcn, ...
    'gui_OutputFcn',  @mlauvi_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1}); gui_State.gui_Callback = str2func(varargin{1}); end
if nargout; [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:}); else; gui_mainfcn(gui_State, varargin{:}); end

function mlauvi_OpeningFcn(hO, ~, h, varargin)

% Addpath GUI folder
if ~contains(path,'mlauvi')
    addpath(genpath(uigetdir(cd,'Please navigate to the mlauvi directory.')));
end


% set ffmpeg path (for combining V/A)
try
    setenv('PATH', cell2mat(importdata('ffmpegpath.txt')))
    h.St.String = 'ffmpeg path set. Ready to load a dataset';
catch
    h.St.String = 'No ffmpeg path found in ffmpegpath.txt. Please update this file to add audio and video seamlessly.';
end

% Set up load pct multi slider
h.output = hO; h.framenum = 1; set(gcf, 'units','normalized','outerposition',[.2 .2 .85 .75]);
h.slider = superSlider(hO, 'numSlides', 2,'controlColor',[.94 .94 .94],... 
'position',[.14 .563 .1 .03],'stepSize',.3,'callback',@slider_Callback);
h.slider.UserData = [0 1;0 1];
h.slider.Children(2).Position(1) = .8125;
guidata(hO, h);

function varargout = mlauvi_OutputFcn(hO, ~, h)
varargout{1} = h.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LoadData_Callback(hO, ~, h)
[File,Path] = uigetfile('.mat','Please choose a data file');
load(fullfile(Path, File));
h.filename.String = strrep(File,'.mat',''); h.filenametext.String = h.filename.String;
ReqVars = {'H','W','im'};
for i = 1:numel(ReqVars)
    if exist('H') && exist ('W') && exist('m')
        h.H = H; h.W = W; h.m = m;
        h.m.ss = size(h.W);
        if numel(h.m.ss) ~= 3
            errordlg('Error: W is not 3D. Please make sure that W is a 3D matrix of N 2D images.')
            return
        else
            h.W = reshape(h.W,[prod(h.m.ss(1:2)) h.m.ss(3)]);
            h.St.String = 'Dataset loaded successfully';
        end
    else
        errordlg('Error loading file. Please make sure that the .mat file contains the following variables: H, W, m')
        return
    end
end

% set default values
h.m.Wshow = 1:size(h.H,1);
h.m.W_sf = ones(1,size(h.W,2));
h.m.clim = str2num(h.clim.String);
h.cmap = jet(size(h.H,1));
h.m.existneuralstream = 0;
h.m.vstart = 0;
h.m.vend = 1;
%h.m.keys = makekeys(h.scale.Value,h.scaletype.Value,numel(find(h.m.W_sf)),str2num(h.addoct.String));
h = assessFields(h);
UpdatePlots(h)
guidata(hO, h);

function ExportDynAud_Callback(hO, ~, h)
h.St.String = 'Writing DynAud file...'; drawnow
%midiout = matrix2midi_nic(h.Mfinal,300,[4,2,24,8],0);
%writemidi(midiout, h.filename.String);
if ~isempty(h.nd)
    nd_to_wav(h.filename.String,h.nd,h);
end
h.St.String = 'DynAud file written.';
h.combineAV.Enable = 'on';
guidata(hO,h)


function ExportAVI_Callback(hO, ~, h)
h.St.String = 'Writing AVI file...'; drawnow
fn = h.filename.String; 
sc = 256/h.m.clim(2);
Wtmp = h.W(:,h.m.Wshow); Htmp = h.H(h.m.Wshow,:);
cmaptmp = h.cmap(h.m.Wshow,:);
vidObj = VideoWriter([fn '.avi']);
vidObj.FrameRate = h.m.framerate; open(vidObj)
outinds = round(h.m.vstart*size(h.H,2))+1:round(h.m.vend*size(h.H,2));
for i = outinds
    im = reshape(Wtmp*diag(Htmp(:,i).*h.m.W_sf(h.m.Wshow)'-h.m.clim(1))*cmaptmp,[h.m.ss(1:2) 3]);
    im = uint8(im*sc);
    frame.cdata = im;
    frame.colormap = [];
    writeVideo(vidObj,frame);
    pct_updt = 10;
    if mod(i,pct_updt) == 1
        h.St.String = ['Writing AVI file... ' mat2str(round(i*100/numel(outinds))) '% done'];
        drawnow
    end
end
h.St.String = 'AVI file written';
close(vidObj);


function Wshow_Callback(hO, ~, h)
if strcmp(h.Wshow.String,'all')
    h.m.Wshow = 1:size(h.H,1);
else
    h.m.Wshow = str2num(h.Wshow.String);
end
h.UpdateH.BackgroundColor = [1 0 0];
UpdatePlots(h)
guidata(hO, h);

function framerate_Callback(hO, ~, h)
h.m.framerate = str2num(h.framerate.String);
h.UpdateH.BackgroundColor = [1 0 0];
h = assessFields(h);
guidata(hO, h);

function clim_Callback(hO, ~, h)
h.m.clim = str2num(h.clim.String);
UpdatePlots(h)
guidata(hO, h);

function thresh_Callback(hO, ~, h)
h.m.thresh = str2num(h.thresh.String);
h = assessFields(h);
h.UpdateH.BackgroundColor = [1 0 0];
guidata(hO, h);

function frameslider_Callback(hO, ~, h)
h.framenum = round(h.frameslider.Value*size(h.H,2));
h.frametxt.String = [mat2str(round(h.framenum*100/h.m.framerate)/100) ' sec'];
UpdatePlots(h)
guidata(hO, h);

function PlayVid_Callback(hO, ~, h)
while h.PlayVid.Value
    axes(h.axesWH);
    h.frameslider.Enable = 'off';
    sc = 256/h.m.clim(2);
    im = reshape(h.W(:,h.m.Wshow)*diag(h.H(h.m.Wshow,h.framenum).*h.m.W_sf(h.m.Wshow)'-h.m.clim(1))*h.cmap(h.m.Wshow,:),[h.m.ss(1:2) 3]);
    imagesc(uint8(sc*im))
    caxis(h.m.clim)
    axis equal
    axis off
    pause(.01)
    h.frametxt.String = [mat2str(round(h.framenum*100/h.m.framerate)/100) ' sec'];
    h.framenum = h.framenum + 1;
    h.frameslider.Value = h.framenum/size(h.H,2);
    axes(h.axesWH);

    if ~get(h.PlayVid, 'Value')
        break;
    end
    if h.framenum == size(h.H,2)
        h.PlayVid.Value = 0;
        h.frameslider.Value = 0;
    end
end
h.frameslider.Enable = 'on';
guidata(hO, h);


function UpdateH_Callback(hO, ~, h)
outinds = round(h.m.vstart*size(h.H,2))+1:round(h.m.vend*size(h.H,2));
tmp = zeros(1,size(h.H,1)); tmp(h.m.Wshow) = 1;

h.St.String = 'Updating H''...'; drawnow
[h.m.keys,keyrangegood] = makekeys(h.scale.Value,h.scaletype.Value,numel(find(h.m.W_sf & tmp)),str2num(h.addoct.String));
if ~keyrangegood
    h.St.String = 'ERROR: The number of components and note arrangement you have chosen is too broad. Please try using less components or a tighter note arrangement (e.g. scale)';
    return
end

%h.Mfinal = H_to_MIDI(h.H(find(h.m.W_sf & tmp),outinds),h.m.framerate,h.m.thresh,h.m.keys);

[h.Mfinal,h.nd] = H_to_nd(h.H(find(h.m.W_sf & tmp),outinds),h.m.framerate,h.m.thresh,h.m.keys);
h.M.notestart = h.Mfinal(:,5);
h.M.noteend = h.Mfinal(:,6);
h.M.notemag = h.Mfinal(:,4);
h.M.notekey = h.Mfinal(:,3);

guidata(hO, h);
h.UpdateH.BackgroundColor = [.94 .94 .94];
UpdatePlots(h)
h.St.String = 'H'' updated.';

function h = assessFields(h)
fields = {'framerate','clim','thresh'};
fieldsgood = zeros(size(fields));
for i = 1:numel(fields)
    if isfield(h.m,fields{i})
        h.(fields{i}).String = mat2str(h.m.(fields{i}));
        h.(fields{i}).BackgroundColor = [.94 .94 .94];
        fieldsgood(i) = 1;
    elseif ~isempty(h.(fields{i}).String)
        h.m.(fields{i}) = str2num(h.(fields{i}).String);
        h.(fields{i}).BackgroundColor = [.94 .94 .94];
        fieldsgood(i) = 1;
    else
        h.(fields{i}).BackgroundColor = [1 .3 .3];
        fieldsgood(i) = 0;
    end
end

if sum(fieldsgood) == numel(fieldsgood)
    h.bs = 'on';
else
    h.bs = 'off';
end

set(h.ExportDynAud,'enable',h.bs)
set(h.ExportAVI,'enable',h.bs)
set(h.ExportStream,'enable',h.bs)
set(h.UpdateH,'enable',h.bs)
set(h.Wshow,'enable',h.bs)
set(h.frameslider,'enable',h.bs)
UpdatePlots(h)

function W_sf_Callback(hO, ~, h)
if h.W_sf.Value
    h.m.W_sf = imbinarize(sum(h.W,1)/max(sum(h.W,1)),.1);
else
    h.m.W_sf = ones(1,size(h.W,2));
end
UpdatePlots(h)
h.UpdateH.BackgroundColor = [1 0 0];
guidata(hO, h);

function ExportStream_Callback(hO, ~, h)
h.St.String = 'Writing audio stream...'; drawnow
outinds = round(h.m.vstart*size(h.H,2))+1:round(h.m.vend*size(h.H,2));
tmp = zeros(1,size(h.H,1)); tmp(h.m.Wshow) = 1;
out = NeuralStream(h.H(h.m.W_sf & tmp,outinds),h.m,h.m.keys,h.filename.String);
if ~out
    h.St.String = 'ERROR: The number of components and note arrangement you have chosen is too broad. Please try using less components or a tighter note arrangement (e.g. scale)';
    return
end
h.m.existneuralstream = 1;
h.combineAV.Enable = 'on';
h.St.String = 'Audio stream written.';
guidata(hO, h);

function editcmap_Callback(hO, ~, h)
editcmap(hO,h);  
guidata(hO,h);

function slider_Callback(hO, ~)
h = guidata(hO);
h.m.vstart = round(1000*h.slider.Children(1).Position(1)/.625)/1000;
h.m.vend = round(1000*(h.slider.Children(2).Position(1)-.1875)/.625)/1000;
h.vs_str.String = mat2str(h.m.vstart*100);
h.ve_str.String = mat2str(h.m.vend*100);
drawnow
guidata(hO,h);

function vs_str_Callback(hO, ~, h)
h.m.vstart = str2num(h.vs_str.String)/100;
h.slider.Children(1).Position(1) = h.m.vstart * .625;
guidata(hO,h);

function ve_str_Callback(hO, ~, h)
h.m.vend = str2num(h.ve_str.String)/100;
h.slider.Children(2).Position(1) = h.m.vend * .625 + .1875;
guidata(hO,h);

function combineAV_Callback(hO, ~, h)
fn = h.filename.String; 

system(['ffmpeg -loglevel panic -i ' fn '.avi -i ' fn '.wav -codec copy -shortest ' fn '_audio.avi -y']);
if exist([fn '_audio.avi'])
    h.St.String = 'AVI w/ audio successfully written.';
else
    h.St.String = 'AVI w/ audio was unable to be written. Check to make sure you have the proper path to ffmpeg.exe in the ffmpegpath.txt file.';
end

function targ = vF(targ) % visibility toggle
if targ.Visible == 'on'
    targ.Visible = 'off';
else
    targ.Visible = 'on';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function framerate_CreateFcn(hO, ~, h)
function Wshow_CreateFcn(hO, ~, h)
function thresh_CreateFcn(hO, ~, h)
function clim_CreateFcn(hO, ~, h)
function frameslider_CreateFcn(hO, ~, h)
function scale_CreateFcn(hO, ~, h)
function scale_Callback(hO, ~, h)
function filename_Callback(hO, ~, h)
function filename_CreateFcn(hO, ~, h)
function scaletype_Callback(hO, ~, h)
function scaletype_CreateFcn(hO, ~, h)
function addoct_Callback(hO, ~, h)
function addoct_CreateFcn(hO, ~, h)
function ve_str_CreateFcn(hO, ~, h)
function vs_str_CreateFcn(hO, ~, h)
