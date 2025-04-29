classdef thegame < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        TabGroup                       matlab.ui.container.TabGroup
        Welcome                        matlab.ui.container.Tab
        GridLayout3                    matlab.ui.container.GridLayout
        HTPButton                      matlab.ui.control.Image
        StartButtonIMG                 matlab.ui.control.Image
        Image                          matlab.ui.control.Image
        SongSelector                   matlab.ui.container.Tab
        AvailableBeatmapsListBox       matlab.ui.control.ListBox
        AvailableBeatmapsListBoxLabel  matlab.ui.control.Label
        Switch                         matlab.ui.control.RockerSwitch
        BeatmapLabel                   matlab.ui.control.Label
        DifficultyDropDown             matlab.ui.control.DropDown
        DifficultyDropDownLabel        matlab.ui.control.Label
        SongDropDown                   matlab.ui.control.DropDown
        SongDropDownLabel              matlab.ui.control.Label
        GameStartButton                matlab.ui.control.Button
        Image3                         matlab.ui.control.Image
        Image4                         matlab.ui.control.Image
        Game                           matlab.ui.container.Tab
        GridLayout2                    matlab.ui.container.GridLayout
        LLabel                         matlab.ui.control.Label
        KLabel                         matlab.ui.control.Label
        JLabel                         matlab.ui.control.Label
        DLabel                         matlab.ui.control.Label
        SLabel                         matlab.ui.control.Label
        ALabel                         matlab.ui.control.Label
        HitLabel                       matlab.ui.control.Label
        StopButton                     matlab.ui.control.Button
        LampK                          matlab.ui.control.Lamp
        LampL                          matlab.ui.control.Lamp
        LampJ                          matlab.ui.control.Lamp
        LampD                          matlab.ui.control.Lamp
        LampS                          matlab.ui.control.Lamp
        LampA                          matlab.ui.control.Lamp
        TimerLabel                     matlab.ui.control.Label
        CountDown                      matlab.ui.control.Label
        GamingButton                   matlab.ui.control.Button
        BeatTable                      matlab.ui.control.Table
        Image2                         matlab.ui.control.Image
        Finish                         matlab.ui.container.Tab
        BackButton                     matlab.ui.control.Button
        HowToPlay                      matlab.ui.container.Tab
    end


    properties (Access = public)
    SongLibrary
    Song
    SongDuration
    RecordedBeats
    Beatmaps
    SelectedBeatmap
end
    
    properties (Access = private)
    introPlayer % audioplayer object

   
    Songs
    RecordingStartTime
    
    ActiveKeys
    Timer
    Player
    Mode
    IsListening logical = false;
    Beatmap
    NextBeatIndex
    
    
    

    % NEW for falling notes:
    ActiveNotes = struct('KeyIndex', {}, 'SpawnTime', {}, 'UIObject', {}); % falling notes
    NoteSpeed = 400; % pixels per second falling speed
    SpawnedBeats
   end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            loaderHelpers.writeSongLibrary();
            app.TabGroup.TabLocation = "bottom";
            app.TabGroup.SelectedTab = app.Welcome;
            app.DifficultyDropDown.Visible = true;
            app.DifficultyDropDownLabel.Visible = true;
            app.SongDropDown.Visible = true;
            app.SongDropDownLabel.Visible = true;
            app.GameStartButton.Visible = false;
            app.BeatmapLabel.Visible = false;
            app.CountDown.Visible = "off";
            app.StopButton.Visible = "off";
            app.Mode = "Play";
            app.UIFigure.WindowKeyPressFcn = @(src,evt) keyInputHelpers.onKeyPress(app, evt);
            app.UIFigure.WindowKeyReleaseFcn = @(src,evt) keyInputHelpers.onKeyRelease(app, evt);
            app.ActiveKeys = containers.Map('KeyType','char','ValueType','double');

            [y, Fs] = audioread('intro_song.mp3');
            app.introPlayer = audioplayer(y, Fs);
            play(app.introPlayer);
        % New function: clears all beatmap-related state
        end

        % Callback function
        function StartButtonPushed(app, event)
            % opts = detectImportOptions('songLibrary.csv');
            % opts = setvartype(opts, {'Beatmap','TrackFile'}, 'string');
            % app.SongLibrary = readtable('songLibrary.csv', opts);
            % app.SongDropDown.Items = unique(app.SongLibrary.Song);
            % app.DifficultyDropDown.Value = "Easy";
            % app.DifficultyDropDownValueChanged(event);
            % app.Switch.Value = "Play";
            % app.SwitchValueChanged(event);
            % app.SongDropDownValueChanged(event);
            % app.TabGroup.SelectedTab = app.SongSelector;
        end

        % Value changed function: SongDropDown
        function SongDropDownValueChanged(app, event)
        app.Song = app.SongDropDown.Value;

        [beatmaps, beatmapDisplayNames, hasBeatmap] = songHelpers.getAvailableBeatmaps(app.SongLibrary, app.Song);


        GUIhelpers.updateSongSelectionUI(app, beatmaps, beatmapDisplayNames, hasBeatmap, app.Song);


        end

        % Button pushed function: GameStartButton
        function GameStartButtonPushed(app, event)
          if app.Mode == "Record"
                app.GamingButton.Text = "Start Recording";
                app.Game.BackgroundColor = "red";
                app.TabGroup.SelectedTab = app.Game;

            elseif app.Mode == "Play"
            % start regular gameplay mode (later)
                app.GamingButton.Text = "Let's Play!";
                app.Game.BackgroundColor = "blue";
                app.TabGroup.SelectedTab = app.Game;

            end
            stop(app.introPlayer);
   
        

        end

        % Button pushed function: GamingButton
        function GamingButtonPushed(app, event)
     disp("===== GamingButtonPushed called; Mode = " + app.Mode)

    songRow = strcmp(app.SongLibrary.Song, app.Song);

    if isempty(find(songRow,1))
        uialert(app.UIFigure, 'No song selected properly!', 'Error');
        return;
    end

    filepath = app.SongLibrary.TrackFile{find(songRow,1)};

    disp(['[DEBUG] filepath = "', filepath, '"']);
    disp(['[DEBUG] class   = ', class(filepath)]);
    disp(['[DEBUG] exists? = ', num2str(isfile(filepath))]);

    if ~isfile(filepath)
        uialert(app.UIFigure, sprintf('Cannot find audio file:\n%s', filepath), 'File Error');
        return;
    end

    % Load the song
    [audio, fs, dur] = loaderHelpers.loadSongFile(filepath, app);
    app.SongDuration = dur;  

    switch app.Mode
        case "Record"
            SetUpHelpers.recordingModeOn(app);
        case "Play"
            SetUpHelpers.gameplayModeOn(app);
    end

    % Hide the Gaming button
    app.GamingButton.Visible = "off";
    app.CountDown.Visible = "on";

    % --- Countdown --- %
    for count = 3:-1:1
        app.CountDown.Text = sprintf('%d...', count);
        pause(1);
    end
    app.CountDown.Text = "Go!";
    pause(1); % Small pause after "Go!" to sync better

    app.CountDown.Visible = "off";
    app.IsListening = true;

    % --- Now start the song and timer --- %
    app.Player = audioplayer(audio, fs);
    play(app.Player);

    app.RecordingStartTime = tic; % <-- MOVED here after playing!

    app.Timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.1, ...
                      'TimerFcn', @(~,~) updateTime(app));
    start(app.Timer);

    app.StopButton.Visible = "on";



        end

        % Value changed function: DifficultyDropDown
        function DifficultyDropDownValueChanged(app, event)
      selDiff = app.DifficultyDropDown.Value;
      selSong = app.SongDropDown.Value;

    % Filter the SongLibrary for matching Song and Difficulty
    matchRows = app.SongLibrary( ...
        strcmp(app.SongLibrary.Song, selSong) & ...
        strcmp(app.SongLibrary.Difficulty, selDiff), :);

    % Get the matching beatmaps
    beatmapList = matchRows.Beatmap;

    % Update the ListBox
    if isempty(beatmapList)
        app.DifficultyDropDown.Visible = "on";
app.AvailableBeatmapsListBox.Items = "(No Beatmaps Available)";

    else
        app.DifficultyDropDown.Visible = "on";
        app.AvailableBeatmapsListBox.Items = beatmapList;
    end
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            if isvalid(app.Timer)
                stop(app.Timer);
            end
            if isvalid(app.Player)
                stop(app.Player);
            end
            app.IsListening = false;

            app.TabGroup.SelectedTab = app.Finish;

            % Check properly if the Mode is "Record"
            switch(app.Mode)
                case "Record"
                    % RECORDING MODE: export beatmap (this will ask name)
                    exportBeatmap(app);
            end
        end

        % Value changed function: Switch
        function SwitchValueChanged(app, event)
       
    app.Mode = strtrim(app.Switch.Value);  % Remove accidental spaces
    app.SongDropDownValueChanged(event);

    % Hide both images before showing one
    app.Image3.Visible = false;
    app.Image4.Visible = false;

    switch app.Mode
        case "Record"
            app.Image3.Visible = true;
            uistack(app.Image3, 'bottom');
            app.GameStartButton.Text = "Let's Record!";
            app.GameStartButton.Visible = "on";

        case "Play"
            app.Image4.Visible = true;
            uistack(app.Image4, 'bottom');
            app.GameStartButton.Text = "Game Start!";
            app.GameStartButton.Visible = "on";
    end


        end

        % Value changed function: AvailableBeatmapsListBox
        function AvailableBeatmapsListBoxValueChanged(app, event)
     selectedDisplayName = app.AvailableBeatmapsListBox.Value;

    % Match against ALL beatmaps (don't just filter by song title)
    allBeatmaps = app.SongLibrary.Beatmap;
    allSongs = app.SongLibrary.Song;

    % Build display names like you did in the ListBox
    displayNames = erase(allBeatmaps, '_beatmap.csv');

    % Find the index where the display name matches the selected item
    idx = find(strcmp(displayNames, selectedDisplayName), 1);

    if ~isempty(idx)
        % Safely assign the beatmap
        app.Beatmap = allBeatmaps(idx);
    else
        warning('No matching beatmap found for the selected item.');
    end

        end

        % Button pushed function: BackButton
        function BackButtonPushed(app, event)
            app.TabGroup.SelectedTab = app.SongSelector;
        end

        % Image clicked function: StartButtonIMG
        function StartButtonIMGImageClicked(app, event)
           opts = detectImportOptions('songLibrary.csv');
            opts = setvartype(opts, {'Beatmap','TrackFile'}, 'string');
            app.SongLibrary = readtable('songLibrary.csv', opts);
            app.SongDropDown.Items = unique(app.SongLibrary.Song);
            app.DifficultyDropDown.Value = "Easy";
            app.DifficultyDropDownValueChanged(event);
            app.Switch.Value = "Play";
            app.SwitchValueChanged(event);
            app.SongDropDownValueChanged(event);
            app.TabGroup.SelectedTab = app.SongSelector;  
        end

        % Image clicked function: HTPButton
        function HTPButtonImageClicked(app, event)
            app.TabGroup.SelectedTab = app.HowToPlay;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {'1x'};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % Create Welcome
            app.Welcome = uitab(app.TabGroup);
            app.Welcome.Title = 'Tab';

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.Welcome);
            app.GridLayout3.ColumnWidth = {'14x', '30x', '30x', '30x', '14x'};
            app.GridLayout3.RowHeight = {'30x', '20x', '20x', '15x', '15x', '20x', '30x'};
            app.GridLayout3.ColumnSpacing = 0;
            app.GridLayout3.RowSpacing = 0;
            app.GridLayout3.Padding = [0 0 0 0];

            % Create Image
            app.Image = uiimage(app.GridLayout3);
            app.Image.ScaleMethod = 'fill';
            app.Image.Layout.Row = [1 7];
            app.Image.Layout.Column = [1 5];
            app.Image.ImageSource = 'bg.png';

            % Create StartButtonIMG
            app.StartButtonIMG = uiimage(app.GridLayout3);
            app.StartButtonIMG.ScaleMethod = 'fill';
            app.StartButtonIMG.ImageClickedFcn = createCallbackFcn(app, @StartButtonIMGImageClicked, true);
            app.StartButtonIMG.Layout.Row = 6;
            app.StartButtonIMG.Layout.Column = 2;
            app.StartButtonIMG.ImageSource = fullfile(pathToMLAPP, 'start.png');

            % Create HTPButton
            app.HTPButton = uiimage(app.GridLayout3);
            app.HTPButton.ScaleMethod = 'fill';
            app.HTPButton.ImageClickedFcn = createCallbackFcn(app, @HTPButtonImageClicked, true);
            app.HTPButton.Layout.Row = 6;
            app.HTPButton.Layout.Column = 4;
            app.HTPButton.ImageSource = fullfile(pathToMLAPP, 'how to play button.png');

            % Create SongSelector
            app.SongSelector = uitab(app.TabGroup);
            app.SongSelector.Title = 'Tab2';
            app.SongSelector.BackgroundColor = [1 1 1];

            % Create Image4
            app.Image4 = uiimage(app.SongSelector);
            app.Image4.ScaleMethod = 'fill';
            app.Image4.Visible = 'off';
            app.Image4.Position = [2 1 619 436];
            app.Image4.ImageSource = fullfile(pathToMLAPP, 'playbg.png');

            % Create Image3
            app.Image3 = uiimage(app.SongSelector);
            app.Image3.ScaleMethod = 'fill';
            app.Image3.Visible = 'off';
            app.Image3.Position = [2 1 619 436];
            app.Image3.ImageSource = fullfile(pathToMLAPP, 'recordbg.png');

            % Create GameStartButton
            app.GameStartButton = uibutton(app.SongSelector, 'push');
            app.GameStartButton.ButtonPushedFcn = createCallbackFcn(app, @GameStartButtonPushed, true);
            app.GameStartButton.Position = [69 114 100 23];
            app.GameStartButton.Text = 'Game Start!';

            % Create SongDropDownLabel
            app.SongDropDownLabel = uilabel(app.SongSelector);
            app.SongDropDownLabel.HorizontalAlignment = 'right';
            app.SongDropDownLabel.FontWeight = 'bold';
            app.SongDropDownLabel.FontColor = [1 1 1];
            app.SongDropDownLabel.Position = [137 255 35 22];
            app.SongDropDownLabel.Text = 'Song';

            % Create SongDropDown
            app.SongDropDown = uidropdown(app.SongSelector);
            app.SongDropDown.Items = {'Loading...'};
            app.SongDropDown.ValueChangedFcn = createCallbackFcn(app, @SongDropDownValueChanged, true);
            app.SongDropDown.Position = [187 255 100 22];
            app.SongDropDown.Value = 'Loading...';

            % Create DifficultyDropDownLabel
            app.DifficultyDropDownLabel = uilabel(app.SongSelector);
            app.DifficultyDropDownLabel.HorizontalAlignment = 'right';
            app.DifficultyDropDownLabel.FontWeight = 'bold';
            app.DifficultyDropDownLabel.FontColor = [1 1 1];
            app.DifficultyDropDownLabel.Position = [116 219 56 22];
            app.DifficultyDropDownLabel.Text = 'Difficulty';

            % Create DifficultyDropDown
            app.DifficultyDropDown = uidropdown(app.SongSelector);
            app.DifficultyDropDown.Items = {'Easy', 'Medium', 'Hard'};
            app.DifficultyDropDown.ValueChangedFcn = createCallbackFcn(app, @DifficultyDropDownValueChanged, true);
            app.DifficultyDropDown.Placeholder = '""';
            app.DifficultyDropDown.Position = [187 219 100 22];
            app.DifficultyDropDown.Value = 'Easy';

            % Create BeatmapLabel
            app.BeatmapLabel = uilabel(app.SongSelector);
            app.BeatmapLabel.FontColor = [1 1 1];
            app.BeatmapLabel.Visible = 'off';
            app.BeatmapLabel.Position = [69 144 479 30];
            app.BeatmapLabel.Text = 'There is no beatmap. Try recording one!';

            % Create Switch
            app.Switch = uiswitch(app.SongSelector, 'rocker');
            app.Switch.Items = {' Record', 'Play'};
            app.Switch.Orientation = 'horizontal';
            app.Switch.ValueChangedFcn = createCallbackFcn(app, @SwitchValueChanged, true);
            app.Switch.FontName = 'tdkalayal';
            app.Switch.FontSize = 36;
            app.Switch.FontColor = [1 1 1];
            app.Switch.Position = [271 359 128 57];
            app.Switch.Value = ' Record';

            % Create AvailableBeatmapsListBoxLabel
            app.AvailableBeatmapsListBoxLabel = uilabel(app.SongSelector);
            app.AvailableBeatmapsListBoxLabel.HorizontalAlignment = 'right';
            app.AvailableBeatmapsListBoxLabel.FontWeight = 'bold';
            app.AvailableBeatmapsListBoxLabel.FontColor = [1 1 1];
            app.AvailableBeatmapsListBoxLabel.Position = [304 267 121 22];
            app.AvailableBeatmapsListBoxLabel.Text = 'Available  Beatmaps';

            % Create AvailableBeatmapsListBox
            app.AvailableBeatmapsListBox = uilistbox(app.SongSelector);
            app.AvailableBeatmapsListBox.ValueChangedFcn = createCallbackFcn(app, @AvailableBeatmapsListBoxValueChanged, true);
            app.AvailableBeatmapsListBox.Position = [440 136 159 155];

            % Create Game
            app.Game = uitab(app.TabGroup);

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.Game);
            app.GridLayout2.ColumnWidth = {'1x', '1x', '1x', 33, 34, 33, '1.02x', '1x', '1x'};
            app.GridLayout2.RowHeight = {'1x', 22, '1x', '1x', '1x', '1x', '1x', 23, '1.27x'};

            % Create Image2
            app.Image2 = uiimage(app.GridLayout2);
            app.Image2.ScaleMethod = 'fill';
            app.Image2.Layout.Row = [1 9];
            app.Image2.Layout.Column = [1 9];
            app.Image2.ImageSource = fullfile(pathToMLAPP, 'bgstart.png');

            % Create BeatTable
            app.BeatTable = uitable(app.GridLayout2);
            app.BeatTable.BackgroundColor = [0.302 0.7451 0.9333;0.102 0.7294 0.7294];
            app.BeatTable.ColumnName = {'A'; 'S'; 'D'; 'J'; 'K'; 'L'; 'Time'};
            app.BeatTable.RowName = {};
            app.BeatTable.Layout.Row = [2 6];
            app.BeatTable.Layout.Column = [1 9];

            % Create GamingButton
            app.GamingButton = uibutton(app.GridLayout2, 'push');
            app.GamingButton.ButtonPushedFcn = createCallbackFcn(app, @GamingButtonPushed, true);
            app.GamingButton.Layout.Row = 8;
            app.GamingButton.Layout.Column = [4 6];
            app.GamingButton.Text = 'Start Recording';

            % Create CountDown
            app.CountDown = uilabel(app.GridLayout2);
            app.CountDown.HorizontalAlignment = 'center';
            app.CountDown.FontSize = 18;
            app.CountDown.FontColor = [1 1 1];
            app.CountDown.Layout.Row = 8;
            app.CountDown.Layout.Column = 5;
            app.CountDown.Text = '3...';

            % Create TimerLabel
            app.TimerLabel = uilabel(app.GridLayout2);
            app.TimerLabel.Layout.Row = 1;
            app.TimerLabel.Layout.Column = [3 7];
            app.TimerLabel.Text = '';

            % Create LampA
            app.LampA = uilamp(app.GridLayout2);
            app.LampA.Layout.Row = 7;
            app.LampA.Layout.Column = 2;

            % Create LampS
            app.LampS = uilamp(app.GridLayout2);
            app.LampS.Layout.Row = 7;
            app.LampS.Layout.Column = 3;

            % Create LampD
            app.LampD = uilamp(app.GridLayout2);
            app.LampD.Layout.Row = 7;
            app.LampD.Layout.Column = 4;

            % Create LampJ
            app.LampJ = uilamp(app.GridLayout2);
            app.LampJ.Layout.Row = 7;
            app.LampJ.Layout.Column = 6;

            % Create LampL
            app.LampL = uilamp(app.GridLayout2);
            app.LampL.Layout.Row = 7;
            app.LampL.Layout.Column = 8;

            % Create LampK
            app.LampK = uilamp(app.GridLayout2);
            app.LampK.Layout.Row = 7;
            app.LampK.Layout.Column = 7;

            % Create StopButton
            app.StopButton = uibutton(app.GridLayout2, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.BackgroundColor = [0.6353 0.0784 0.1843];
            app.StopButton.FontColor = [1 1 1];
            app.StopButton.Visible = 'off';
            app.StopButton.Layout.Row = 8;
            app.StopButton.Layout.Column = [4 6];
            app.StopButton.Text = 'Stop';

            % Create HitLabel
            app.HitLabel = uilabel(app.GridLayout2);
            app.HitLabel.Layout.Row = 6;
            app.HitLabel.Layout.Column = 1;
            app.HitLabel.Text = '';

            % Create ALabel
            app.ALabel = uilabel(app.GridLayout2);
            app.ALabel.HorizontalAlignment = 'center';
            app.ALabel.Layout.Row = 7;
            app.ALabel.Layout.Column = 2;
            app.ALabel.Text = 'A';

            % Create SLabel
            app.SLabel = uilabel(app.GridLayout2);
            app.SLabel.HorizontalAlignment = 'center';
            app.SLabel.Layout.Row = 7;
            app.SLabel.Layout.Column = 3;
            app.SLabel.Text = 'S';

            % Create DLabel
            app.DLabel = uilabel(app.GridLayout2);
            app.DLabel.HorizontalAlignment = 'center';
            app.DLabel.Layout.Row = 7;
            app.DLabel.Layout.Column = 4;
            app.DLabel.Text = 'D';

            % Create JLabel
            app.JLabel = uilabel(app.GridLayout2);
            app.JLabel.HorizontalAlignment = 'center';
            app.JLabel.Layout.Row = 7;
            app.JLabel.Layout.Column = 6;
            app.JLabel.Text = 'J';

            % Create KLabel
            app.KLabel = uilabel(app.GridLayout2);
            app.KLabel.HorizontalAlignment = 'center';
            app.KLabel.Layout.Row = 7;
            app.KLabel.Layout.Column = 7;
            app.KLabel.Text = 'K';

            % Create LLabel
            app.LLabel = uilabel(app.GridLayout2);
            app.LLabel.HorizontalAlignment = 'center';
            app.LLabel.Layout.Row = 7;
            app.LLabel.Layout.Column = 8;
            app.LLabel.Text = 'L';

            % Create Finish
            app.Finish = uitab(app.TabGroup);
            app.Finish.Title = 'Tab3';

            % Create BackButton
            app.BackButton = uibutton(app.Finish, 'push');
            app.BackButton.ButtonPushedFcn = createCallbackFcn(app, @BackButtonPushed, true);
            app.BackButton.Position = [172 114 100 23];
            app.BackButton.Text = 'Back';

            % Create HowToPlay
            app.HowToPlay = uitab(app.TabGroup);
            app.HowToPlay.Title = 'Tab4';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = thegame

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
