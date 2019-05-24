function out = NeuralStream(H,m,keys,filename)
freqs = csvread('PianoFreqs.csv');
H(H<0) = 0;
movielength = size(H,2)/m.framerate;
fs = 8192*2;  % sampling frequency
t1 = linspace(0,movielength,size(H,2));
t2 = 0:1/fs:movielength;
if keys(end) > 87
    out = 0;
    return
else
    out = 1;
end
for i = 1:size(H,1)
    a(i,:) = sin(2*pi*freqs(keys(i)+1)*t2);
    Hrs(i,:) = interp1(t1,H(i,:),t2);
end
song = sum(a.*Hrs,1);
song = song*.8/max(song);
audiowrite([filename '.wav'],song,fs);
