log_files = strcat(pwd,filesep,'logs',filesep,'useful_data',filesep,ls(strcat('logs',filesep,'useful_data',filesep,'*.mat')))
n_sujes = size(log_files,1);

subject = [];
rt = [];
modality = []; %stimulus modality 0-> visual, 1-> auditory
block = [];
leading = []; %0-> leading ; 1-> trailing
threshold = 10; %ignore reaction times longer than thres
pair = []; %pair_codes
mod_switch = []; %modality switch before the stimulus
next_mod = []; %modality of following stimulus
order = []; %position of the stimulus
next_capture = []; %time when the program starts capturing keypresses again after stimulus disappears
stimulus = [];

false_subject = [];
false_rt = [];
false_stimuli = [];

press_after = [];
target_after = [];
press_before = [];
target_before = [];
press2_after = [];

subj_subject=[];
subj_age=[];
subj_order=[];
subj_music=[];
subj_gender=[];
subj_hand=[];
subj_timebtwnblocks1=[];
subj_timebtwnblocks2=[];
subj_timebtwnblocks3=[];
subj_timebtwnblocks4=[];
subj_timeb4test=[];
subj_sti_fr=[];
subj_ifi=[];
subj_presses=[];

for i=1:n_sujes
    load(log_files(i,:));
    
    if(init.remove )%|| init.bad_oddball) %if flagged as remove, we jump to next iteration
        continue
    end
    
    subj_id = str2num(log_files(i,end-5:end-4));
    start = init.vbls(2); %we start counting from the second timestamp, since its when the first stimulus is shown

    stim = repelem(init.stimuli_order,2);
    targ = repelem(init.task_target,2);

    expo_times = init.vbls(2:length(targ)+1)-start; %two timestamps (onset&offset) per stimulus
    end_ts = expo_times(end);

    stimulus_onsets = expo_times(1:2:end);

    keys = init.key_press_times-start;
    expo_presses = keys(keys<end_ts);

    targets = expo_times(targ==1);
    target_onsets = targets(1:2:end);

    target_idxs = target_onsets<expo_presses(end);
    
    first_press_after_target=arrayfun(@(x) min(expo_presses(expo_presses>x)),target_onsets(target_idxs));
    
    rt_aux = (first_press_after_target-target_onsets(target_idxs))';
    target_idxs = target_idxs(1:length(rt_aux))&(rt_aux<threshold)';
    
    rt = [rt;rt_aux(target_idxs)];
    modal = init.modality_order(init.task_target==1);
    modality= [modality;modal(target_idxs)'];
    
    next_modal = init.modality_order(circshift(init.task_target==1,[0,1]));
    aux = (init.modality_order(circshift(init.task_target==1,[0,-1]))~=modal);  
    mod_switch = [mod_switch; aux(target_idxs)'];
    next_mod = [next_mod;next_modal(target_idxs)'];
    all_pairs = repelem(init.expo_order,2);
    all_pairs = all_pairs(init.task_target==1);
    pair = [pair;all_pairs(target_idxs)'];
    lead = ~mod(1:length(init.stimuli_order),2);
    lead = lead(init.task_target==1);
    leading = [leading;lead(target_idxs)'];
    bl=ceil((1:length(init.stimuli_order))/init.block_size);
    bl=bl(init.task_target==1);
    block = [block;bl(target_idxs)'];
    subject = [subject; repmat(subj_id,[sum(target_idxs) 1])];
    order_aux = find(init.task_target);
    order = [order;order_aux(target_idxs)'];
    aux=init.sec(5:4:10561)-start;
    aux=aux(order_aux)-target_onsets;
    next_capture=[next_capture;aux(target_idxs)'];
    
    %stimuli codes: 1-13: visual, 14-25: auditory
    aux = init.stimuli_order+13*init.modality_order;
    aux = aux(init.task_target==1);    
    stimulus = [stimulus;aux(target_idxs)'];
    
    %computing false detections
    
    press_after_st = arrayfun(@(x) min([expo_presses(expo_presses>x) inf]),stimulus_onsets);
    target_after_st = arrayfun(@(x) min([target_onsets(target_onsets>x) inf]),stimulus_onsets);
    press_before_st = arrayfun(@(x) max([expo_presses(expo_presses<x) 0]),stimulus_onsets);
    target_before_st = arrayfun(@(x) max([target_onsets(target_onsets<x) 0]),stimulus_onsets);
    
    press2_after_st = arrayfun(@(x) min([expo_presses(expo_presses>x) inf]),press_after_st);
    
    %lgth = min(length(press_after_st),length(target_after_st));
    %false_detections = press_after_st(1:lgth) < target_after_st(1:lgth); %whenever after a stimulus appears a press before a target
    %false_detections = false_detections & ~init.task_target(1:lgth);
    
    false_subject = [false_subject;repmat(subj_id,[length(stimulus_onsets) 1])];
    %false_rt = [false_rt; (press_after_st(false_detections)-stimulus_onsets(false_detections))'];
    %stimuli codes: 1-13: visual, 14-25: auditory
    false_stimuli = [false_stimuli;(init.stimuli_order+13*init.modality_order)'];
    press_after = [press_after; press_after_st'];
    target_after = [target_after; target_after_st'];
    press_before = [press_before; press_before_st'];
    target_before = [target_before; target_before_st'];
    press2_after = [press2_after; press2_after_st'];
    
    subj_subject=[subj_subject;subj_id];
    subj_age=[subj_age;init.age];
    subj_order=[subj_order;init.order];
    subj_music=[subj_music;init.music];
    subj_gender=[subj_gender;init.gender];
    subj_hand=[subj_hand;init.hand];
    
    startblocks=init.vbls(2*(init.block_size*[1:4]+1));
    endblocks=init.vbls(1+2*(init.block_size*[1:4]));
    blocktimes=startblocks-endblocks;
    
    subj_timebtwnblocks1=[subj_timebtwnblocks1;blocktimes(1)];
    subj_timebtwnblocks2=[subj_timebtwnblocks2;blocktimes(2)];
    subj_timebtwnblocks3=[subj_timebtwnblocks3;blocktimes(3)];
    subj_timebtwnblocks4=[subj_timebtwnblocks4;blocktimes(4)];
    
    subj_sti_fr=[subj_sti_fr;init.sti_dur_fr];
    subj_ifi=[subj_ifi;init.ifi];
    subj_presses = [subj_presses;length(expo_presses)];
    
    subj_timeb4test = [subj_timeb4test;init.vbls(2*(length(init.stimuli_order)+1)) - init.vbls(1+2*length(init.stimuli_order))];
end

keys = repelem(1:4,3);
pair_modality = keys(pair)';
T = table(subject,rt,modality,leading,block,pair,pair_modality,next_mod,mod_switch,order,next_capture,stimulus,'VariableNames', ...
    {'subject','rt','modality','leading','block','pair','pair_modality','next_mod','mod_switch','order','next_capture','stimulus'});

writetable(T,'csvs/oddball_rts_all.csv');

T = table(false_subject,false_stimuli,press_after,target_after,press_before,target_before,press2_after,'VariableNames', ...
    {'subject','stimulus','press_after','target_after','press_before','target_before','press2_after'});
writetable(T,'csvs/false_detections_rts_all.csv');

T = table(subj_subject,subj_age,subj_order,subj_music,subj_gender,subj_hand,subj_timebtwnblocks1,subj_timebtwnblocks2,subj_timebtwnblocks3,subj_timebtwnblocks4,subj_timeb4test,subj_sti_fr,subj_ifi,subj_presses,'VariableNames', ...
    {'subject','age','order','music','gender','hand','subj_timebtwnblocks1','subj_timebtwnblocks2','subj_timebtwnblocks3','subj_timebtwnblocks4','subj_timeb4test','sti_fr','ifi','keypresses'});
writetable(T,'csvs/subjects_info_all.csv');