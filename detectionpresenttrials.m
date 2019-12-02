close all;
clearvars;
commandwindow;

% Setup PTB with some default values
PsychDefaultSetup(2);

% Seed the random number generator.
rng('default')

prompt = {'Subject''s number:', 'group'};

% Skip sync tests for demo purposes only
Screen('Preference', 'SkipSyncTests', 1);


%----------------------------------------------------------------------
%                       Screen setup
%----------------------------------------------------------------------

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2);

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set the text size
Screen('TextSize', window, 60);

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');


%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% Keybpard setup
spaceKey = KbName('space');
escapeKey = KbName('ESCAPE');
RestrictKeysForKbCheck([spaceKey escapeKey]);
%----------------------------------------------------------------------
%                     Gabor info
%----------------------------------------------------------------------

% Dimension of the region where will draw the Gabor in pixels
gaborDimPix = windowRect(4) / 2;

% Sigma of Gaussian
sigma = gaborDimPix / 7;

% Obvious Parameters
orientation = 0;
contrast = 0.8;
aspectRatio = 1.0;
phase = 0;

% Spatial Frequency (Cycles Per Pixel)
% One Cycle = Grey-Black-Grey-White-Grey i.e. One Black and One White Lobe
numCycles = 5;
freq = numCycles / gaborDimPix;

% Build a procedural gabor texture (Note: to get a "standard" Gabor patch
% we set a grey background offset, disable normalisation, and set a
% pre-contrast multiplier of 0.5.
% For full details see:
% https://groups.yahoo.com/neo/groups/psychtoolbox/conversations/topics/9174
backgroundOffset = [0.5 0.5 0.5 0.0];
disableNorm = 1;
preContrastMultiplier = 0.5;
gabortex = CreateProceduralGabor(window, gaborDimPix, gaborDimPix, [],...
    backgroundOffset, disableNorm, preContrastMultiplier);

% Randomise the phase of the Gabors and make a properties matrix.
propertiesMat = [phase, freq, sigma, contrast, aspectRatio, 0, 0, 0]

%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------

% Interstimulus interval time in seconds and frames
isiTimeSecs = 1;
isiTimeFrames = round(isiTimeSecs / ifi);

% Numer of frames to wait before re-drawing
waitframes = 1;

% How long should the texture stay up during flicker in time and frames
gaborSecs = 6;
gaborFrames = round(gaborSecs / ifi);

% Duration (in seconds) of the blanks between the images during flicker
blankSecs = 0.25;
blankFrames = round(blankSecs / ifi);

% Make a vector which shows what we do on each frame
presVector = [ones(1, gaborFrames) zeros(1, blankFrames)...
    ones(1, gaborFrames) .* 2 zeros(1, blankFrames)];
numPresLoopFrames = length(presVector);

%----------------------------------------------------------------------
%                        Fixation Cross
%----------------------------------------------------------------------

% Screen Y fraction for fixation cross
crossFrac = 0.0167;

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = windowRect(4) * crossFrac;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;

%----------------------------------------------------------------------
%                  Response matrix
%----------------------------------------------------------------------

% This is a four row matrix the first row will record the word we present,
% the second row the color the word it written in, the third row the key
% they respond with and the final row the time they took to make there response.
numTrials = 6
respMat = nan(2, numTrials);

%----------------------------------------------------------------------
%                      Experimental Loop
%----------------------------------------------------------------------

% set start screen
line1 = 'Hello! This is the beginning of the experiment ';
%line2 = '\n Press the Space bar if a gabor patch was displayed';
line2 = '\n\n Press Spacebar To Begin';
[screenXpixel, screenYpixels] = Screen ('WindowSize', window)
Screen('TextSize', window, 50)

 
% start actual trials 
for trial = 1:numTrials
     
    if trial == 1  
    DrawFormattedText(window, [line1 line2 ],...
            'center', screenYpixels * 0.25, white),
    Screen('Flip', window);
     while 1
     [keyIsDown,secs,keyCode] = KbCheck;
      if keyCode(KbName('space'))==1
         break
      end
     end
    end

   Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2)
   vbl = Screen('Flip', window)
    
   % Draw the fixation cross in white, set it to the center of our screen and
   % set good quality antialiasing
    for frame = 1:isiTimeFrames - 1

        % Draw the fixation point
        Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2);

        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end 

    tStart = GetSecs;
    
    % This is the drawing loop 
    Priority(topPriorityLevel);
    %draw gabor
    Screen('DrawTextures', window, gabortex, [], [], orientation, [], [], [], [],...
    kPsychDontDoRotation, propertiesMat')
    Screen('Flip', window);

    % Check the keyboard. The person should pressed the spacekey
    WaitSecs(1)
    
    trial_timer = tic()
    
    while trial_timer<3
        
        %collect responses with kbcheck
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(spaceKey)
            response = 1
            respMade = true
        else
            response = 0;
            respMade = false
        end
     
        respMat(1, trial) = responsemade;
        respMat(2, trial) = toc(trial_timer);

    end 

end
%disp(experiment has ended)
DrawFormattedText(window, ['This is the end of the experiment, press any key to exit'],...
            'center', screenYpixels * 0.25, white)
Screen('Flip', window)
KbWait;
% Close the onscreen window
sca
return
