log_files = strcat(pwd,filesep,'logs',filesep,ls(strcat('logs',filesep,'*.mat')))
n_sujes = size(log_files,1);

subject=[];
lead_modality=[];
multimodal=[];
trial_type=[];
correct = [];
rt= [];
rtRKG = [];
RKG = [];
order = [];
modality = [];
answer = [];
trial_id = [];
std_pair_id = [];

trials = 144;

for i=1:n_sujes
    load(log_files(i,:));
    
    if(init.remove )%|| init.bad_oddball) %if flagged as remove, we jump to next iteration
        continue
    end
    
    subj_id = str2num(log_files(i,end-5:end-4));
    test = init.test;

    subject = [subject; repmat(subj_id,[144 1])];
    
    answers = init.answers-1; %1 -> 0; 2 -> 1
    true_answers = ~test.trial_answers(:,1); %1 0 -> 0; 0 1 -> 1
    correct_answers = (answers==true_answers(test.trials_order));

    conditions = test.trial_conditions(test.trials_order, :); %sort conditions by trial order
    %conditions: first column: 1->audio; 2->visual; 3->audiovisual; 4->visualaudio
    %            second column: 1->normal_std; 2->inverted_std
    
    lead_modality = [lead_modality;mod(conditions(:,1),2)]; % 0->visual; 1-> audio
    multimodal = [multimodal;conditions(:,1)>2]; % 0->unimodal; 1-> multimodal
    trial_type = [trial_type;conditions(:,2)-1]; % 0->normal; 1->inverted
    correct = [correct;correct_answers];
    modality = [modality;conditions(:,1)];
    rt= [rt; init.RT_answers];
    rtRKG = [rtRKG; init.RT_answersRKG];
    RKG = [RKG; init.answersRKG];
    order = [order;(1:trials)'];
    answer = [answer;init.answers];
    trials_orig_sorted = cellstr(num2str(sort(test.trial_keys,2)));
    trials_sorted = num2str(sort(test.trial_keys(test.trials_order,:),2));
    trial_id = [trial_id; %same id for trials with same pairs, independent of order
        cellfun(@(x) min(find(strcmp(trials_orig_sorted,x))),cellstr(trials_sorted))];
    first_pair_x_trial = str2num(trials_sorted(:,1:2));
    std_pair_id = [std_pair_id; 
        floor(first_pair_x_trial/12)*3+mod(first_pair_x_trial,3)+1]; %std pair id, independent of trial type
end

T = table(subject,modality,lead_modality,multimodal,trial_type,correct,rt,rtRKG,RKG,order,answer,trial_id,std_pair_id,'VariableNames', ...
    {'subject','modality','leading_modality','multimodal','trial_type','correct','rt','rkg_rt','rkg','order','answer','trial_id','std_pair_id'});
writetable(T,'csvs/test_results_all.csv');