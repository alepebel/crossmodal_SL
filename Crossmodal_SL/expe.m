function expe()
sca;
%PsychPortAudio('Close');
close all;
clearvars;

% Variables for debugging
a = 0; b = 0; c = 0; d = 0; f = 0;

%TODO: blocks fade out;

global init window textures vbl pahandle target_textures
global istraining tp fp current_image

% Experiment variables
init.ph_width = 0.53; init.ph_height = 0.30; %screen dimensions in m
init.view_distance = 0.5; %in m
init.view_angle = 20;
init.version = 1.1;
init.stimulus_dur = 0.500;
init.isi = 0.250;
init.test_ipi = 0.9; %inter-pair interval during test
init.widthImage = 700;
init.aspectRatio = 1;
init.task = 'DET_SALIENCE'; % options: NONE, CLAS_MODALITY, DET_SALIENCE % TODO
init.visual_stimuli='norm-filter-t';
init.visual_target='noise-filter-t';
init.num_targets_x_pair = 20; %number of task targets x pair
init.expo_repeat = 110; %number of repetitions for each pair during exposure (better if its a multiple of 11)
init.max_response_time = inf;
init.max_response_timeRKG = inf;
init.background_color = 0; %between 0 and 1
init.time_before_flip = 0.02; %time to leave between capturing keys and preparing to flip, in seconds
init.kb_scanlist = zeros(1,256); init.kb_scanlist(32)=1; %scan only the spacebar
init.windows_os = ispc;
init.freq = 44100; %audio playback freq
init.target_noise_pct = 0.7; %percentage of noise in audio targets
init.training_block = true; %true;
init.examples={'norm-filter-example', 'noise-filter-example','example-norm','example-noise'};
init.block_size = 331;
init.blocks = 8;
init.debug = 1;
init.max_time_to_detect = 2; %number of stimuli that can pass between a target stimulus onset and the keypress to qualify as a correct detection
init.show_square = false; %white square in the corner used for calibration

init.image_ph_height = tan(degtorad(init.view_angle/2))*init.view_distance*2;
init.image_ph_width = init.image_ph_height; %image dimensions in m

target_undetected = false;
time_to_detect = 0;

% modalities: 0=Visual, 1=Auditory
%           in indexes: 1=Visual, 2=Auditory

init.pair_modalities = [1 1;
    1 1;
    1 1;
    0 0;
    0 0;
    0 0;
    1 0;
    1 0;
    1 0;
    0 1;
    0 1;
    0 1;
    ];

%init.pair_modalities = zeros(12,2); %only visual stimuli
%init.pair_modalities = ones(12,2); %only auditory stimuli

init.pairs = size(init.pair_modalities,1);
sti_num(2) = nnz(init.pair_modalities);
sti_num(1) = numel(init.pair_modalities)-sti_num(2);

init.audios_volume=[1 1 1 1 1 1 1 1 1 1 1 1];

% Loading stimuli
cd visual_stimuli
if init.windows_os
    init.v_files = strcat(pwd,filesep,ls(strcat(init.visual_stimuli,'*.png')));
    init.target_v_files = strcat(pwd,filesep,ls(strcat(init.visual_target,'*.png')));
else
    c =strsplit(ls(strcat(init.visual_stimuli,'*.png')), '\t');
    m = max(cellfun(@(x) numel(x),c));
    list = cell2mat(cellfun(@(x) x{:},cellfun(@(x) [strcat(x,{repmat(' ',[1 m-length(x)])})],c, 'UniformOutput', false)','UniformOutput',false));
    init.v_files = strcat(pwd,filesep,list);
    
    c =strsplit(ls(strcat(init.visual_target,'*.png')), '\t');
    m = max(cellfun(@(x) numel(x),c));
    list = cell2mat(cellfun(@(x) x{:},cellfun(@(x) [strcat(x,{repmat(' ',[1 m-length(x)])})],c, 'UniformOutput', false)','UniformOutput',false));
    init.target_v_files = strcat(pwd,filesep,list);
end
cd ..
cd auditory_stimuli_final
if init.windows_os
    init.a_files = strcat(pwd,filesep,ls('Pista*.wav'));
else
    c =strsplit(ls('Pista*.wav'), '\t');
    m = max(cellfun(@(x) numel(x),c));
    list = cell2mat(cellfun(@(x) x{:},cellfun(@(x) [strcat(x,{repmat(' ',[1 m-length(x)])})],c, 'UniformOutput', false)','UniformOutput',false));
    init.a_files = strcat(pwd,filesep,list);
end
cd ..

% Creating pairs
v_index = 1;
a_index = 1;
v_perm = NRandPerm(size(init.v_files,1),sti_num(1));
a_perm = NRandPerm(size(init.a_files,1),sti_num(2));
init.pair_stimuli = zeros(size(init.pair_modalities));
for st=1:size(init.pair_modalities,1)
    if init.pair_modalities(st,1)
        init.pair_stimuli(st,1) = a_perm(a_index);
        a_index = a_index + 1;
    else
        init.pair_stimuli(st,1) = v_perm(v_index);
        v_index = v_index + 1;
    end
    if init.pair_modalities(st,2)
        init.pair_stimuli(st,2) = a_perm(a_index);
        a_index = a_index + 1;
    else
        init.pair_stimuli(st,2) = v_perm(v_index);
        v_index = v_index + 1;
    end
end

% Trials order
final_order = []; deviants = [];
load(strcat('orders',filesep,sprintf('order_%ipairs-%irep-%iblocks.mat', init.pairs, init.expo_repeat, init.blocks)));
init.expo_order = final_order;

init.stimuli_order = [];
init.modality_order = [];
for i=1:length(init.expo_order)
    init.stimuli_order = [init.stimuli_order init.pair_stimuli(init.expo_order(i),:)];
    init.modality_order = [init.modality_order init.pair_modalities(init.expo_order(i),:)];
end

for f=find(deviants)
    init.stimuli_order(f*2) = init.pair_stimuli(deviants(f),2);
    init.modality_order(f*2) = init.pair_modalities(deviants(f),2);
end

init.task_target = zeros(1,length(init.stimuli_order));
if strcmp(init.task, 'DET_SALIENCE')
    for pair = 1:init.pairs
        targets = randsample(find(init.expo_order==pair),init.num_targets_x_pair);
        init.task_target(targets(1:end/2)*2-1)=1;
        init.task_target(targets(end/2+1:end)*2)=1;
    end
end
init.num_blocks = ceil(length(init.stimuli_order)/init.block_size);
init.accuracy_x_block = zeros(1,init.num_blocks);

% Load test order
test = load('test_info.mat');
init.test = test;
init.vbls = [];

try
    rand('state',sum(100*clock));
    
    % Sound setup
    InitializePsychSound(0);
    nrchannels = 2;
    
    devices = PsychPortAudio('GetDevices');
    device = devices(find([devices.HostAudioAPIId]==3,1)); %select ASIO device (==3)
   % pahandle = PsychPortAudio('Open', [], 1, 0, init.freq, nrchannels);
     pahandle = PsychPortAudio('Open', device.DeviceIndex, 1, 0, init.freq, nrchannels);
    %pahandle = PsychPortAudio('Open', [], 1, 0, init.freq, nrchannels);
    
    % Screen setup
    PsychDefaultSetup(2); sca
    screens=Screen('Screens');
  %  Screen('Preference', 'SkipSyncTests', 1);
    screenNumber=max(screens);
    if init.debug
        PsychDebugWindowConfiguration(0,0.5);
    else 
        HideCursor;
    end
    [window, windowRect]=Screen('OpenWindow', screenNumber);
    [init.w, init.h] = RectSize(windowRect);
    init.center = [init.w/2 init.h/2];
    init.squareRect = CenterRectOnPointd([0 0 300 300], floor(init.center(1)*1.5), floor(init.center(2)*0.5));
    init.black=BlackIndex(screenNumber);
    init.white=WhiteIndex(screenNumber);
    init.ifi = Screen('GetFlipInterval', window);
    init.isi_fr = round(init.isi/init.ifi);
    init.test_ipi_fr = round(init.test_ipi/init.ifi);
    init.sti_dur_fr = round(init.stimulus_dur/init.ifi);
    Screen(window,'FillRect', init.white*init.background_color);
    [width, height]=Screen('WindowSize', window);
    leftKey     = KbName('LeftArrow');
    rightKey    = KbName('RightArrow');
    rememberKey = KbName('z');
    knowKey = KbName('x');
    guessKey = KbName('c');
    Screen('Preference', 'TextEncodingLocale', 'C');
    init.key_presses = {};
    init.key_press_times = [];
    
    %pre-loading audio buffers
    buffer = [];
    target_buffer = [];
    n = size(init.a_files,1);
    audios = cell(n,1);
    audios_norm = cell(n,1);
    audios_noise = cell(n,1);
    for i=1:init.pairs
        audiodata = psychwavread(init.a_files(i,:));
        audios{i} = (audiodata(:,1)+audiodata(:,2))/2; %mixing stereo channels into mono
        audiodata = [audios{i},audios{i}]*init.audios_volume(i);
        buffer(end+1) = PsychPortAudio('CreateBuffer', [], audiodata');
    end
    
    if strcmp(init.task, 'DET_SALIENCE')
        powers = cell2mat(cellfun(@(x) bandpower(x), audios, 'UniformOutput', false));
        power_mean = mean(mean(powers));

        for i=1:init.pairs
            audio_norm = audios{i}*sqrt(power_mean/bandpower(audios{i}));
            envelope = smooth(abs(hilbert(audio_norm)),1000);
            noise = wgn(length(audios{i}),1,0).*envelope;
            audios_noise{i} = audios{i}*(1-init.target_noise_pct)+noise*init.target_noise_pct;
            target_buffer(end+1) = PsychPortAudio('CreateBuffer', [], [audios_noise{i},audios_noise{i}]');
        end
    end
    PsychPortAudio('UseSchedule', pahandle, 1);
    
    %pre-making the textures
    textures = zeros(size(init.v_files,1),1);
    target_textures = zeros(size(init.v_files,1),1);
    for i=1:size(init.v_files,1)
        A = imread(init.v_files(i,:));
        textures(i) = Screen('MakeTexture', window, A);
        
        if strcmp(init.task, 'DET_SALIENCE')
            A = imread(init.target_v_files(i,:));
            target_textures(i) = Screen('MakeTexture', window, A);
        end
    end
    
    init.image_px_height = init.image_ph_height * init.h/init.ph_height;
    init.image_px_width = init.image_ph_width * init.w/init.ph_width;
    init.imageRect = [0 0 init.image_px_width init.image_px_height];
    init.imageRect = CenterRectOnPointd(init.imageRect, init.center(1), init.center(2));
    
    %preparing fixation point
    fixCrossDimPix = 30;
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    init.allCoords = [xCoords; yCoords];
    init.lineWidthPix = 3;
    
    %X mark for errors
    xCoords = [-fixCrossDimPix fixCrossDimPix -fixCrossDimPix fixCrossDimPix];
    yCoords = [fixCrossDimPix -fixCrossDimPix -fixCrossDimPix fixCrossDimPix];
    init.allXCoords = [xCoords; yCoords];
    
    topPriorityLevel = MaxPriority(window);
    Priority(topPriorityLevel);
    
    KbQueueCreate;
    KbQueueStart;
    
    % Training block
    if init.training_block
        init.sec = [];
        init.vbls = [];
        init.target_time = 0;
        % Distortion examples
        cd visual_stimuli
        file_std = strcat(pwd,filesep,ls(strcat(init.examples{1},'*.png')));
        file_target = strcat(pwd,filesep,ls(strcat(init.examples{2},'*.png')));
        cd ..
        cd auditory_stimuli_final
        file_audio = strcat(pwd,filesep,ls(strcat(init.examples{3},'*.wav')));
        file_noise = strcat(pwd,filesep,ls(strcat(init.examples{4},'*.wav')));
        cd ..
        standard = imread(file_std);
        target = imread(file_target);
        texture_std = Screen('MakeTexture', window, standard);
        texture_target = Screen('MakeTexture', window, target);

        audiodata = psychwavread(file_audio);
        %audiodata = [audiodata,audiodata];
        buffer_std = PsychPortAudio('CreateBuffer', [], audiodata');

        audiodata = psychwavread(file_noise);
        audiodata = [audiodata,audiodata];
        buffer_noise = PsychPortAudio('CreateBuffer', [], audiodata');

        widthImage = init.w*0.3;

        heightImage = widthImage / init.aspectRatio;
        imageRect = [0 0 widthImage heightImage];
        imageRect_std = CenterRectOnPointd(imageRect, init.center(1)-init.w*0.1125, init.center(2)-init.h*0.1);
        imageRect_target = CenterRectOnPointd(imageRect, init.center(1)+init.w*0.2625, init.center(2)-init.h*0.1);


        Screen('FillRect', window, 0);
        DrawFormattedText(window, strcat(WrapString('Durante este experimento se te irán mostrando dos tipos de estímulos: imágenes o sonidos.',60), WrapString('\n\nA veces estos estímulos aparecerán distorsionados al habérseles añadido ruido. A continuación se te mostrarán ejemplos de estas distorsiones.',60), '\n\nPresiona cualquier tecla para continuar.'), 'center', 'center', [255 255 255, 255]);
        Screen('Flip',window);
        KbWait([],3);

        Screen('FillRect', window, 0);
        DrawFormattedText_mod(window, 'Normal', 'center', init.h*0.1, 255, -init.w*0.1125);
        DrawFormattedText_mod(window, 'Distorsión', 'center', init.h*0.1, 255, +init.w*0.2625);
        Screen('DrawTexture', window, texture_std, [], imageRect_std, 0);
        Screen('DrawTexture', window, texture_target, [], imageRect_target, 0);
        DrawFormattedText_mod(window, 'Imágenes', 'center', init.center(2)-init.h*0.1, 255, -init.w*0.3750);
        DrawFormattedText_mod(window, 'Audios', 'center', init.center(2)+init.h*0.2, 255, -init.w*0.3750);
        DrawFormattedText_mod(window, 'Presiona la tecla Z\n para escuchar', 'center', init.center(2)+init.h*0.2, 255, -init.w*0.1125);
        DrawFormattedText_mod(window, 'Presiona la tecla X\n para escuchar', 'center', init.center(2)+init.h*0.2, 255, +init.w*0.2625);
        DrawFormattedText(window, 'Presiona la barra espaciadora para continuar.', 'center', init.center(2)+init.h*0.4, [255 255 255, 255]);

        Screen('Flip',window);
        next = false;
        while ~next
            [~, keyCode, ~] = KbWait([],3);
            if keyCode(KbName('z'))
                s = PsychPortAudio('GetStatus', pahandle);
                if s.Active == 0
                    PsychPortAudio('UseSchedule', pahandle, 2);
                end
                PsychPortAudio('AddToSchedule', pahandle, buffer_std, 1, 0, [], 1);
                PsychPortAudio('Start', pahandle, 1,  0, 1, inf);
            elseif keyCode(KbName('x'))
                s = PsychPortAudio('GetStatus', pahandle);
                if s.Active == 0
                    PsychPortAudio('UseSchedule', pahandle, 2);
                end
                PsychPortAudio('AddToSchedule', pahandle, buffer_noise, 1, 0, [], 1);
                PsychPortAudio('Start', pahandle, 1,  0, 1, inf);
            elseif keyCode(KbName('space'))
                next = true;
            end
        end
        
        % Training instructions
        DrawFormattedText(window, strcat(WrapString('Ahora se te mostrará una serie de varios estímulos de este tipo. Este bloque es de prueba para familiarizarte con ellos y con la tarea. Pulsa la barra espaciadora cuando aparezca un estímulo distorsionado con ruido (sea imagen o audio). Mantén la mirada fija en la cruz del centro.',60), '\n\nAparecerá una X cuando falles, azul si no detectas una distorsión \n y roja si pulsas cuando no había distorsión.\n\nPresiona cualquier tecla para comenzar.'), 'center', 'center', [255 255 255, 255]);
        Screen('Flip',window);
        WaitSecs(1);
        KbWait([],3);
        stimuli_count = 1;
        init.training_order = repmat(1:init.pairs*2,[1 3]);
        init.training_order = init.training_order(randperm(length(init.training_order)));
        fscore = 0;
        while fscore < 0.8
            vbl=GetSecs();
            ideal_vbl = vbl;
            stimuli_count = 1;
            init.training_order = repmat(1:init.pairs*2,[1 4]);
            init.training_targets = [zeros(1,init.pairs*6),ones(1,init.pairs*2)];
            total_targets = sum(init.training_targets);
            perm = randperm(length(init.training_order));
            init.training_order = init.training_order(perm);
            init.training_targets = init.training_targets(perm);
            istraining = true;
            tp = 0; fp = 0;
            KbQueueFlush();
            while stimuli_count <= length(init.training_order)
                stimulus = init.training_order(stimuli_count);
                showStimulus(floor((stimulus-1)/init.pairs), mod((stimulus-1),init.pairs)+1,init.isi_fr, 0, init.training_targets(stimuli_count),true);
                stimuli_count = stimuli_count+1;
            end
            precision = tp/(tp+fp); recall = tp/total_targets;
            fscore = 2/(inv(precision)+inv(recall));
            if fscore < 0.8
                DrawFormattedText(window, strcat('Fin del entrenamiento. \nPuntuación: ',num2str(fscore*100),'% \n Repetirás el entrenamiento hasta obtener una puntuación mayor que el 80%\nPresiona cualquier tecla para continuar.'), 'center', 'center', [255 255 255, 255]);
                Screen('Flip',window);
                WaitSecs(1);
                KbWait([],3);
            end
        end
        DrawFormattedText(window, strcat('Fin del entrenamiento. \nPuntuación: ',num2str(fscore*100),'% \n ¡Muy bien! \n Presiona cualquier tecla para continuar.'), 'center', 'center', [255 255 255, 255]);
        Screen('Flip',window);
        WaitSecs(1);
        KbWait([],3);
    end
    istraining = false;
    
    % Instructions
    DrawFormattedText(window, strcat(WrapString(strcat('Igual que en el anterior bloque, vas a ver y oir diferentes estímulos. Estos a veces aparecerán distorsionados, pero con menor frecuencia que en el bloque anterior. Pulsa la barra espaciadora cuando aparezca un estímulo distorsionado. Mantén la mirada fija en la cruz del centro. El experimento está dividido en ',num2str(init.num_blocks),' bloques, entre los cuales podrás tomarte un espiro.'),60), '\n\nPresiona cualquier tecla para comenzar el experimento.'), 'center', 'center', [255 255 255, 255]);
    Screen('Flip',window);
    while ~KbCheck
    end
    WaitSecs(1);
    
    % Exposure
    vbl = Screen('Flip', window);
    init.sec = [];
    init.vbls = vbl;
    init.target_time = 0;
    stimuli_count = 1;
    block = 1;
    tp = 0; fp = 0;
    while stimuli_count <= length(init.stimuli_order)
        if stimuli_count > block*init.block_size
            total_targets = sum(init.task_target((block-1)*init.block_size+1:block*init.block_size));
            precision = tp/(tp+fp); recall = tp/total_targets;
            fscore = 2/(inv(precision)+inv(recall));
            DrawFormattedText(window, strcat('Fin del bloque ',' ',num2str(block),'. \nPuntuación: ',num2str(fscore*100),'% \n Presiona cualquier tecla para continuar.'), 'center', 'center', [255 255 255, 255]);
            Screen('Flip',window);
            block = block+1;
            WaitSecs(1);
            while ~KbCheck
            end
            vbl = GetSecs;
            tp = 0; fp = 0;
        end
        showStimulus(init.modality_order(stimuli_count), init.stimuli_order(stimuli_count),init.isi_fr, 0, init.task_target(stimuli_count), true);
        stimuli_count = stimuli_count+1;
    end
    
    % Test instructions
    DrawFormattedText(window, strcat(WrapString('¡Tarea finalizada! Avisa al experimentrador.\nAhora se te mostrarán pares de secuencias de dos estímulos, selecciona la que creas haber visto durante la tarea anterior usando las teclas de dirección izquierda (para la primera secuencia) y derecha (para la segunda secuencia)',50), '\n Presiona cualquier tecla para continuar con las instrucciones.'), 'center', 'center', [255 255 255, 255]);
    Screen('Flip',window);
    while ~KbCheck
    end
    WaitSecs(1);
    
    DrawFormattedText(window, strcat(WrapString('Tras indicar qué secuencia te resultaba más familiar, se te preguntará por qué has seleccionado esa secuencia, tendrás que seleccionar usando las teclas Z, X y C una de las siguientes alternativas:',50), '\n Z: Recuerdo la secuencia.', '\n X: Me era más familiar la secuencia.', '\n C: He escogido al azar.', '\n Presiona cualquier tecla para comenzar.'), 'center', 'center', [255 255 255, 255]);
    Screen('Flip',window);
    while ~KbCheck
    end
    WaitSecs(1);
    vbl = GetSecs;
    
    %Conductual test
    init.answers = zeros(length(test.trials_order),1);
    init.RT_answers = zeros(length(test.trials_order),1);
    init.answersRKG = zeros(length(test.trials_order),1);
    init.RT_answersRKG = zeros(length(test.trials_order),1);
    for trials_count=1:length(test.trials_order)
        trial_num = test.trials_order(trials_count);
        trial_keys = test.trial_keys(trial_num,:);
        
        oldTextSize = Screen('TextSize', window ,50);
        for test_pair=1:2
            Screen('TextSize', window ,oldTextSize);
            DrawFormattedText(window, strcat(WrapString(strcat('Presiona cualquier tecla para ver la ',num2str(test_pair),'ª secuencia de estímulos'))), 'center', 'center', [255 255 255, 255]);
            Screen('Flip',window);
            oldTextSize = Screen('TextSize', window ,50);
            vbl = KbWait([],3);
            pair_key = test.pair_keys(trial_keys(test_pair),:);
            
            %TODO comprobar que funcione bien; seems to work bien, aunque
            %podría testear con un número de pares o algo o quizás sería
            %mucho lío
            
            pair = init.pair_stimuli(pair_key);
            pair_modality = init.pair_modalities(pair_key);
                        
            Screen('FillRect', window, init.white*init.background_color);
            DrawFormattedText(window, num2str(test_pair) , 'center', 'center', [255 255 255, 255]);
            Screen('Flip',window);
            
            timeToWait = init.test_ipi_fr;
            for stimulus=1:2
                showStimulus(pair_modality(stimulus), pair(stimulus), timeToWait, test_pair, 0, false);
                timeToWait = init.isi_fr;
                Screen('FillRect', window, init.white*init.background_color);
            end
        end
        
        %draw pair question 
        Screen('TextSize', window, 40);
        DrawFormattedText(window, '1  ?  2', 'center', 'center', 255);
        Screen('TextSize', window, oldTextSize);
        width  = 13;           % width of arrow head
        h_offset = 40;          
        arrows_center = init.center+[0, 60];
        head_left   = arrows_center-[h_offset,0] ; % coordinates of head
        points_left = [ head_left-[0,width]    % left corner
                   head_left-[width,0]         % right corner
                   head_left+[0,width] ];      % vertex
        Screen('FillPoly', window, 255, points_left);
        Screen('DrawLine', window, 255, arrows_center(1)-h_offset/2, arrows_center(2), points_left(2,1), arrows_center(2));
        head_right   = arrows_center+[h_offset,0] ; % coordinates of head
        points_right = [ head_right-[0,width]    % left corner
                   head_right+[width,0]         % right corner
                   head_right+[0,width] ];      % vertex
        Screen('FillPoly', window,255, points_right);
        Screen('DrawLine', window, 255, arrows_center(1)+h_offset/2, arrows_center(2), points_right(2,1), arrows_center(2));
        vbl = Screen('Flip',window);
        
        %get answer
        rel_time = 0;
        response = 0;
        answered = false;
        while ~answered && rel_time < init.max_response_time
            rel_time = GetSecs - vbl;
            [~,~, keyCode] = KbCheck;
            if keyCode(leftKey)
                response = 1;
                answered = true;
            elseif keyCode(rightKey)
                response = 2;
                answered = true;
            end
        end
        init.RT_answers(trials_count) = rel_time;
        init.answers(trials_count) = response;
        
        vbl = GetSecs;
        
        %subjective awareness measure (KnowRememberGuess)
        
        %draw subjective awareness question 
        Screen(window,'FillRect', 0);
        v_offset = 80;
        h_offset = 200;
        DrawFormattedText_mod(window, 'Recuerdo', 'center', 'center', 255, -h_offset);
        DrawFormattedText_mod(window, 'Familiar', 'center', 'center', 255);
        DrawFormattedText_mod(window, 'Azar', 'center', 'center', 255, h_offset);
        width  = 10;
        h_offset_multiplier = 1.1;
        arrow_center   = init.center+[0,v_offset/2]; % coordinates of head
        points = [ arrow_center-[h_offset*h_offset_multiplier,width]    % left corner
                   arrow_center+[h_offset*h_offset_multiplier,0]         % right corner
                   arrow_center+[-h_offset*h_offset_multiplier,width] ];      % vertex
        Screen('FillPoly', window,255, points, 1);
        DrawFormattedText_mod(window, 'Z', 'center', init.h/2+v_offset, 255, -h_offset);
        DrawFormattedText_mod(window, 'X', 'center', init.h/2+v_offset, 255);
        DrawFormattedText_mod(window, 'C', 'center', init.h/2+v_offset, 255, h_offset);
        
        vbl = Screen('Flip',window);
        rel_time = 0;
        response = 0;
        answered = false;
        while ~answered && rel_time < init.max_response_timeRKG
            rel_time = GetSecs - vbl;
            [~,secs, keyCode] = KbCheck;
            if keyCode(knowKey)
                response = 1;
                answered = true;
            elseif keyCode(rememberKey)
                response = 2;
                answered = true;
            elseif keyCode(guessKey)
                response = 3;
                answered = true;
            end
        end
        init.RT_answersRKG(trials_count) = rel_time;
        init.answersRKG(trials_count) = response;
        
        vbl = GetSecs;
    end
    
    DrawFormattedText(window, WrapString('¡Gracias por participar!\nAvisa al experimentador de que has terminado el experimento.',40), 'center', 'center', [255 255 255, 255]);
    vbl = Screen('Flip',window);
    WaitSecs(1);
    while ~KbCheck
    end
    
    sca;
    PsychPortAudio('Close');
    save(strcat('logs',filesep,datestr(now, 'dd-mmm-yyyy-hh-MM-SS')),'init');
catch
    init.error = psychlasterror;
    save(strcat('error-logs',filesep,datestr(now, 'dd-mmm-yyyy-hh-MM-SS'),'-error'),'init');
    PsychPortAudio('Close');
    Screen('CloseAll');
    fclose('all');
    psychrethrow(psychlasterror);
end

    function showStimulus(modality, sti_index, waitframes, fixation, target, capture)
        %global a_loaded textures window init vbl pahandle
        Screen('FillRect', window, init.white*init.background_color);
        if modality %if auditory
            
            s = PsychPortAudio('GetStatus', pahandle);
            if s.Active == 0
                PsychPortAudio('UseSchedule', pahandle, 2);
            end
            
            if target
                PsychPortAudio('AddToSchedule', pahandle, target_buffer(sti_index), 1, 0, [], 1);
            else
                PsychPortAudio('AddToSchedule', pahandle, buffer(sti_index), 1, 0, [], 1);
            end
            fixationPoint(fixation);
            init.sec = [init.sec GetSecs()];
            
            if capture
                captureKeyPresses(vbl+(waitframes-0.5)*init.ifi-init.time_before_flip);
            end
            
            if init.show_square
                Screen('FillRect', window, [255 255 255, 255], init.squareRect);
            end
            
            Screen('Flip', window, vbl+(waitframes-0.5)*init.ifi,0,1);
            vbl = PsychPortAudio('Start', pahandle, 1,  vbl+(waitframes-0.5)*init.ifi, 1, inf); %stimulus appears
            init.sec = [init.sec GetSecs()];
        else
            if target
                Screen('DrawTexture', window, target_textures(sti_index), [], init.imageRect, 0);
                texture = target_textures(sti_index);
            else
                Screen('DrawTexture', window, textures(sti_index), [], init.imageRect, 0);
                texture = textures(sti_index);
            end
            
             
            fixationPoint(fixation);
            init.sec = [init.sec GetSecs()];
            
            if capture
                captureKeyPresses(vbl+(waitframes-0.5)*init.ifi-init.time_before_flip);
            end
            current_image = texture;
            
             if init.show_square
                Screen('FillRect', window, [255 255 255, 255], init.squareRect);
            end
            vbl = Screen('Flip', window, vbl+(waitframes-0.5)*init.ifi); %stimulus appears
            init.sec = [init.sec GetSecs()];
        end
        if target_undetected>0 %previous target wasn't detected
            if istraining %showError
                if ~isempty(current_image)
                    Screen('DrawTexture', window, current_image, [], init.imageRect, 0);
                end
                fixationPoint(0);
                trainingError(2); %type-2 error
                Screen('Flip', window, [], 1);
                WaitSecs(0.3);
                Screen('FillRect', window, init.white*init.background_color);
                if ~isempty(current_image)
                    Screen('DrawTexture', window, current_image, [], init.imageRect, 0);
                end
                fixationPoint(0);
                Screen('Flip', window, [], 1);
            end
            target_undetected = target_undetected-1;
        end
        if target
            if istraining
                target_undetected = 1;
            else
                target_undetected = 2;
            end
        end
        init.target_time = [init.target_time init.target_time(end)+init.isi];
        init.vbls = [init.vbls vbl];
        Screen('FillRect', window, init.white*init.background_color);
        fixationPoint(fixation);
        init.sec = [init.sec GetSecs()];
        
        if capture
            captureKeyPresses(vbl+(init.sti_dur_fr-0.5)*init.ifi-init.time_before_flip);
        end
        
        vbl = Screen('Flip', window, vbl+(init.sti_dur_fr-0.5)*init.ifi); %stimulus disappears
        init.sec = [init.sec GetSecs()];
        init.target_time = [init.target_time init.target_time(end)+init.stimulus_dur];
        init.vbls = [init.vbls vbl];
        current_image = '';
    end

    function fixationPoint(fixation)
        if(fixation==0)
            Screen('DrawLines', window, init.allCoords,init.lineWidthPix, init.white, init.center);
        else
             DrawFormattedText(window, num2str(fixation) , 'center', 'center', [255 255 255, 255]);
        end
    end

    function trainingError(error_type)
        if error_type==1
            Screen('DrawLines', window, init.allXCoords,init.lineWidthPix*2, [255 0 0], init.center);
        else
            Screen('DrawLines', window, init.allXCoords,init.lineWidthPix*2, [0 0 255], init.center);
        end
    end

    function captureKeyPresses(until)
        while GetSecs() < until
            [ pressed, firstPress]=KbQueueCheck;
            %[keyIsDown,secs,keyCode] = KbCheck([], init.kb_scanlist);
            if pressed
                init.key_presses = [init.key_presses find(firstPress)];
                init.key_press_times = [init.key_press_times nonzeros(firstPress)];
                if target_undetected
                    target_undetected = 0;
                    %init.accuracy_x_block(block) = init.accuracy_x_block(block)+1;
                    tp = tp+1;
                else
                    if istraining
                        if ~isempty(current_image)
                            Screen('DrawTexture', window, current_image, [], init.imageRect, 0);
                        end
                        fixationPoint(0);   
                        trainingError(1);
                        Screen('Flip', window, [], 1);
                    end
                    fp=fp+1;
                end
            end
        end
    end

end