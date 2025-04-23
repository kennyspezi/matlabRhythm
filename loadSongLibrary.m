function songLibrary = loadSongLibrary(app)
%UNTITLED2 Summary of this function goes here

  if isfile('songLibrary.csv')
        songLibrary = readtable('songLibrary.csv');
    else
        songLibrary = table();
        uialert(app.UIFigure, 'No songLibrary.csv found', 'Warning');
    end
end