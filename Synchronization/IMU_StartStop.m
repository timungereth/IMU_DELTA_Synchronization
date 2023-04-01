clear;

fn.imu = [pwd filesep 'IMU_PaulR'];
imuCsv = dir([fn.imu filesep '*.csv']);
%nl = {'WR', 'Box', 'C', 'WL', 'AL', 'Cup', 'AR'};
nl = {'AL', 'AR', 'Box', 'C', 'Cup','WL', 'WR'};
imu = struct;
for i = 1:length(imuCsv)
    imu(i).name = imuCsv(i).name(1:2);
    imu(i).Label = nl(i);
    I = readtable([imuCsv(i).folder filesep imuCsv(i).name]);
    imu(i).FrameRate = round( 1000/(mode(diff(I.SampleTimeFine))/1000) );
    imu(i).acc = [I.Acc_X I.Acc_Y I.Acc_Z];
    imu(i).gyr = [I.Gyr_X I.Gyr_Y I.Gyr_Z];
    imu(i).quat= [I.Quat_W I.Quat_X I.Quat_Y I.Quat_Z];
    ns(i)=length(I.Acc_X);
end

% calculate free acceleration    
% https://base.xsens.com/s/article/Calculating-Free-Acceleration?language=en_US
% https://base.xsens.com/s/article/DOT-Reference-frame-and-Data-types?language=en_US
% https://xsenstechnologies.force.com/knowledgebase/s/article/Transforming-MTi-data-from-local-frame-L-to-sensor-frame-S-1605869710122?language=en_US
% https://ch.mathworks.com/matlabcentral/answers/511409-rotate-acceleration-vector-using-rotation-matrix
%https://stackoverflow.com/questions/3377288/how-to-remove-gravity-factor-from-accelerometer-readings-in-android-3-axis-accel
for i = 1:length(imu)
    % quaternion to rotation matrix
    R = quat2rotm(imu(i).quat);
    acc = imu(i).acc;
    result = zeros(size(acc));
    for k=1:size(acc,1)
        % rotate accelration
        result(k,:) = R(:,:,k) * acc(k,:)';
    end
    % remove gravity
    imu(i).accFree = result - [0 0 9.81];
end

if 0
    % these plots show that gravity was removed correctly
    % because data are shown for the IMU on the sync box
    % which show gravity only in the z component of acc
    IMUId = 2;
    acc = imu(IMUId).acc;
    figure
    subplot(3,1,1)
    plot(acc)
    legend({'x', 'y', 'z'})
    title('acc in sensor frame')

    R = quat2rotm(imu(IMUId).quat);
    result = zeros(size(acc));
    for k=1:size(acc,1)
        % rotate accelration
        result(k,:) = R(:,:,k) * acc(k,:)';
    end
    subplot(3,1,2)
    plot(result)
    legend({'x', 'y', 'z'})
    title('acc in world frame')

    accFree = imu(IMUId).accFree;
    subplot(3,1,3)
    plot(accFree)
    legend({'x', 'y', 'z'})
    title('acc in world frame, gravity removed')
end

if 0
    figure
    c=0;
    for i = 1:length(imu)
        c=c+1;
        subplot(length(imu),2,c)
        plot(imu(i).accFree)
        ylim([-10 10])
        legend({'x', 'y', 'z'})
        title(['acc, ' imu(i).Label])

        c=c+1;
        subplot(length(imu),2,c)
        plot(imu(i).gyr)
        ylim([-50 50])
        legend({'x', 'y', 'z'})
        title(['gyr, ' imu(i).Label])
    end
end

%%
% threshold
b = vecnorm(imu(3).accFree , 2, 2);

n1 = 20;
n2 = 18;
xMax = movmax(b,[n1,n1]);
xMax = movmin(xMax,[n2,n2]);
plot(xMax,'r','LineWidth',1.1);

th = [xMax>1.5]';
sp = logical([zeros(1,30) ones(1,30)]);
starts = strfind(th, sp);
ep = logical([ ones(1,30) zeros(1,30)]);
starts = strfind(th, sp);
stops  = strfind(th, ep);

% remove trials with a larger index than 27, because data are not in video
%starts(28:end)=[];
%stops(28:end) =[];

duration = [(stops-starts)*1/imu(1).FrameRate]';

if 1
    figure
    plot(xMax), hold on
    plot(th)
    plot(starts, ones(size(starts)),'go')
    plot(stops , ones(size(stops)), 'ro')
    xlabel('Time [Frames]')
    ylabel('Acceleration magnitude')
    title('IMU on Sync Box')
end

% % envelope
% fl = 40;
%[up1,lo1] = envelope(b,fl,'peak');
% hold on
% plot(up1)
% 
% % mov avg
% % https://stackoverflow.com/questions/38301504/encase-signal-by-getting-the-upper-and-lower-envelope-in-matlab


%%
fn.imuTrials = [fn.imu filesep 'trials'];
if ~exist(fn.imuTrials, 'dir')
    mkdir(fn.imuTrials);
end

%% get timestamps from video and correct shift and factor 
load('timestamps_cam3_PaulR.mat')
starts_1 = int64(starts);
stops_1 = int64(stops);

diff = 8202;
factor = 120/119.88;
starts_1 = (starts_1 - diff)*factor;
stops_1 = (stops_1 - diff)*factor; 

starts = starts_1;
stops = stops_1; 

%%
for i = 1:length(starts)
    startF = starts(i);
    stopF  = stops(i);
    intF   = startF:stopF;    

    for m = 1:length(imu)
        lab   = imu(m).Label{:} ;
        if ~strcmp(lab, 'Box')
            T = table;
            T.time = [1:length(intF)]'.*1./imu(m).FrameRate;
            T.acc_x     = imu(m).acc(intF,1);
            T.acc_y     = imu(m).acc(intF,2);
            T.acc_z     = imu(m).acc(intF,3);
            T.gyr_x     = imu(m).gyr(intF,1);
            T.gyr_y     = imu(m).gyr(intF,2);
            T.gyr_z     = imu(m).gyr(intF,3);
            T.quat_w    = imu(m).quat(intF,1);
            T.quat_x    = imu(m).quat(intF,2);
            T.quat_y    = imu(m).quat(intF,3);
            T.quat_z    = imu(m).quat(intF,4);
            T.accFree_x = imu(m).accFree(intF,1);
            T.accFree_y = imu(m).accFree(intF,2);
            T.accFree_z = imu(m).accFree(intF,3);
            tname = [fn.imuTrials filesep 'trial_' num2str(i) '_' lab '.csv'];
            writetable(T, tname);
        end
    end
end
