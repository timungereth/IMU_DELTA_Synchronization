% code is from here:
% https://ch.mathworks.com/matlabcentral/fileexchange/28512-simplecolordetectionbyhue?s_tid=srchtitle
% might be better solution:
% https://ch.mathworks.com/matlabcentral/fileexchange/26420-simplecolordetection
% Demo to track green color.  Finds and annotates centroid and bounding box of green blobs.
% Modify thresholds to detect different colors.

clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
imtool close all;  % Close all imtool figures if you have the Image Processing Toolbox.
clear;  % Erase all existing variables. Or clearvars if you want.
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 10;


fullFileName = 'F:\DELTA_data\Patients\P06\cams\Gopro1\merged\crop.mp4';
%fullFileName = 'C:\Users\Tim\PycharmProjects\GetHSVvalues\P06_crop_short.mp4';

videoObject = VideoReader(fullFileName);

% Setup other parameters
numberOfFrames = videoObject.NumberOfFrame;
res1.FrameRate  = videoObject.FrameRate;


% get thresholds from python script!! 
hThresholds = [0, 1];
sThresholds = [50/255, 115/255];
vThresholds = [255, 255];

%%
% toggle plots
p = 0;
d = 0;	
% Read one frame at a time, and find specified color.
int = 1:numberOfFrames;
iin = 1:length(int);
tic;
if ~p, f = waitbar(0, 'Starting'); end
 for i = iin 
    if ~p, waitbar(i/length(int), f, sprintf('Progress: %d %%', floor(i/length(int)*100))); end
    %waitbar(i/numberOfFrames, f, sprintf('Progress: %d %%', floor(i/length(int)*100)));
    k = int(i);
    res(i).number = i;
    res(i).frame  = k;
    res(i).time   = i*1/res1.FrameRate;     
    
	% Read one frame
	rgb=read(videoObject,k);
    
	hsv = rgb2hsv(double(rgb));
	hue=hsv(:,:,1);
	sat=hsv(:,:,2);
	val=hsv(:,:,3);

   
	binaryH = (hue >= hThresholds(1) & hue <= hThresholds(2));% | (hue >= 0.98 & hue <= 1);
	binaryS = sat >= sThresholds(1) & sat <= sThresholds(2);
	binaryV = val >= vThresholds(1) & val <= vThresholds(2);
    

	
	% Overall color mask is the AND of all the masks.
	coloredMask = binaryH & binaryS & binaryV; % tim this is where detection mainly happens 
	% Filter out small blobs.
	coloredMask = bwareaopen(coloredMask, 200); % out tim to test
	% Fill holes
    coloredMask = imfill(coloredMask, 'holes');

    
	[labeledImage, numberOfRegions] = bwlabel(coloredMask);
    res(i).blobs = numberOfRegions > 0; % > 0 von tim 
    
end
close(f)
msgbox('Done with analysis.');
save res res
toc;
%% starts
% starts defined by red bright color
load res
blobs = [res.blobs];
sp = logical([zeros(1,10) ones(1,10)]); % 10->5
starts = strfind(blobs, sp)+10; % +10 is to correct for the leading zeros

st = logical([ones(1,10) zeros(1,10)]);
stops = strfind(blobs, st) -10 ;
%%
res1.duration = ( (stops-starts(1:length(stops)))*1/res1.FrameRate )';


%%
%res1.duration = ( (stops-starts(1:120))*1/res1.FrameRate )'; % take out hack because video (almost) ends with led on 
save res1 res1






