function [audio, fs, durationInSeconds] = loadSongFile(filename,app)
    [audio, fs] = audioread(filename);
    durationInSeconds = length(audio) / fs;
end
