close all;
clearvars;
commandwindow;

% Setup PTB with some default values
PsychDefaultSetup(2);

% Seed the random number generator.
rng('shuffle')

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
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
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

% How long should the image stay up during flicker in time and frames
gaborSecs = 3;
gaborFrames = round(gaborSecs / ifi);

% Duration (in seconds) of the blanks between the images during flicker
blankSecs = 0.25;
blankFrames = round(blankSecs / ifi);

% Make a vector which shows what we do on each frame
presVector = [ones(1, gaborFrames) zeros(1, blankFrames)...
    ones(1, gaborFrames) .* 2 zeros(1, blankFrames)];
numPresLoopFrames = length(presVector);


%----------------------------------------------------------------------
%                        Condition Matrix
%----------------------------------------------------------------------

% For this demo we have a (1) "disappear" condition and (2) "color change"
% We will call this our "trialType"
trialType = [1 2];

% Each condition has two examples
numExamples = 2;
numTrials = 4
% Make a condition matrix
trialLine = repmat(trialType, 1, numExamples);
exampleLine = sort(repmat(1:numExamples, 1, 2));
condMat = [trialLine; exampleLine];

% Shuffle the conditoins
shuffler = Shuffle(1:numTrials);
condMatShuff = condMat(:, shuffler);

% Make a  matrix which which will hold all of our results
resultsMatrix = nan(numTrials, 3);
resultsMatrix(:, 1:2) = condMatShuff';

% Make a directory for the results
resultsDir = [cd '/Results/'];
if exist(resultsDir, 'dir') < 1
    mkdir(resultsDir);
end
%----------------------------------------------------------------------
%                  Response matrix
%----------------------------------------------------------------------

% This is a four row matrix the first row will record the word we present,
% the second row the color the word it written in, the third row the key
% they respond with and the final row the time they took to make there response.
respMat = nan(4, numTrials);
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
%                      Experimental Loop
%----------------------------------------------------------------------

% Start screen
line1 = 'Please press Left arrow if you see a gabor patch ';
line2 = '\n Press Right arrow if no gabor patch was displayed';
line3 = '\n\n press any key to begin';
line4 = 'This is the end of the experiment, press any key to exit';
[screenXpixel, screenYpixels] = Screen ('WindowSize', window)
 Screen('TextSize', window, 50)
 DrawFormattedText(window, [line1 line2 line3],...
            'center', screenYpixels * 0.25, white),
 Screen('Flip', window);
KbWait;


for trial = 1:numTrials

    % Get this trials information
    thisTrialType = condMatShuff(1, trial);
    thisExample = condMatShuff(2, trial);

    % Define the trial type label
    if thisTrialType == 1
        trialTypeLabel = 'present';
    elseif thisTrialType == 2
        trialTypeLabel = 'absent';
    end
    % Cue to determine whether a response has been made
    respToBeMade = true;

    % Draw the fixation cross in white, set it to the center of our screen and
    % set good quality antialiasing
    Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2);

    Screen('Flip', window);
    WaitSecs(1);

    % This is the drawing loop
    numFrames = 0; 
    Priority(topPriorityLevel);
    
    while respToBeMade == true

        % Decide what we are showing on this frame
        % Draw the gabor or a blank frame
        if thisTrialType == 1
            Screen('DrawTextures', window, gabortex, [], [], orientation, [], [], [], [],...
    kPsychDontDoRotation, propertiesMat');
        elseif thisTrialType == 2
            Screen('Flip', window)
        end 
        % Check the keyboard. The person should press the
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            ShowCursor;
            sca;
            return
        elseif keyCode(leftKey)
            response = 1;
        elseif keyCode(rightKey)
            response = 2;
        end  
    end 

    % Calculate the time it took the person to respond
    timeTakenSecs = numFrames * ifi;

    % Switch to low priority for after trial tasks
    Priority(0);

    % Record this in our results matrix
    respMat(1, trial) = response;
    respMat(2, trial) = timeTakenSecs;
end

disp('*** Experiment terminated ***')
DrawFormattedText(window, [line 4],...
            'center', screenYpixels * 0.25, white)
KbStrokeWait;
% Close the onscreen window
sca
return
