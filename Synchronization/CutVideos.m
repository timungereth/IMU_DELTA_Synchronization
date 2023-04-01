if 1
    %fullVid  = 'C:\Users\Tim\Documents\CEFIR\Delta\Pilote_Healthy_JosefTimJiahiu\TIM2\Video\Merged\GX010021_joined.mp4';
    fullVid = 'F:\DELTA_data\Patients\P06\cams\Gopro3\merged\GX010029\GX010029_joined.mp4';

    folderTrials = 'F:\DELTA_data\Patients\P06\cams\Gopro3\trials';

    % cut video:
    vf = VideoReader(fullVid);
    %starts_corrected = [starts(1:98),starts(100:end)];
    %stops_corrected = [stops(1:97),254475,stops(99:end)];
    starts_corrected = starts;
    stops_corrected = stops;
%     stops_corrected(98)=237674;
%     stops_corrected(99) = 254475;
% 
% 
    start1_cam3 = 8567;
    start1_cam2 = 12919;
    start1_cam1 = 10494;
%     %% correct initial offset between camera frames 
     starts = starts_corrected + (start1_cam3-start1_cam1);
     stops = stops_corrected + (start1_cam3-start1_cam1);

    %%
    for i = 1:length(starts) %
        vo = VideoWriter([folderTrials filesep 'trial_' num2str(i)],'MPEG-4');
        vo.FrameRate = vf.FrameRate;
        open(vo)

        startF = starts(i);
        stopF  = stops(i);
        intF = startF:stopF;

        f = waitbar(0, 'Starting','Name',['trial' num2str(i)]);
        for ir = intF
            F = read(vf,ir);
            writeVideo(vo,F);
            waitbar((ir-startF)/length(intF), f, sprintf('Progress: %d %%', floor((ir-startF)/length(intF)*100)));
        end
        close(f)
        close(vo)
    end
    % video
end