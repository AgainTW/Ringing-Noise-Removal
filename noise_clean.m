% parameter set
plot_flag1 = 0;
plot_flag2 = 0;
noiseGate_flag = 0;
filter_control = 1;

% load data
[y1,fs1] = audioread('singing16k16bit-clean.wav');
[y1s, ~]= size(y1);
s1 = spectrogram(y1, 256);

[y2,fs2] = audioread('singingWithPhoneRing16k16bit-noisy.wav');
[y2s, ~]= size(y2);
s2 = spectrogram(y2, 256);

% spectrogram compare
if plot_flag1==1
    tiledlayout(2,1);
    
    ax1 = nexttile;
    t1 = linspace(0, y1s/fs1, size(s1,1));
    f1 = linspace(0, fs1/2, size(s1,2));
    imagesc(t1, f1, 20*log10((abs(s1))));xlabel('Samples'); ylabel('Freqency');
    title('clean sound')
    colorbar;
    
    ax2 = nexttile;
    t2 = linspace(0, y2s/fs2, size(s2,1));
    f2 = linspace(0, fs2/2, size(s2,2));
    imagesc(t2, f2, 20*log10((abs(s2))));xlabel('Samples'); ylabel('Freqency');
    title('noise sound')
    colorbar;
end

% fft compare
if plot_flag2 == 1
    tiledlayout(2,1);
    
    m1 = length(y1);
    n1 = pow2(nextpow2(m1));
    y1_f = fft(y1,n1);
    f1 = (0:n1-1)*(fs1/n1)/10;
    power1 = abs(y1_f).^2/n1;
    
    m2 = length(y2);
    n2 = pow2(nextpow2(m2));
    y2_f = fft(y2,n2);
    f2 = (0:n2-1)*(fs2/n2)/10;
    power2 = abs(y2_f).^2/n2;
    
    ax1 = nexttile;
    plot(f1(1:floor(n1/2)),power1(1:floor(n1/2)))
    title('clean sound')
    xlabel('Frequency')
    ylabel('Power')
    
    ax2 = nexttile;
    plot(f2(1:floor(n2/2)),power2(1:floor(n1/2)))
    title('noise sound')
    xlabel('Frequency')
    ylabel('Power')
end

% Compressor design and show
dRCompressor = compressor('Threshold',-45,"Ratio",50,'SampleRate',fs1);
dRG = noiseGate('Threshold',-20,'SampleRate',fs1);
if noiseGate_flag==1
    visualize(dRCompressor)
    visualize(dRG)
end

% filter design,and apply Compressor and filter at the same time
% note：when apply filter, must be sure filter_control=1
if filter_control==0
    x = randn(20000,1);
else
    x = y2;
end
[y10,d10] = bandpass(x,[ 50 600],fs1,ImpulseResponse="iir",Steepness=0.8);
y10 = dRG(y10);
[y11,d11] = bandpass(x,[ 700 1100],fs1,ImpulseResponse="iir",Steepness=0.8);
[y12,d12] = bandpass(x,[2000 4000],fs1,ImpulseResponse="iir",Steepness=0.8);
y12 = dRCompressor(y12);
[y13,d13] = bandpass(x,[4300 5800],fs1,ImpulseResponse="iir",Steepness=0.8);
y13 = dRCompressor(y13);
[y14,d14] = bandpass(x,[6000 7500],fs1,ImpulseResponse="iir",Steepness=0.8);
y14 = dRCompressor(y14);

pspectrum([y10 y11 y12 y13 y14],fs1);
legend("Steepness = " + [0.8 0.8 0.8 0.8 0.8],Location="south");

% sound reconstruction
y2_denoise = y10 + y11 + y12 + y13 + y14;
[y3s, temp]= size(y2_denoise);

% denoise spectrogram
s3 = spectrogram(y2_denoise, 256);
t3 = linspace(0, y3s/fs2, size(s3,1));
f3 = linspace(0, fs2/2, size(s3,2));
imagesc(t3, f3, 20*log10((abs(s3))));xlabel('Samples'); ylabel('Freqency');
title('clean sound')
colorbar;

% save sound
audiowrite('C:\AG\課程講義\digtal signal porcessing\HW4\singing16k16bit-denoise.wav',y2_denoise,fs2);