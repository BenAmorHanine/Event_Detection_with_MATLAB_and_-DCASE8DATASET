% Load two audio files from your dataset
[y1, fs1] = audioread('test/section_00_0000.wav');
[y2, fs2] = audioread('test/section_00_0001.wav');

% Parameters for file 1
T1 = length(y1) / fs1;
t1 = 0:1/fs1:T1-1/fs1;

% Parameters for file 2
T2 = length(y2) / fs2;
t2 = 0:1/fs2:T2-1/fs2;

% Visualize both temporal signatures
figure;

subplot(2,1,1);
plot(t1, y1);
title(['Signal 1 - Fs = ', num2str(fs1), ' Hz, Duration = ', num2str(T1), ' s']);
xlabel('Time (s)');
ylabel('Amplitude');
grid on;

subplot(2,1,2);
plot(t2, y2);
title(['Signal 2 - Fs = ', num2str(fs2), ' Hz, Duration = ', num2str(T2), ' s']);
xlabel('Time (s)');
ylabel('Amplitude');
grid on;