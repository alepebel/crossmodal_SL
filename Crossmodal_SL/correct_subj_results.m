log_files = strcat(pwd,filesep,'logs',filesep,'useful_data',filesep,ls(strcat('logs',filesep,'useful_data',filesep,'*.mat')));
n_sujes = size(log_files,1);

%from subjects 001 to 015 the values for Remember and Know were reversed,
%this script fixes that.

orders = [repelem(1,8) repelem(2,6) repelem(3,8) 2 repelem(3,3) repelem(3,3)];
left_handed = [15 19 26];
music = [2 4 7 9 11 12 13 16 19 22 23 28];
age = [20 22 20 35 21 20 26 18 19 23 31 23 18 23 26 23 20 23 20 20 19 18 24 19 18 20 22 20];
gender = [0 0 1 0 1 1 0 0 1 0 0 1 0 0 1 1 1 1 1 0 1 1 1 1 0 1 1 1]; %0->male, 1->female
remove = [1 15 18, 10 11 25];
bad_oddball = [9 16 17 21 22 24 28];

for i=1:n_sujes
    load(log_files(i,:));
    subj_id = str2num(log_files(i,end-5:end-4));
    if(subj_id<16 && ~isfield(init, 'reversed'))
        rkg = init.answersRKG;
        rkg(init.answersRKG==2)=1;
        rkg(init.answersRKG==1)=2;
        init.answersRKG = rkg;
        init.reversed = true;
    end
    init.subj_id = subj_id;
    init.order = orders(subj_id);
    init.gender = gender(subj_id);
    init.age = age(subj_id);
    init.music = ismember(subj_id,music);
    init.hand = ismember(subj_id,left_handed); %0-> right, 1-> left
    init.remove = ismember(subj_id,remove); %0-> keep, 1-> remove
    init.bad_oddball = ismember(subj_id,bad_oddball); %0-> keep, 1-> remove
    save(log_files(i,:),'init');
end

