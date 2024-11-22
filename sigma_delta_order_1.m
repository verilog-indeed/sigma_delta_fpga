%------First order Sigma-Delta modulator------%
%based on the block diagram found in Oppenheim

%imports
pkg load signal

%function declaration
freq_sig = 100;
f = @(t) 0.5 + 0.5*cos(2*pi*freq_sig*t);

%parameters
fs = freq_sig * 2;
N = 1; %adc bits
M = 32; % oversample ratio (fs multiplier)
Vmin = -1; %dac low and max values
Vmax = 1;
deltaV = (Vmax - Vmin) / 2^N; %adc voltage step

%signals
duration = 10 * (1/freq_sig); %10 periods
sample_count = M * fs / duration;
t = linspace(0, duration, sample_count);
x = f(t);
y = zeros(1, sample_count);
x_digital = zeros(1, sample_count);
s = zeros(1, sample_count); % integrator output history (x_digit before decimation)

%STF = 1
for i=2:sample_count
  %difference (comparator)
  y(i) = x(i) - y(i-1);

  %accumulate (integrator)
  s(i) = y(i) + s(i-1);

  %quantize (round to 2^N)
  y(i) = round(s(i) / deltaV);
  y(i) = min(max(y(i), 0), 2^N - 1); %range correction
  err = y(i) - s(i)/deltaV;
end

figure(1);
subplot(3, 1, 1);
plot(t, x);
%figure(2);
subplot(3, 1, 2);
plot(t, y);

%Low-pass with cut off at fc=fs/2
[b, a] = butter(6,  1 / (2 * M), 'low');
x_digital = filter(b, a, y);
%decimate
x_digital = downsample(x_digital, M);
t = downsample(t, M);
subplot(3, 1, 3);
plot(t, x_digital);

%FFT plot
f = linspace(0, (fs * M) / 2, sample_count);
y_f = fft(y) / sample_count;
figure(2);
semilogx(f, abs(y_f));
