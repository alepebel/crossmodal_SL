function create_test_trials_final()
standard = reshape(1:6,[3,2]);
deviants_mapping_x_modality = [
    1 5; 2 6; 3 4; %dev1
    ];

%deviant_types_x_modality = repelem(1:3,3)';
trials_x_modality = [repelem(1:3,3)', repmat(4:6,[1 3])'];

trial_conditions = [repelem(1:4,9)]' %first col:modality;
trial_answers = [ones(36,1),zeros(36,1)];

pair_keys = [standard; deviants_mapping_x_modality];
trial_keys = trials_x_modality;
for i=1:3
    pair_keys = [pair_keys; standard+6*i; deviants_mapping_x_modality+6*i];
    trial_keys = [trial_keys; trials_x_modality+6*i];
end

%trial_keys = [trial_keys;trial_keys];
%trial_conditions = [trial_conditions;trial_conditions];

trials_order = randperm(size(trial_keys,1));

%reshape pair indices so that they coincide with the ones of the experiment
pair_keys = arrayfun(@(x) sub2ind([12,2],mod(x-1,3)+3*floor(((x-1)/6))+1, floor(mod(x-1,6)/3)+1),pair_keys);
%pair_keys = sub2ind([12,2],mod(pair_keys-1,3)+3*floor(((pair_keys-1)/6))+1, floor(mod(pair_keys-1,6)/3)+1);

for i=1:length(trials_order)
    if(rand > 0.5)
        trial_keys(i,:)=[trial_keys(i,2) trial_keys(i,1)];
        trial_answers(i,:)=[trial_answers(i,2) trial_answers(i,1)];
    end
end

save('test_info.mat','pair_keys','trial_keys','trial_conditions','trial_answers','trials_order');
end