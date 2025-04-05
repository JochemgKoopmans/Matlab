%% CNS Internship Data Processing Pipeline: Pilot3 AFC
%Jochem Koopmans

% HYPOTHESIS RATIOS MIGHT CONTAIN NANS SHOW NUMBER OF
% DATAPOINTS IN FIGURES? Also for posthoc analyses

%% clear and close
clear
close all

%% List of participants; organisational data
    % 1 and 2 have imbalanced recog option distributions;
    % 7, 10, 15, 16, 22, 29, 41, 43 ignored recog letter orientation
    % 30, 42 has an incomplete dataset (40 was incomplete but
    % participant_session file was complete)
    % 34, 49 dataset is missing
    % 44 did not provide serious answers
pp_list = {'3.xlsx','4.xlsx','5.xlsx','6.xlsx','8.xlsx','9.xlsx', ...
    '11.xlsx','12.xlsx','13.xlsx','14.xlsx','17.xlsx','18.xlsx','19.xlsx','20.xlsx', ...
    '21.xlsx','23.xlsx','24.xlsx','25.xlsx','26.xlsx','27.xlsx','28.xlsx', ...
    '31.xlsx','32.xlsx','33.xlsx','35.xlsx','36.xlsx','37.xlsx','38.xlsx','39.xlsx','40_2.xlsx', ...
    '45.xlsx','46.xlsx','47.xlsx','48.xlsx','50.xlsx', ...
    '51.xlsx'}; % 
pp_tab_list = {'3','4','5','6','8','9', ...
    '11','12','13','14','17','18','19','20', ...
    '21','23','24','25','26','27','28', ...
    '31','32','33','35','36','37','38','39','40', ...
    '45','46','47','48','50', ...
    '51'}; %

    % Lists of subject file rows, depending on which block goes first
block_starts_0 = [10;175;308;473];
block_starts_1 = [10;143;308;441];
trial_list_0 = [0;5;11;16;21;26;31;36;41;46;51;56;61;66;71;76;81;86;91;96;101;106;111;116;121;126;131;136;141;146;151;156];
trial_list_1 = [0;4;9;13;17;21;25;29;33;37;41;45;49;53;57;61;65;69;73;77;81;85;89;93;97;101;105;109;113;117;121;125];


%% Importing data from subject data files
for participant = 1:length(pp_list)
    disp('Participant:')
    disp(participant)

    %% Import datafile
    subj_1_file = importfile4(pp_list{participant},pp_tab_list{participant},1,607);

    %% Determining block order
    if strcmp(subj_1_file{10,6}{1,1}(25:28),'cued')
        block_starts = block_starts_0;
    else
        block_starts = block_starts_1;
    end

    %% Subject-level information and feedback
        %ProlID, age, gender: delim identifies where new demographic questions start
    delim = {};
    ind = 1;
    for count = 1:length(subj_1_file{8,7}{1,1})
        if strcmp(subj_1_file{8,7}{1,1}(count),':')
            delim{ind} = count;
            ind = ind+1;
        end
        if length(delim) == 3
            break
        end
    end
        %% Copying subj information: 1. ProlID, 2. Age, 3. Gender
    dat(participant).prolid = subj_1_file{8,7}{1,1}((delim{1}+2):(delim{2}-8));
    dat(participant).age = str2num(subj_1_file{8,7}{1,1}((delim{2}+2):(delim{3}-11)));
    dat(participant).gender = subj_1_file{8,7}{1,1}((delim{3}+2):(end-2));
        % Copying feedback. Again, identify where new question starts
    delim = [];
    for count = 1:length(subj_1_file{606,7}{1,1})
        if strcmp(subj_1_file{606,7}{1,1}(count),'[')
            delim(end+1) = count;
        end
        if length(delim) == 3
            break
        end
    end
    fb_cued = subj_1_file{606,7}{1,1}((delim(1)+2):(delim(2)-20));
    fb_free = subj_1_file{606,7}{1,1}((delim(2)+2):(delim(3)-27));
    fb_recog = subj_1_file{606,7}{1,1}((delim(3)+2):(end-3));
        %% 4. fb_cued
    delim = [];
    for count = 5:(length(fb_cued)-5) %the shortest answer is 'other'
        if strcmp(fb_cued(count),',')
            delim(end+1) = count;
        end
    end
    if isempty(delim)
        dat(participant).fb_cued = {fb_cued};
    else
        dat(participant).fb_cued{1,1} = fb_cued(1:delim(1)-2);
        for count = 1:length(delim)
            try
                dat(participant).fb_cued{count+1} = fb_cued(delim(count)+2:delim(count+1)-2);
            catch
                dat(participant).fb_cued{count+1} = fb_cued(delim(count)+2:end);
            end
        end
    end
        %% 5. fb_free
    delim = [];
    for count = 5:(length(fb_free)-5) %the shortest answer is 'other'
        if strcmp(fb_free(count),',')
            delim(end+1) = count;
        end
    end
    if isempty(delim)
        dat(participant).fb_free = {fb_free};
    else
        dat(participant).fb_free{1,1} = fb_free(1:delim(1)-2);
        for count = 1:length(delim)
            try
                dat(participant).fb_free{count+1} = fb_free(delim(count)+2:delim(count+1)-2);
            catch
                dat(participant).fb_free{count+1} = fb_free(delim(count)+2:end);
            end
        end
    end
        %% 6. fb_recog
    delim = [];
    for count = 5:(length(fb_recog)-5) %the shortest answer is 'other'
        if strcmp(fb_recog(count),',')
            delim(end+1) = count;
        end
    end
    if isempty(delim)
        dat(participant).fb_recog = {fb_recog};
    else
        dat(participant).fb_recog{1,1} = fb_recog(1:delim(1)-2);
        for count = 1:length(delim)
            try
                dat(participant).fb_recog{count+1} = fb_recog(delim(count)+2:delim(count+1)-2);
            catch
                dat(participant).fb_recog{count+1} = fb_recog(delim(count)+2:end);
            end
        end
    end
        %% 7. Free comments/feedback:
    dat(participant).fb_comments = subj_1_file{607,7}{1,1}(8:end-2);

    %% Trial-level information: loops over over trials and then over blocks.
    for block = 1:4
        disp('Block:')
        disp(block)
        if strcmp(subj_1_file{block_starts(block),6}{1,1}(25:28),'cued')
        %% 1. Block type is cued
            dat(participant).block_num(block).block_type = 'cued';
            for trial = 1:32
                disp(trial)
            %% 2. Letter list, 3. inverted letter and 4. inverted letter position
                ind = 1;
                for count = 1:length(subj_1_file{(block_starts(block)+4+trial_list_0(trial)),6}{1,1})
                    if strcmp(subj_1_file{(block_starts(block)+4+trial_list_0(trial)),6}{1,1}(count:(count+1)),'<i')
                        if strcmp(subj_1_file{(block_starts(block)+4+trial_list_0(trial)),6}{1,1}(count+17),'_') %Then the letter is the cue placeholder '_'
                        elseif strcmp(subj_1_file{(block_starts(block)+4+trial_list_0(trial)),6}{1,1}(count+18),'_') % Then the letter is an inverted one
                            dat(participant).block_num(block).trial(trial).let_list{ind} = subj_1_file{(block_starts(block)+4+trial_list_0(trial)),6}{1,1}((count+17):(count+21));
                            dat(participant).block_num(block).trial(trial).inv_letter = subj_1_file{(block_starts(block)+4+trial_list_0(trial)),6}{1,1}(count+17); %Inverted letter
                            dat(participant).block_num(block).trial(trial).inv_pos = ind;       %Inverted letter position
                            ind = ind+1;
                        else    %Then the letter is a normal one
                            dat(participant).block_num(block).trial(trial).let_list{ind} = subj_1_file{(block_starts(block)+4+trial_list_0(trial)),6}{1,1}(count+17);
                            ind = ind+1;
                        end
                    end
                    if ind == 13
                        break
                    end
                end
            %% 5. Cued letters
                for count = 0:3
                dat(participant).block_num(block).trial(trial).cued_let{count+1} = subj_1_file{(block_starts(block)+6+trial_list_0(trial)),14}{1,1}(count*4+3);
                end
            %% 6. Cued row
                if strcmp(subj_1_file{(block_starts(block)+6+trial_list_0(trial)),14}{1,1}(3),dat(participant).block_num(block).trial(trial).let_list{1})
                    dat(participant).block_num(block).trial(trial).cued_row = 1;
                elseif strcmp(subj_1_file{(block_starts(block)+6+trial_list_0(trial)),14}{1,1}(3),dat(participant).block_num(block).trial(trial).let_list{5})
                    dat(participant).block_num(block).trial(trial).cued_row = 2;
                elseif strcmp(subj_1_file{(block_starts(block)+6+trial_list_0(trial)),14}{1,1}(3),dat(participant).block_num(block).trial(trial).let_list{9})
                    dat(participant).block_num(block).trial(trial).cued_row = 3;
                else
                    disp('first cued letter did not match any letter list starting letter')
                end
            %% 7. Recall answers
                count2 = 1;
                for count = 3:4:length(subj_1_file{(block_starts(block)+6+trial_list_0(trial)),19}{1,1})
                    dat(participant).block_num(block).trial(trial).recall_ans{count2} = upper(subj_1_file{(block_starts(block)+6+trial_list_0(trial)),19}{1,1}(count));
                    count2 = count2+1;
                end
                for count = count2:4
                    dat(participant).block_num(block).trial(trial).recall_ans{count} = '';
                end
            %% 8. Recall RT
                dat(participant).block_num(block).trial(trial).recall_rt = (subj_1_file{(block_starts(block)+6+trial_list_0(trial)),3}-subj_1_file{(block_starts(block)+5+trial_list_0(trial)),3})/1000;
            %% 9. Recall correctness: Correct, wrong place and incorrect
                dat(participant).block_num(block).trial(trial).recall_correct(1) = subj_1_file{(block_starts(block)+6+trial_list_0(trial)),16}{1,1};
                dat(participant).block_num(block).trial(trial).recall_correct(2) = subj_1_file{(block_starts(block)+6+trial_list_0(trial)),17}{1,1};
                dat(participant).block_num(block).trial(trial).recall_correct(3) = subj_1_file{(block_starts(block)+6+trial_list_0(trial)),18}{1,1};
            %% 10. Recog options
                dat(participant).block_num(block).trial(trial).recog_options{1} = subj_1_file{(block_starts(block)+7+trial_list_0(trial)),23}{1,1}(3); % the first recognition option is always a number
                if strcmp(subj_1_file{(block_starts(block)+7+trial_list_0(trial)),23}{1,1}(8),'_')   % Then the second recognition option is inverted
                    dat(participant).block_num(block).trial(trial).recog_options{2} = subj_1_file{(block_starts(block)+7+trial_list_0(trial)),23}{1,1}(7:11);
                else
                    dat(participant).block_num(block).trial(trial).recog_options{2} = subj_1_file{(block_starts(block)+7+trial_list_0(trial)),23}{1,1}(7);
                end
                delim = [];
                for i = 9:length(subj_1_file{(block_starts(block)+7+trial_list_0(trial)),23}{1,1})
                    if strcmp(subj_1_file{(block_starts(block)+7+trial_list_0(trial)),23}{1,1}(i),',')
                        delim(end+1)= i;
                    end
                end
                dat(participant).block_num(block).trial(trial).recog_options{3} = subj_1_file{(block_starts(block)+7+trial_list_0(trial)),23}{1,1}(delim(1)+2:delim(2)-2);
                dat(participant).block_num(block).trial(trial).recog_options{4} = subj_1_file{(block_starts(block)+7+trial_list_0(trial)),23}{1,1}(delim(2)+2:end-2);
                if length(dat(participant).block_num(block).trial(trial).recog_options{4}) == 1
                    not_shown_opt(2) = 1; %The not-shown option was upright (continued at 13).
                else
                    not_shown_opt(2) = 0; %The not-shown option was inverted (continued at 13)
                end
            %% 11. Recog answer
                    % First finding all the chosen items through their " marks
                delim = {};
                ind = 1;
                for count = 1:length(subj_1_file{(block_starts(block)+7+trial_list_0(trial)),19}{1,1})
                    if strcmp(subj_1_file{(block_starts(block)+7+trial_list_0(trial)),19}{1,1}(count),'"')
                        delim{ind} = count;
                        ind = ind+1;
                    end
                end
                    % Then using the marks to select the string width of the chosen items
                recog_chosen = {};
                for count = 1:2:length(delim)
                    recog_chosen{end+1} = subj_1_file{(block_starts(block)+7+trial_list_0(trial)),19}{1,1}((delim{count}+1):(delim{count+1}-1));
                end
                    %Loop over recognition options to identify which were chosen
                for count = 1:4
                    is_chosen = 0;
                    if sum(strcmp(dat(participant).block_num(block).trial(trial).recog_options{count},recog_chosen))>0
                        dat(participant).block_num(block).trial(trial).recog_ans(count) = 1;
                        is_chosen = 1;
                    end
                    if is_chosen == 0
                        dat(participant).block_num(block).trial(trial).recog_ans(count) = 0;
                    end
                end
            %% 12-15. Recog results
                    %Per recog option, make 2-number lists: [Id 1/0 rej | present 1/0 absent]
                num_opt = [dat(participant).block_num(block).trial(trial).recog_ans(1),0];
                inv_opt = [dat(participant).block_num(block).trial(trial).recog_ans(2),0];
                not_inv_opt = [dat(participant).block_num(block).trial(trial).recog_ans(3),0];
                not_shown_opt(1) = dat(participant).block_num(block).trial(trial).recog_ans(4); %The second number is upright (1) or inverted (0)
                options_list = {num_opt,inv_opt,not_inv_opt};
                    %Adding whether the presented option was present in array
                for count = 1:3 %The not-shown option is never in the array, the second number represents whether it was upright (1) or inv (0)
                    for count2 = 1:12
                        if sum(strcmp(dat(participant).block_num(block).trial(trial).recog_options{count},dat(participant).block_num(block).trial(trial).let_list{count2})) > 0
                            options_list{count}(2) = 1;
                        end
                    end
                end
                    %Using the double-binary code to fill in the recognition option tables
                recog_array = [0 0 0 0];
                if options_list{1}(1) == 1 && options_list{1}(2) == 1   %Both Id and present in array
                    recog_array(1) = 1;
                elseif options_list{1}(1) == 1 && options_list{1}(2) == 0 %Id and absent in array
                    recog_array(2) = 1;
                elseif options_list{1}(1) == 0 && options_list{1}(2) == 1 %Rej and present in array
                    recog_array(3) = 1;
                elseif options_list{1}(1) == 0 && options_list{1}(2) == 0 %Rej and absent in array
                    recog_array(4) = 1;
                end
                dat(participant).block_num(block).trial(trial).recog_num = recog_array;
                
                recog_array = [0 0 0 0];
                if options_list{2}(1) == 1 && options_list{2}(2) == 1   %Both Id and present in array
                    recog_array(1) = 1;
                elseif options_list{2}(1) == 1 && options_list{2}(2) == 0 %Id and absent in array
                    recog_array(2) = 1;
                elseif options_list{2}(1) == 0 && options_list{2}(2) == 1 %Rej and present in array
                    recog_array(3) = 1;
                elseif options_list{2}(1) == 0 && options_list{2}(2) == 0 %Rej and absent in array
                    recog_array(4) = 1;
                end
                dat(participant).block_num(block).trial(trial).recog_inv = recog_array;
                
                recog_array = [0 0 0 0];
                if options_list{3}(1) == 1 && options_list{3}(2) == 1   %Both Id and present in array
                    recog_array(1) = 1;
                elseif options_list{3}(1) == 1 && options_list{3}(2) == 0 %Id and absent in array
                    recog_array(2) = 1;
                elseif options_list{3}(1) == 0 && options_list{3}(2) == 1 %Rej and present in array
                    recog_array(3) = 1;
                elseif options_list{3}(1) == 0 && options_list{3}(2) == 0 %Rej and absent in array
                    recog_array(4) = 1;
                end
                dat(participant).block_num(block).trial(trial).recog_not_inv = recog_array;
                
                recog_array = [0 0 0 0];
                if not_shown_opt(1) == 1 && not_shown_opt(2) == 1   %Both Id and upright
                    recog_array(1) = 1;
                elseif not_shown_opt(1) == 1 && not_shown_opt(2) == 0 %Id and inverted
                    recog_array(2) = 1;
                elseif not_shown_opt(1) == 0 && not_shown_opt(2) == 1 %Rej and upright
                    recog_array(3) = 1;
                elseif not_shown_opt(1) == 0 && not_shown_opt(2) == 0 %Rej and inverted
                    recog_array(4) = 1;
                end
                dat(participant).block_num(block).trial(trial).recog_not_shown = recog_array;
            %% 16. Recog RT
                dat(participant).block_num(block).trial(trial).recog_rt = (subj_1_file{(block_starts(block)+7+trial_list_0(trial)),3}-subj_1_file{(block_starts(block)+6+trial_list_0(trial)),3})/1000;    
            end
        elseif strcmp(subj_1_file{block_starts(block),6}{1,1}(25:28),'free')
        %% 1. Block type is free   
            dat(participant).block_num(block).block_type = 'free';
            for trial = 1:32
                disp(trial)
            %% 2. Letter list, 3. inverted letter and 4. inverted letter position
                ind = 1;
                for count = 1:length(subj_1_file{(block_starts(block)+4+trial_list_1(trial)),6}{1,1})
                    if strcmp(subj_1_file{(block_starts(block)+4+trial_list_1(trial)),6}{1,1}(count:(count+1)),'<i')
                        if strcmp(subj_1_file{(block_starts(block)+4+trial_list_1(trial)),6}{1,1}(count+17),'_') %Then the letter is the cue placeholder '_'
                        elseif strcmp(subj_1_file{(block_starts(block)+4+trial_list_1(trial)),6}{1,1}(count+18),'_') % Then the letter is an inverted one
                            dat(participant).block_num(block).trial(trial).let_list{ind} = subj_1_file{(block_starts(block)+4+trial_list_1(trial)),6}{1,1}((count+17):(count+21));
                            dat(participant).block_num(block).trial(trial).inv_letter = subj_1_file{(block_starts(block)+4+trial_list_1(trial)),6}{1,1}(count+17); %Inverted letter
                            dat(participant).block_num(block).trial(trial).inv_pos = ind;       %Inverted letter position
                            ind = ind+1;
                        else    %Then the letter is a normal one
                            dat(participant).block_num(block).trial(trial).let_list{ind} = subj_1_file{(block_starts(block)+4+trial_list_1(trial)),6}{1,1}(count+17);
                            ind = ind+1;
                        end
                    end
                    if ind == 13
                        break
                    end
                end
            %% 5. Recall answers
                count2 = 1;
                for count = 3:4:length(subj_1_file{(block_starts(block)+5+trial_list_1(trial)),19}{1,1})
                    dat(participant).block_num(block).trial(trial).recall_ans{count2} = upper(subj_1_file{(block_starts(block)+5+trial_list_1(trial)),19}{1,1}(count));
                    count2 = count2+1;
                end
                for count = count2:12
                    dat(participant).block_num(block).trial(trial).recall_ans{count} = '';
                end
            %% 6. Recall RT
                dat(participant).block_num(block).trial(trial).recall_rt = (subj_1_file{(block_starts(block)+5+trial_list_1(trial)),3}-subj_1_file{(block_starts(block)+4+trial_list_1(trial)),3})/1000;
            %% 7. Recall correctness: Correct, wrong place and incorrect
                dat(participant).block_num(block).trial(trial).recall_correct(1) = subj_1_file{(block_starts(block)+5+trial_list_1(trial)),16}{1,1};
                dat(participant).block_num(block).trial(trial).recall_correct(2) = subj_1_file{(block_starts(block)+5+trial_list_1(trial)),17}{1,1};
                dat(participant).block_num(block).trial(trial).recall_correct(3) = subj_1_file{(block_starts(block)+5+trial_list_1(trial)),18}{1,1};
            %% 8. Recog options
                dat(participant).block_num(block).trial(trial).recog_options{1} = subj_1_file{(block_starts(block)+6+trial_list_1(trial)),23}{1,1}(3); % the first recognition option is always a number
                if strcmp(subj_1_file{(block_starts(block)+6+trial_list_1(trial)),23}{1,1}(8),'_')   % Then the second recognition option is inverted
                    dat(participant).block_num(block).trial(trial).recog_options{2} = subj_1_file{(block_starts(block)+6+trial_list_1(trial)),23}{1,1}(7:11);
                else
                    dat(participant).block_num(block).trial(trial).recog_options{2} = subj_1_file{(block_starts(block)+6+trial_list_1(trial)),23}{1,1}(7);
                end
                delim = [];
                for count = 9:length(subj_1_file{(block_starts(block)+6+trial_list_1(trial)),23}{1,1})
                    if strcmp(subj_1_file{(block_starts(block)+6+trial_list_1(trial)),23}{1,1}(count),',')
                        delim(end+1)= count;
                    end
                end
                dat(participant).block_num(block).trial(trial).recog_options{3} = subj_1_file{(block_starts(block)+6+trial_list_1(trial)),23}{1,1}(delim(1)+2:delim(2)-2);
                dat(participant).block_num(block).trial(trial).recog_options{4} = subj_1_file{(block_starts(block)+6+trial_list_1(trial)),23}{1,1}(delim(2)+2:end-2);
                if length(dat(participant).block_num(block).trial(trial).recog_options{4}) == 1 %The not-shown option is upright
                    not_shown_opt(2) = 1;
                else
                    not_shown_opt(2) = 0;
                end
            %% 9. Recog answer
                    % First finding all the chosen items through their " marks
                delim = {};
                ind = 1;
                for count = 1:length(subj_1_file{(block_starts(block)+6+trial_list_1(trial)),19}{1,1})
                    if strcmp(subj_1_file{(block_starts(block)+6+trial_list_1(trial)),19}{1,1}(count),'"')
                        delim{ind} = count;
                        ind = ind+1;
                    end
                end
                    % Then using the marks to select the string width of the chosen items
                recog_chosen = {};
                for count = 1:2:length(delim)
                    recog_chosen{end+1} = subj_1_file{(block_starts(block)+6+trial_list_1(trial)),19}{1,1}((delim{count}+1):(delim{count+1}-1));
                end
                    %Loop over recognition options to identify which were chosen
                for count = 1:4
                    is_chosen = 0;
                    if sum(strcmp(dat(participant).block_num(block).trial(trial).recog_options{count},recog_chosen))>0
                        dat(participant).block_num(block).trial(trial).recog_ans(count) = 1;
                        is_chosen = 1;
                    end
                    if is_chosen == 0
                        dat(participant).block_num(block).trial(trial).recog_ans(count) = 0;
                    end
                end
            %% 10-13. Recog results
                    %Per recog option, make 2-number lists: [Id 1/0 rej | present 1/0 absent]
                num_opt = [dat(participant).block_num(block).trial(trial).recog_ans(1),0];
                inv_opt = [dat(participant).block_num(block).trial(trial).recog_ans(2),0];
                not_inv_opt = [dat(participant).block_num(block).trial(trial).recog_ans(3),0];
                not_shown_opt(1) = dat(participant).block_num(block).trial(trial).recog_ans(4);
                options_list = {num_opt,inv_opt,not_inv_opt};
                    %Adding whether the presented option was present-in-array (1) or not (0)
                for count = 1:3
                    for count2 = 1:12
                        if sum(strcmp(dat(participant).block_num(block).trial(trial).recog_options{count},dat(participant).block_num(block).trial(trial).let_list{count2})) > 0
                            options_list{count}(2) = 1;
                        end
                    end
                end
                    %Using the double-binary code to fill in the recognition option arrays
                recog_array = [0 0 0 0];
                if options_list{1}(1) == 1 && options_list{1}(2) == 1   %Both Id and present in array
                    recog_array(1) = 1;
                elseif options_list{1}(1) == 1 && options_list{1}(2) == 0 %Id and absent in array
                    recog_array(2) = 1;
                elseif options_list{1}(1) == 0 && options_list{1}(2) == 1 %Rej and present in array
                    recog_array(3) = 1;
                elseif options_list{1}(1) == 0 && options_list{1}(2) == 0 %Rej and absent in array
                    recog_array(4) = 1;
                end
                dat(participant).block_num(block).trial(trial).recog_num = recog_array;
                %Recog option inverted
                recog_array = [0 0 0 0];
                if options_list{2}(1) == 1 && options_list{2}(2) == 1   %Both Id and present in array
                    recog_array(1) = 1;
                elseif options_list{2}(1) == 1 && options_list{2}(2) == 0 %Id and absent in array
                    recog_array(2) = 1;
                elseif options_list{2}(1) == 0 && options_list{2}(2) == 1 %Rej and present in array
                    recog_array(3) = 1;
                elseif options_list{2}(1) == 0 && options_list{2}(2) == 0 %Rej and absent in array
                    recog_array(4) = 1;
                end
                dat(participant).block_num(block).trial(trial).recog_inv = recog_array;
                %Recog option not inverted               
                recog_array = [0 0 0 0];
                if options_list{3}(1) == 1 && options_list{3}(2) == 1   %Both Id and present in array
                    recog_array(1) = 1;
                elseif options_list{3}(1) == 1 && options_list{3}(2) == 0 %Id and absent in array
                    recog_array(2) = 1;
                elseif options_list{3}(1) == 0 && options_list{3}(2) == 1 %Rej and present in array
                    recog_array(3) = 1;
                elseif options_list{3}(1) == 0 && options_list{3}(2) == 0 %Rej and absent in array
                    recog_array(4) = 1;
                end
                dat(participant).block_num(block).trial(trial).recog_not_inv = recog_array;
                %Recog option not-shown                                
                recog_array = [0 0 0 0];
                if not_shown_opt(1) == 1 && not_shown_opt(2) == 1   %Id and upright
                    recog_array(1) = 1;
                elseif not_shown_opt(1) == 1 && not_shown_opt(2) == 0 %Id and inverted
                    recog_array(2) = 1;
                elseif not_shown_opt(1) == 0 && not_shown_opt(2) == 1 %Rej and upright
                    recog_array(3) = 1;
                elseif not_shown_opt(1) == 0 && not_shown_opt(2) == 0 %Rej and inverted
                    recog_array(4) = 1;
                end
                dat(participant).block_num(block).trial(trial).recog_not_shown = recog_array;
            %% 14. Recog RT
                dat(participant).block_num(block).trial(trial).recog_rt = (subj_1_file{(block_starts(block)+6+trial_list_1(trial)),3}-subj_1_file{(block_starts(block)+5+trial_list_1(trial)),3})/1000;
            %The 'end' below ends the 32 trials
            end
        %The 'end' below ends the free block
        end
    end
end

%% Analyses/data visualisations
%% 1. Assumptions checks
    %a. Strategy (how do subjects answer?): FB questions 1-4
ana.fb.cued = {};
ana.fb.free = {};
ana.fb.recog = {};
ana.fb.comments = {};
for participant = 1:length(pp_list)
    for strat = 1:length(dat(participant).fb_cued)
        ana.fb.cued{end+1} = dat(participant).fb_cued{strat}; %
    end
    for strat = 1:length(dat(participant).fb_free)
        ana.fb.free{end+1} = dat(participant).fb_free{strat}; %
    end
    for strat = 1:length(dat(participant).fb_recog)
        ana.fb.recog{end+1} = dat(participant).fb_recog{strat}; %
    end
    ana.fb.comments{participant} = dat(participant).fb_recog{strat};
end
ana.fb.cued = categorical(ana.fb.cued);
ana.fb.free = categorical(ana.fb.free);
ana.fb.recog = categorical(ana.fb.recog);

figure %1
subplot(3,1,1);
hist(ana.fb.cued)
title('Feedback cued recall')
ylabel('Times chosen')

subplot(3,1,2);
hist(ana.fb.free)
title('Feedback free recall')
ylabel('Times chosen')

subplot(3,1,3);
hist(ana.fb.recog);
title('Feedback recognition question')
ylabel('Times chosen')

%% 2. Main analysis
    % 0. Age, gender of subjects
disp('Age: mean, SD')
age2 = [];
for participant = 1:length(pp_list)
    age2(end+1) = dat(participant).age;
end
age(1) = mean(age2);
age(2) = std(age2);
disp(age)

gender(1) = 0;
for participant = 1:length(pp_list)
    if strcmpi(dat(participant).gender(1), 'm')
        gender = gender +1;
    end
end
disp('Subject distribution: N men, total')
gender(2) = length(pp_list);
disp(gender)

%% 1b & 1c & 2.1 Performance recall trials: Recall_correctness total, separated per condition, per block_number
      %1c. Recognition IDs: Number of options chosen per trial in total, separated per condition, per block
      %2.1 MAIN ANALYSIS RECOGNITION TABLES
for participant = 1:length(pp_list)
        num1=0;
        num2=0;
    for block = 1:4
        if strcmp(dat(participant).block_num(block).block_type,'cued')
            for trial = 3:32 % The first two are practice (see also comment on the lines below)
                perf_block(trial-2) = (dat(participant).block_num(block).trial(trial).recall_correct(1)+dat(participant).block_num(block).trial(trial).recall_correct(2))*3; %Exclude the practice trials by writing (trial-2)
                perf_cued(num1*30+trial-2) = (dat(participant).block_num(block).trial(trial).recall_correct(1)+dat(participant).block_num(block).trial(trial).recall_correct(2))*3; %Exclude the practiec trials by writing (num1*30+trial-2)
                
                %Recognition percentages
                recog_rate_block(trial-2) = sum(dat(participant).block_num(block).trial(trial).recog_ans);
                recog_rate_cued(num1*30+trial-2) = sum(dat(participant).block_num(block).trial(trial).recog_ans);
                
                %Recognition option 2x2 tables
                num_rates_block(trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_num;
                num_rates_cued(num1*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_num;
                
                inv_rates_block(trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                inv_rates_cued(num1*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                %Saving for posthoc test:
                ana.inv_ratio_list(participant).cued(num1*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                
                not_inv_rates_block(trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_not_inv;
                not_inv_rates_cued(num1*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_not_inv;
                
                not_shown_rates_block(trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_not_shown;
                not_shown_rates_cued(num1*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_not_shown;
            end
            ana.performance.block(participant,block) = mean(perf_block);
            ana.performance.cued(participant,num1+1) = mean(perf_block);
            ana.performance.cued(participant,num1+3) = sum(perf_block)/1.2;
            ana.recog_rate.block(participant,block) = mean(recog_rate_block);
            ana.recog_rate.cued(participant,num1+1) = mean(recog_rate_block);
            ana.recog_tables.block.number(participant,((block-1)*4+1):(block*4)) = mean(num_rates_block); %Columns 1:4 show the table for the first block, 5:8 for the second, etc.
            ana.recog_tables.block.inverted(participant,((block-1)*4+1):(block*4)) = mean(inv_rates_block);
            ana.recog_tables.block.not_inverted(participant,((block-1)*4+1):(block*4)) = mean(not_inv_rates_block);
            ana.recog_tables.block.not_shown(participant,((block-1)*4+1):(block*4)) = mean(not_shown_rates_block); 
            ana.recog_tables.cued(participant,(num1*4+1):(num1*4+4)) = mean(num_rates_block);
            ana.recog_tables.cued(participant,(num1*4+9):(num1*4+12)) = mean(inv_rates_block);
            ana.recog_tables.cued(participant,(num1*4+17):(num1*4+20)) = mean(not_inv_rates_block);
            ana.recog_tables.cued(participant,(num1*4+25):(num1*4+28)) = mean(not_shown_rates_block);
            
            num1 = num1+1;
            %5D matrix: Participant(N),condition(2),block(2),recog_option(4),recog_table(4)
            ana.tables(participant,1,num1,1,1:4) = mean(num_rates_block);
            ana.tables(participant,1,num1,2,1:4) = mean(inv_rates_block);
            ana.tables(participant,1,num1,3,1:4) = mean(not_inv_rates_block);
            ana.tables(participant,1,num1,4,1:4) = mean(not_shown_rates_block);
        else
            for trial = 3:32 % The first two trials are practice
                perf_block(trial-2) = dat(participant).block_num(block).trial(trial).recall_correct(1)+dat(participant).block_num(block).trial(trial).recall_correct(2);
                perf_free(num2*30+trial-2) = dat(participant).block_num(block).trial(trial).recall_correct(1)+dat(participant).block_num(block).trial(trial).recall_correct(2);
                
                %Recognition percentages
                recog_rate_block(trial-2) = sum(dat(participant).block_num(block).trial(trial).recog_ans);
                recog_rate_free(num2*30+trial-2) = sum(dat(participant).block_num(block).trial(trial).recog_ans);
                
                %Recognition option 2x2 tables
                num_rates_block(trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_num;
                num_rates_free(num2*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_num;
                
                inv_rates_block(trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                inv_rates_free(num2*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                %Saving for posthoc test
                ana.inv_ratio_list(participant).free(num2*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                
                not_inv_rates_block(trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_not_inv;
                not_inv_rates_free(num2*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_not_inv;
                
                not_shown_rates_block(trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_not_shown;
                not_shown_rates_free(num2*30+trial-2,1:4) = dat(participant).block_num(block).trial(trial).recog_not_shown;
            end
            ana.performance.block(participant,block) = mean(perf_block);
            ana.performance.free(participant,num2+1) = mean(perf_block);
            ana.performance.free(participant,num2+3) = sum(perf_block)/3.6;
            ana.recog_rate.block(participant,block) = mean(recog_rate_block);
            ana.recog_rate.free(participant,num2+1) = mean(recog_rate_block);
            ana.recog_tables.block.number(participant,((block-1)*4+1):(block*4)) = mean(num_rates_block);
            ana.recog_tables.block.inverted(participant,((block-1)*4+1):(block*4)) = mean(inv_rates_block);
            ana.recog_tables.block.not_inverted(participant,((block-1)*4+1):(block*4)) = mean(not_inv_rates_block);
            ana.recog_tables.block.not_shown(participant,((block-1)*4+1):(block*4)) = mean(not_shown_rates_block);
            ana.recog_tables.free(participant,(num2*4+1):(num2*4+4)) = mean(num_rates_block);
            ana.recog_tables.free(participant,(num2*4+9):(num2*4+12)) = mean(inv_rates_block);
            ana.recog_tables.free(participant,(num2*4+17):(num2*4+20)) = mean(not_inv_rates_block);
            ana.recog_tables.free(participant,(num2*4+25):(num2*4+28)) = mean(not_shown_rates_block);
            
            num2 = num2+1;
            %5D matrix: Participant(N),condition(2),block(2),recog_option(4),recog_table(4)
            ana.tables(participant,2,num2,1,1:4) = mean(num_rates_block);
            ana.tables(participant,2,num2,2,1:4) = mean(inv_rates_block);
            ana.tables(participant,2,num2,3,1:4) = mean(not_inv_rates_block);
            ana.tables(participant,2,num2,4,1:4) = mean(not_shown_rates_block);
        end
    end
    ana.performance.cond(participant,1) = mean(perf_cued); %These three show number correct out of 12.
    ana.performance.cond(participant,2) = mean(perf_free);
    ana.performance.tot(participant) = mean(cat(2,perf_cued,perf_free));
    
    ana.recog_rate.cond(participant,1) = mean(recog_rate_cued); %Shows how many recognition options each subject selects on average out of the 4
    ana.recog_rate.cond(participant,2) = mean(recog_rate_free);
    ana.recog_rate.tot(participant) = mean(cat(2,recog_rate_cued,recog_rate_free));
    
    ana.recog_tables.cond.number(participant,1:4) = mean(num_rates_cued); %Shows the average table per recognition option per condition
    ana.recog_tables.cond.number(participant,5:8) = mean(num_rates_free); %Columns 1:4 show the table for cued, columns 5:8 for free
    ana.recog_tables.tot.number(participant,1:4) = mean(cat(1,num_rates_cued,num_rates_free)); %Shows the average table per recognition option
    ana.recog_tables.cond.inverted(participant,1:4) = mean(inv_rates_cued);
    ana.recog_tables.cond.inverted(participant,5:8) = mean(inv_rates_free);
    ana.recog_tables.tot.inverted(participant,1:4) = mean(cat(1,inv_rates_cued,inv_rates_free));
    ana.recog_tables.cond.not_inverted(participant,1:4) = mean(not_inv_rates_cued);
    ana.recog_tables.cond.not_inverted(participant,5:8) = mean(not_inv_rates_free);
    ana.recog_tables.tot.not_inverted(participant,1:4) = mean(cat(1,not_inv_rates_cued,not_inv_rates_free));
    ana.recog_tables.cond.not_shown(participant,1:4) = mean(not_shown_rates_cued);
    ana.recog_tables.cond.not_shown(participant,5:8) = mean(not_shown_rates_free);
    ana.recog_tables.tot.not_shown(participant,1:4) = mean(cat(1,not_shown_rates_cued,not_shown_rates_free));
    %Below are for follow-up on test3/hyp but with n-shown subtracted from inv and n-inv
    ana.hyp_count.inv(participant,1:4) = sum(inv_rates_cued);
    ana.hyp_count.inv(participant,5:8) = sum(inv_rates_free);
    ana.hyp_count.n_inv(participant,1:4) = sum(not_inv_rates_cued);
    ana.hyp_count.n_inv(participant,5:8) = sum(not_inv_rates_free);
    ana.hyp_count.n_shown(participant,1:4) = sum(not_shown_rates_cued);
    ana.hyp_count.n_shown(participant,5:8) = sum(not_shown_rates_free);
end
% 1.b Plotting the performance numbers
figure %2
subplot(2,2,1);
plot([1],ana.performance.tot,'ko-')
title('Average number of items correct')
ylabel('Items correct (max=12)')
hold on
plot([1],mean(ana.performance.tot),'r*-','LineWidth',1.5)

subplot(2,2,2);
plot([1 2],ana.performance.cond,'ko-')
title('Average number of items correct per condition')
xlabel('Condition: 1=Cued; 2=Free')
ylabel('Items correct (max=12)')
hold on
plot([1 2],mean(ana.performance.cond,1),'r*-','LineWidth',1.5)

subplot(2,2,[3 4]);
plot([1 2 3 4],ana.performance.block,'ko-')
title('Average number of items correct per block')
xlabel('Block')
ylabel('Items correct (max=12)')
hold on
plot([1 2 3 4],mean(ana.performance.block,1),'r*-','LineWidth',1.5)

%Statistical tests
disp('T-test on condition means (Sperling effect):')
[h,p,ci,stats] = ttest(ana.performance.cond(:,1),ana.performance.cond(:,2))
disp('Anova on block means:')
[p,table,stats] = anova1(ana.performance.block) %Figure 3, 4

% 1.c Plotting the recognition selection numbers
figure %5
subplot(2,2,1);
plot([1],ana.recog_rate.tot,'ko-')
title('Average number of recognition options selected')
ylabel('range 0-4')
hold on
plot([1],mean(ana.recog_rate.tot),'r*-','Linewidth',1.5)

subplot(2,2,2);
plot([1 2],ana.recog_rate.cond,'ko-')
title('Average number of recog options selected per condition')
ylabel('range 0-4')
xlabel('Condition: 1=Cued; 2=Free')
hold on
plot([1 2],mean(ana.recog_rate.cond,1),'r*-','LineWidth',1.5)

subplot(2,2,[3 4]);
plot([1 2 3 4],ana.recog_rate.block,'ko-')
title('Average number of recog options selected per block')
ylabel('range 0-4')
xlabel('Block')
hold on
plot([1 2 3 4],mean(ana.recog_rate.block,1),'r*-','LineWidth',1.5)

% 2.1 Plotting the recognition tables
figure %6
subplot(2,2,1);
plot([1 2 3 4],ana.recog_tables.tot.number,'ko')
title('Table ratio for the number option')
ylabel('range: 0-.5')
xlabel('Corr & sel; Wrong & sel; Corr & rej; Wrong & rej')
hold on
plot([1 2 3 4],mean(ana.recog_tables.tot.number,1),'r*','LineWidth',1.5)

subplot(2,2,2);
plot([1 2 3 4],ana.recog_tables.tot.inverted,'ko')
title('Table ratio for the inverted option')
ylabel('range: 0-.5')
xlabel('Inv & sel; Upr & sel; Inv & rej; Upr & rej')
hold on
plot([1 2 3 4],mean(ana.recog_tables.tot.inverted,1),'r*','LineWidth',1.5)

subplot(2,2,3);
plot([1 2 3 4],ana.recog_tables.tot.not_inverted,'ko')
title('Table ratio for the not-inverted option')
ylabel('range: 0-.5')
xlabel('Upr & sel; Inv & sel; Upr & rej; Inv & rej')
hold on
plot([1 2 3 4],mean(ana.recog_tables.tot.not_inverted,1),'r*','LineWidth',1.5)

subplot(2,2,4);
plot([1 2 3 4],ana.recog_tables.tot.not_shown,'ko')
title('Table ratio for the not-shown option')
ylabel('range: 0-.5')
xlabel('Upr & sel; Inv & sel; Upr & rej; Inv & rej')
hold on
plot([1 2 3 4],mean(ana.recog_tables.tot.not_shown,1),'r*','LineWidth',1.5)

%% 2. Main analyses
    %2. Null hypothesis 1: All item information forgotten, id% equal between inv_letter, not-inv_let, and not-shown_let.
    %3. Null hypothesis 2: Letter information accurate: equal correctness number, inv_letter, not-inv_letter
    %4. Hypothesis: Comparing id_UR/id_tot % between inv, not-inv, and not-shown
for participant = 1:length(pp_list)
    %All item information lost: participant,compare number inv and n_inv on total,condition,block)
        %Total:
    ana.null1.tot(participant,1) = ana.recog_tables.tot.number(participant,1)+ana.recog_tables.tot.number(participant,2); %id percentage number option
    ana.null1.tot(participant,2) = ana.recog_tables.tot.inverted(participant,1)+ana.recog_tables.tot.inverted(participant,2); %id percentage inverted option
    ana.null1.tot(participant,3) = ana.recog_tables.tot.not_inverted(participant,1)+ana.recog_tables.tot.not_inverted(participant,2); %id percentage not_inverted option
    ana.null1.tot(participant,4) = ana.recog_tables.tot.not_shown(participant,1)+ana.recog_tables.tot.not_shown(participant,2); %id percentage not_shown option
        %Condition = cued recall:
    ana.null1.cond(participant,1) = ana.recog_tables.cond.number(participant,1)+ana.recog_tables.cond.number(participant,2);
    ana.null1.cond(participant,2) = ana.recog_tables.cond.inverted(participant,1)+ana.recog_tables.cond.inverted(participant,2);
    ana.null1.cond(participant,3) = ana.recog_tables.cond.not_inverted(participant,1)+ana.recog_tables.cond.not_inverted(participant,2);
    ana.null1.cond(participant,4) = ana.recog_tables.cond.not_shown(participant,1)+ana.recog_tables.cond.not_shown(participant,2);
        %Condition = free recall
    ana.null1.cond(participant,5) = ana.recog_tables.cond.number(participant,5)+ana.recog_tables.cond.number(participant,6);
    ana.null1.cond(participant,6) = ana.recog_tables.cond.inverted(participant,5)+ana.recog_tables.cond.inverted(participant,6);
    ana.null1.cond(participant,7) = ana.recog_tables.cond.not_inverted(participant,5)+ana.recog_tables.cond.not_inverted(participant,6);
    ana.null1.cond(participant,8) = ana.recog_tables.cond.not_shown(participant,5)+ana.recog_tables.cond.not_shown(participant,6);
        %Block = 1
    ana.null1.block(participant,1) = ana.recog_tables.block.number(participant,1)+ana.recog_tables.block.number(participant,2);
    ana.null1.block(participant,2) = ana.recog_tables.block.inverted(participant,1)+ana.recog_tables.block.inverted(participant,2);
    ana.null1.block(participant,3) = ana.recog_tables.block.not_inverted(participant,1)+ana.recog_tables.block.not_inverted(participant,2);
    ana.null1.block(participant,4) = ana.recog_tables.block.not_shown(participant,1)+ana.recog_tables.block.not_shown(participant,2);
        %Block = 2
    ana.null1.block(participant,5) = ana.recog_tables.block.number(participant,5)+ana.recog_tables.block.number(participant,6);
    ana.null1.block(participant,6) = ana.recog_tables.block.inverted(participant,5)+ana.recog_tables.block.inverted(participant,6);
    ana.null1.block(participant,7) = ana.recog_tables.block.not_inverted(participant,5)+ana.recog_tables.block.not_inverted(participant,6);
    ana.null1.block(participant,8) = ana.recog_tables.block.not_shown(participant,5)+ana.recog_tables.block.not_shown(participant,6);
        %Block = 3
    ana.null1.block(participant,9) = ana.recog_tables.block.number(participant,9)+ana.recog_tables.block.number(participant,10);
    ana.null1.block(participant,10) = ana.recog_tables.block.inverted(participant,9)+ana.recog_tables.block.inverted(participant,10);
    ana.null1.block(participant,11) = ana.recog_tables.block.not_inverted(participant,9)+ana.recog_tables.block.not_inverted(participant,10);
    ana.null1.block(participant,12) = ana.recog_tables.block.not_shown(participant,9)+ana.recog_tables.block.not_shown(participant,10);
        %Block = 4
    ana.null1.block(participant,13) = ana.recog_tables.block.number(participant,13)+ana.recog_tables.block.number(participant,14);
    ana.null1.block(participant,14) = ana.recog_tables.block.inverted(participant,13)+ana.recog_tables.block.inverted(participant,14);
    ana.null1.block(participant,15) = ana.recog_tables.block.not_inverted(participant,13)+ana.recog_tables.block.not_inverted(participant,14);
    ana.null1.block(participant,16) = ana.recog_tables.block.not_shown(participant,13)+ana.recog_tables.block.not_shown(participant,14);
    
    %Letter information accurate
        %Total
    ana.null2.tot(participant,1) = ana.recog_tables.tot.number(participant,1)+ana.recog_tables.tot.number(participant,4); %Correctness percentage number
    ana.null2.tot(participant,2) = ana.recog_tables.tot.inverted(participant,1)+ana.recog_tables.tot.inverted(participant,4); %Correctness percentage inverted
    ana.null2.tot(participant,3) = ana.recog_tables.tot.not_inverted(participant,1)+ana.recog_tables.tot.not_inverted(participant,4); %Correctness percentage not_inverted
        %Condition = cued recall
    ana.null2.cond(participant,1) = ana.recog_tables.cond.number(participant,1)+ana.recog_tables.cond.number(participant,4);
    ana.null2.cond(participant,2) = ana.recog_tables.cond.inverted(participant,1)+ana.recog_tables.cond.inverted(participant,4);
    ana.null2.cond(participant,3) = ana.recog_tables.cond.not_inverted(participant,1)+ana.recog_tables.cond.not_inverted(participant,4);
        %Condition = free recall
    ana.null2.cond(participant,4) = ana.recog_tables.cond.number(participant,5)+ana.recog_tables.cond.number(participant,8);
    ana.null2.cond(participant,5) = ana.recog_tables.cond.inverted(participant,5)+ana.recog_tables.cond.inverted(participant,8);
    ana.null2.cond(participant,6) = ana.recog_tables.cond.not_inverted(participant,5)+ana.recog_tables.cond.not_inverted(participant,8);
        %Block = 1
    ana.null2.block(participant,1) = ana.recog_tables.block.number(participant,1)+ana.recog_tables.block.number(participant,4);
    ana.null2.block(participant,2) = ana.recog_tables.block.inverted(participant,1)+ana.recog_tables.block.inverted(participant,4);
    ana.null2.block(participant,3) = ana.recog_tables.block.not_inverted(participant,1)+ana.recog_tables.block.not_inverted(participant,4);
        %Block = 2
    ana.null2.block(participant,4) = ana.recog_tables.block.number(participant,5)+ana.recog_tables.block.number(participant,8);
    ana.null2.block(participant,5) = ana.recog_tables.block.inverted(participant,5)+ana.recog_tables.block.inverted(participant,8);
    ana.null2.block(participant,6) = ana.recog_tables.block.not_inverted(participant,5)+ana.recog_tables.block.not_inverted(participant,8);
        %Block = 3
    ana.null2.block(participant,7) = ana.recog_tables.block.number(participant,9)+ana.recog_tables.block.number(participant,12);
    ana.null2.block(participant,8) = ana.recog_tables.block.inverted(participant,9)+ana.recog_tables.block.inverted(participant,12);
    ana.null2.block(participant,9) = ana.recog_tables.block.not_inverted(participant,9)+ana.recog_tables.block.not_inverted(participant,12);
        %Block = 4
    ana.null2.block(participant,10) = ana.recog_tables.block.number(participant,13)+ana.recog_tables.block.number(participant,16);
    ana.null2.block(participant,11) = ana.recog_tables.block.inverted(participant,13)+ana.recog_tables.block.inverted(participant,16);
    ana.null2.block(participant,12) = ana.recog_tables.block.not_inverted(participant,13)+ana.recog_tables.block.not_inverted(participant,16);
    
    %Comparing upright id over id-total
        %Total
    ana.hyp.tot(participant,1) = ana.recog_tables.tot.inverted(participant,2)/(ana.recog_tables.tot.inverted(participant,1)+ana.recog_tables.tot.inverted(participant,2)); %Upright proportion of identifications
    ana.hyp.tot(participant,2) = ana.recog_tables.tot.not_inverted(participant,1)/(ana.recog_tables.tot.not_inverted(participant,1)+ana.recog_tables.tot.not_inverted(participant,2)); %Upright proportion of identifications
    ana.hyp.tot(participant,3) = ana.recog_tables.tot.not_shown(participant,1)/(ana.recog_tables.tot.not_shown(participant,1)+ana.recog_tables.tot.not_shown(participant,2)); %Upright proportion of identifications
        %Condition = cued recall
    ana.hyp.cond(participant,1) = ana.recog_tables.cond.inverted(participant,2)/(ana.recog_tables.cond.inverted(participant,1)+ana.recog_tables.cond.inverted(participant,2));
    ana.hyp.cond(participant,2) = ana.recog_tables.cond.not_inverted(participant,1)/(ana.recog_tables.cond.not_inverted(participant,1)+ana.recog_tables.cond.not_inverted(participant,2));
    ana.hyp.cond(participant,3) = ana.recog_tables.cond.not_shown(participant,1)/(ana.recog_tables.cond.not_shown(participant,1)+ana.recog_tables.cond.not_shown(participant,2));
        %Condition = free recall
    ana.hyp.cond(participant,4) = ana.recog_tables.cond.inverted(participant,6)/(ana.recog_tables.cond.inverted(participant,5)+ana.recog_tables.cond.inverted(participant,6));
    ana.hyp.cond(participant,5) = ana.recog_tables.cond.not_inverted(participant,5)/(ana.recog_tables.cond.not_inverted(participant,5)+ana.recog_tables.cond.not_inverted(participant,6));
    ana.hyp.cond(participant,6) = ana.recog_tables.cond.not_shown(participant,5)/(ana.recog_tables.cond.not_shown(participant,5)+ana.recog_tables.cond.not_shown(participant,6));
        %Block = 1
    ana.hyp.block(participant,1) = ana.recog_tables.block.inverted(participant,2)/(ana.recog_tables.block.inverted(participant,1)+ana.recog_tables.block.inverted(participant,2));
    ana.hyp.block(participant,2) = ana.recog_tables.block.not_inverted(participant,1)/(ana.recog_tables.block.not_inverted(participant,1)+ana.recog_tables.block.not_inverted(participant,2));
    ana.hyp.block(participant,3) = ana.recog_tables.block.not_shown(participant,1)/(ana.recog_tables.block.not_shown(participant,1)+ana.recog_tables.block.not_shown(participant,2));
        %Block = 2
    ana.hyp.block(participant,4) = ana.recog_tables.block.inverted(participant,6)/(ana.recog_tables.block.inverted(participant,5)+ana.recog_tables.block.inverted(participant,6));
    ana.hyp.block(participant,5) = ana.recog_tables.block.not_inverted(participant,5)/(ana.recog_tables.block.not_inverted(participant,5)+ana.recog_tables.block.not_inverted(participant,6));
    ana.hyp.block(participant,6) = ana.recog_tables.block.not_shown(participant,5)/(ana.recog_tables.block.not_shown(participant,5)+ana.recog_tables.block.not_shown(participant,6));
        %Block = 3
    ana.hyp.block(participant,7) = ana.recog_tables.block.inverted(participant,10)/(ana.recog_tables.block.inverted(participant,9)+ana.recog_tables.block.inverted(participant,10));
    ana.hyp.block(participant,8) = ana.recog_tables.block.not_inverted(participant,9)/(ana.recog_tables.block.not_inverted(participant,9)+ana.recog_tables.block.not_inverted(participant,10));
    ana.hyp.block(participant,9) = ana.recog_tables.block.not_shown(participant,9)/(ana.recog_tables.block.not_shown(participant,9)+ana.recog_tables.block.not_shown(participant,10));
        %Block = 4
    ana.hyp.block(participant,10) = ana.recog_tables.block.inverted(participant,14)/(ana.recog_tables.block.inverted(participant,13)+ana.recog_tables.block.inverted(participant,14));
    ana.hyp.block(participant,11) = ana.recog_tables.block.not_inverted(participant,13)/(ana.recog_tables.block.not_inverted(participant,13)+ana.recog_tables.block.not_inverted(participant,14));
    ana.hyp.block(participant,12) = ana.recog_tables.block.not_shown(participant,13)/(ana.recog_tables.block.not_shown(participant,13)+ana.recog_tables.block.not_shown(participant,14));
end
x3=[1 2 3];
x4=[1 2 3 4];
figure %7
subplot(1,3,1);
plot(x4,ana.null1.tot,'ko-')
title('Test1: Grid information decayed')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate per trial')
hold on
plot(x4,mean(ana.null1.tot,1),'r*-','LineWidth',1.5)

subplot(1,3,2);
plot(x3,ana.null2.tot,'ko-')
title('Test2: Orientation information retained')
xlabel('Num, Inv, N-inv')
ylabel('Correctness rate per trial')
hold on
plot(x3,mean(ana.null2.tot,1),'r*-','LineWidth',1.5)

subplot(1,3,3);
plot(x3,ana.hyp.tot,'ko-')
title('Test3: Letter orientation lost')
xlabel('Inv, N-inv, N-shown')
ylabel('Proportion of upright among selections')
hold on
plot(x3,nanmean(ana.hyp.tot,1),'r*-','LineWidth',1.5)

figure %8
subplot(3,2,1);
plot(x4,ana.null1.cond(:,1:4),'ko-')
title('Test1: Grid information decayed | cued')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate per trial')
hold on
plot(x4,mean(ana.null1.cond(:,1:4),1),'r*-','LineWidth',1.5)

subplot(3,2,2);
plot(x4,ana.null1.cond(:,5:8),'ko-')
title('Test1: Grid information decayed | free')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate per trial')
hold on
plot(x4,mean(ana.null1.cond(:,5:8),1),'r*-','LineWidth',1.5)

subplot(3,2,3);
plot(x3,ana.null2.cond(:,1:3),'ko-')
title('Test2: Orientation info retained | cued')
xlabel('Num, Inv, N-inv')
ylabel('Correctness rate per trial')
hold on
plot(x3,mean(ana.null2.cond(:,1:3),1),'r*-','LineWidth',1.5)

subplot(3,2,4);
plot(x3,ana.null2.cond(:,4:6),'ko-')
title('Test2: Orientation info retained | free')
xlabel('Num, Inv, N-inv')
ylabel('Correctness rate per trial')
hold on
plot(x3,mean(ana.null2.cond(:,4:6),1),'r*-','LineWidth',1.5)

subplot(3,2,5);
plot(x3,ana.hyp.cond(:,1:3),'ko-')
title('Test3: Letter orientation lost | cued')
xlabel('Inv, N-inv, N-shown')
ylabel('Proportion upright among selections')
hold on
plot(x3,nanmean(ana.hyp.cond(:,1:3),1),'r*-','LineWidth',1.5)

subplot(3,2,6);
plot(x3,ana.hyp.cond(:,4:6),'ko-')
title('Test3: Letter orientation lost | free')
xlabel('Inv, N-inv, N-shown')
ylabel('Proportion upright among selections')
hold on
plot(x3,nanmean(ana.hyp.cond(:,4:6),1),'r*-','LineWidth',1.5)

figure %9
subplot(3,4,1);
plot(x4,ana.null1.block(:,1:4),'ko-')
title('Test1: Grid information decayed | Bl 1')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate')
hold on
plot(x4,mean(ana.null1.block(:,1:4),1),'r*-','LineWidth',1.5)

subplot(3,4,2);
plot(x4,ana.null1.block(:,5:8),'ko-')
title('Test1: Grid information decayed | Bl 2')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate')
hold on
plot(x4,mean(ana.null1.block(:,5:8),1),'r*-','LineWidth',1.5)

subplot(3,4,3);
plot(x4,ana.null1.block(:,9:12),'ko-')
title('Test1: Grid information decayed | Bl 3')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate')
hold on
plot(x4,mean(ana.null1.block(:,9:12),1),'r*-','LineWidth',1.5)

subplot(3,4,4);
plot(x4,ana.null1.block(:,13:16),'ko-')
title('Test1: Grid information decayed | Bl 4')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate')
hold on
plot(x4,mean(ana.null1.block(:,13:16),1),'r*-','LineWidth',1.5)

subplot(3,4,5);
plot(x3,ana.null2.block(:,1:3),'ko-')
title('Test2: Orientation info retained | Block 1')
xlabel('Num, Inv, N-inv')
ylabel('Correctness rate')
hold on
plot(x3,mean(ana.null2.block(:,1:3),1),'r*-','LineWidth',1.5)

subplot(3,4,6);
plot(x3,ana.null2.block(:,4:6),'ko-')
title('Test2: Orientation info retained | Block 2')
xlabel('Num, Inv, N-inv')
ylabel('Correctness rate')
hold on
plot(x3,mean(ana.null2.block(:,4:6),1),'r*-','LineWidth',1.5)

subplot(3,4,7);
plot(x3,ana.null2.block(:,7:9),'ko-')
title('Test2: Orientation info retained | Block 3')
xlabel('Num, Inv, N-inv')
ylabel('Correctness rate')
hold on
plot(x3,mean(ana.null2.block(:,7:9),1),'r*-','LineWidth',1.5)

subplot(3,4,8);
plot(x3,ana.null2.block(:,10:12),'ko-')
title('Test2: Orientation info retained | Block 4')
xlabel('Num, Inv, N-inv')
ylabel('Correctness rate')
hold on
plot(x3,mean(ana.null2.block(:,10:12),1),'r*-','LineWidth',1.5)

subplot(3,4,9);
plot(x3,ana.hyp.block(:,1:3),'ko-')
title('Test3: Letter orientation lost | Block 1')
xlabel('Inv, N-inv, N-shown')
ylabel('Prop UR among ID')
hold on
plot(x3,nanmean(ana.hyp.block(:,1:3),1),'r*-','LineWidth',1.5)

subplot(3,4,10);
plot(x3,ana.hyp.block(:,4:6),'ko-')
title('Test3: Letter orientation lost | Block 2')
xlabel('Inv, N-inv, N-shown')
ylabel('Prop UR among ID')
hold on
plot(x3,nanmean(ana.hyp.block(:,4:6),1),'r*-','LineWidth',1.5)

subplot(3,4,11);
plot(x3,ana.hyp.block(:,7:9),'ko-')
title('Test3: Letter orientation lost | Block 3')
xlabel('Inv, N-inv, N-shown')
ylabel('Prop UR among ID')
hold on
plot(x3,nanmean(ana.hyp.block(:,7:9),1),'r*-','LineWidth',1.5)

subplot(3,4,12);
plot(x3,ana.hyp.block(:,10:12),'ko-')
title('Test3: Letter orientation lost | Block 4')
xlabel('Inv, N-inv, N-shown')
ylabel('Prop UR among ID')
hold on
plot(x3,nanmean(ana.hyp.block(:,10:12),1),'r*-','LineWidth',1.5)

%% Figure summary for supervisors
figure %10 Is there a Sperling effect? (Needs not-2 participants)
plot([1 2],ana.performance.cond,'ko-')
title('Average number of items correct per condition')
xlabel('Condition: 1=Cued; 2=Free')
ylabel('Items correct (max=12)')
hold on
plot([1 2],mean(ana.performance.cond,1),'r*-','LineWidth',1.5)

figure %11 How many options do subjects select? (Needs not-2 participants)
plot([1 2],ana.recog_rate.cond,'ko-')
title('Average number of recog options selected per condition')
ylabel('range 0-4')
xlabel('Condition: 1=Cued; 2=Free')
hold on
plot([1 2],mean(ana.recog_rate.cond,1),'r*-','LineWidth',1.5)

figure %12 Hypotheses separated per condition (needs not-3 participants)
subplot(3,2,1);
plot(x4,ana.null1.cond(:,1:4),'ko-')
title('Test1: Letter information decayed | cued')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate')
hold on
plot(x4,mean(ana.null1.cond(:,1:4),1),'r*-','LineWidth',1.5)

subplot(3,2,2);
plot(x4,ana.null1.cond(:,5:8),'ko-')
title('Test1: Letter information decayed | free')
xlabel('Num, Inv, N-inv, N-shown')
ylabel('Selection rate')
hold on
plot(x4,mean(ana.null1.cond(:,5:8),1),'r*-','LineWidth',1.5)

subplot(3,2,3);
plot(x3,ana.null2.cond(:,1:3),'ko-')
title('Test2: Detailed item info retained | cued')
xlabel('Num, Inv, N-inv')
ylabel('Correct rate')
hold on
plot(x3,mean(ana.null2.cond(:,1:3),1),'r*-','LineWidth',1.5)

subplot(3,2,4);
plot(x3,ana.null2.cond(:,4:6),'ko-')
title('Test2: Detailed item info retained | free')
xlabel('Num, Inv, N-inv')
ylabel('Correct rate')
hold on
plot(x3,mean(ana.null2.cond(:,4:6),1),'r*-','LineWidth',1.5)

subplot(3,2,5);
plot(x3,ana.hyp.cond(:,1:3),'ko-')
title('Test3: Letter orientation lost | cued')
xlabel('Inv, N-inv, N-shown')
ylabel('Prop. upright/selected')
hold on
plot(x3,nanmean(ana.hyp.cond(:,1:3),1),'r*-','LineWidth',1.5)

subplot(3,2,6);
plot(x3,ana.hyp.cond(:,4:6),'ko-')
title('Test3: Letter orientation lost | free')
xlabel('Inv, N-inv, N-shown')
ylabel('Prop. upright/selected')
hold on
plot(x3,nanmean(ana.hyp.cond(:,4:6),1),'r*-','LineWidth',1.5)
        
%% 3. Post hoc analyses
    %a. Did people focus on one row? I.e. esp. for free recall, how
    %many entries are there per trial?
for participant = 1:length(pp_list)
    num1 = 0;
	for block = 1:4
		if strcmp(dat(participant).block_num(block).block_type,'free')
            for trial = 3:32
                for subj_ans = 1:12
                    % Here starts row-focus test
                    if subj_ans<10
                        % If subj_ans is the first letter and the subsequent answers are the other three letters in the row
                        if strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},dat(participant).block_num(block).trial(trial).let_list{1,1}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+1},dat(participant).block_num(block).trial(trial).let_list{1,2}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+2},dat(participant).block_num(block).trial(trial).let_list{1,3}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+3},dat(participant).block_num(block).trial(trial).let_list{1,4}(1))
                            row_focus((num1*30+trial-2),participant) = 1;
                        elseif strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},dat(participant).block_num(block).trial(trial).let_list{1,5}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+1},dat(participant).block_num(block).trial(trial).let_list{1,6}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+2},dat(participant).block_num(block).trial(trial).let_list{1,7}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+3},dat(participant).block_num(block).trial(trial).let_list{1,8}(1))
                            row_focus((num1*30+trial-2),participant) = 1;
                        elseif strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},dat(participant).block_num(block).trial(trial).let_list{1,9}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+1},dat(participant).block_num(block).trial(trial).let_list{1,10}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+2},dat(participant).block_num(block).trial(trial).let_list{1,11}(1)) ...
                                && strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans+3},dat(participant).block_num(block).trial(trial).let_list{1,12}(1))
                            row_focus((num1*30+trial-2),participant) = 1;
                        end
                    end
                    if strcmp(dat(participant).block_num(block).trial(trial-2).recall_ans{1,subj_ans},'')
						free_ans_length((num1*30+trial-2),participant) = subj_ans-1;
                        break
                    elseif subj_ans == 12
                        free_ans_length((num1*30+trial-2),participant) = subj_ans;
                    end
                end
            end
            num1 = num1+1;
		end
	end
end
part_list_vector = 1:1:length(pp_list);
figure %13
plot(part_list_vector,mean(free_ans_length(1:30,:),1),'ko')
xlabel('Participant')
ylabel('Answer length')
title('Free recall answer length per block (black|blue)')
hold on
plot(part_list_vector,mean(free_ans_length(31:end,:),1),'b*')

%Correcting row focus to short answers (up to 6 letters)
for participant = 1:length(pp_list)
    for trial = 1:60
        if row_focus(trial,participant)==1 && free_ans_length(trial,participant)<=6
            row_focus_corrected(trial, participant) =1;
        end
    end
end
figure %14
plot(part_list_vector,sum(row_focus_corrected(1:30,:),1),'ko')
xlabel('Participant')
ylabel('N (max=30)')
title('Complete row entries per block (black|blue)')
hold on
plot(part_list_vector,sum(row_focus_corrected(31:end,:),1),'b*')

    %b. Did people in cued/free recall focus on number and/or inverted letter (as judged from their recall answer?)
special_focus.cued.num = zeros(60,length(pp_list));
special_focus.cued.inv = zeros(60,length(pp_list));
special_focus.free.num = zeros(60,length(pp_list));
special_focus.free.inv = zeros(60,length(pp_list));
for participant = 1:length(pp_list)
    num1=0;
    num2=0;
    for block = 1:4
        if strcmp(dat(participant).block_num(block).block_type,'cued')
            for trial = 3:32
                for subj_ans = 1:4
                    %First check if number was entered
                    if sum(strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},{'0','1','2','3','4','5','6','7','8','9'}))>0 && sum(strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},dat(participant).block_num(block).trial(trial).let_list))>0
                        special_focus.cued.num((num1*30+trial-2),participant) = 1;
                    end
                    %Then check if inv letter was entered
                    if strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},dat(participant).block_num(block).trial(trial).inv_letter)
                        special_focus.cued.inv((num1*30+trial-2),participant) = 1;
                    end
                end
            end
            num1 = num1+1;
        elseif strcmp(dat(participant).block_num(block).block_type,'free')
            for trial = 3:32
                for subj_ans = 1:12
                    %First check if number was entered
                    if sum(strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},{'0','1','2','3','4','5','6','7','8','9'}))>0 && sum(strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},dat(participant).block_num(block).trial(trial).let_list))>0
                        special_focus.free.num((num2*30+trial-2),participant) = 1;
                    end
                    %Then check if inv letter was entered
                    if strcmp(dat(participant).block_num(block).trial(trial).recall_ans{1,subj_ans},dat(participant).block_num(block).trial(trial).inv_letter)
                        special_focus.free.inv((num2*30+trial-2),participant) = 1;
                    end
                end
            end
            num2 = num2+1;
        end
    end
end
figure %15
plot(part_list_vector,sum(special_focus.cued.num,1),'b-')
hold on
plot(part_list_vector,sum(special_focus.cued.inv,1),'r-')
hold on
plot(part_list_vector,sum(special_focus.free.num,1),'c-')
hold on
plot(part_list_vector,sum(special_focus.free.inv,1),'y-')
hold on
legend('Cued, num','Cued, inv','Free, num','Free, inv')
title('Entering number or inv letter in recall')
xlabel('Participant')
ylabel('Number of trials (max 60)')

        %1. Does answering the inverted letter on recall change the subsequent inv_letter choice?
for participant = 1:length(pp_list)
    num1=1;
    num2=1;
    num3=1;
    num4=1;
    for trial = 1:60
        if special_focus.cued.inv(trial,participant) == 1
            ana.inv_influence.subj(participant).cued_focus(num1,1:4) = ana.inv_ratio_list(participant).cued(trial,1:4);
            num1 = num1+1;
        elseif special_focus.cued.inv(trial,participant) == 0
            ana.inv_influence.subj(participant).cued_nonfocus(num2,1:4) = ana.inv_ratio_list(participant).cued(trial,1:4);
            num2 = num2+1;
        end
        if special_focus.free.inv(trial,participant) == 1
            ana.inv_influence.subj(participant).free_focus(num3,1:4) = ana.inv_ratio_list(participant).free(trial,1:4);
            num3 = num3+1;
        elseif special_focus.free.inv(trial,participant) == 0
            ana.inv_influence.subj(participant).free_nonfocus(num4,1:4) = ana.inv_ratio_list(participant).free(trial,1:4);
            num4 = num4+1;
        end
    end
end

for participant = 1:length(pp_list)
    %Sel_pres_focus(1) and sel_pres_nonfocus(5)
    inv_influence.cued(participant,1) = sum(ana.inv_influence.subj(participant).cued_focus(:,1))/(sum(ana.inv_influence.subj(participant).cued_focus(:,1))+sum(ana.inv_influence.subj(participant).cued_focus(:,3)));
    inv_influence.cued(participant,5) = sum(ana.inv_influence.subj(participant).cued_nonfocus(:,1))/(sum(ana.inv_influence.subj(participant).cued_nonfocus(:,1))+sum(ana.inv_influence.subj(participant).cued_nonfocus(:,3)));
    %Sel_abs_focus(2) and sel_abs_nonfocus(6)
    inv_influence.cued(participant,2) = sum(ana.inv_influence.subj(participant).cued_focus(:,2))/(sum(ana.inv_influence.subj(participant).cued_focus(:,2))+sum(ana.inv_influence.subj(participant).cued_focus(:,4)));
    inv_influence.cued(participant,6) = sum(ana.inv_influence.subj(participant).cued_nonfocus(:,2))/(sum(ana.inv_influence.subj(participant).cued_nonfocus(:,2))+sum(ana.inv_influence.subj(participant).cued_nonfocus(:,4)));
    %Rej_pres_focus(3) and rej_pres_nonfocus(7)
    inv_influence.cued(participant,3) = sum(ana.inv_influence.subj(participant).cued_focus(:,3))/(sum(ana.inv_influence.subj(participant).cued_focus(:,1))+sum(ana.inv_influence.subj(participant).cued_focus(:,3)));
    inv_influence.cued(participant,7) = sum(ana.inv_influence.subj(participant).cued_nonfocus(:,3))/(sum(ana.inv_influence.subj(participant).cued_nonfocus(:,1))+sum(ana.inv_influence.subj(participant).cued_nonfocus(:,3)));
    %Rej_abs_focus(4) and rej_abs_nonfocus(8)
    inv_influence.cued(participant,4) = sum(ana.inv_influence.subj(participant).cued_focus(:,4))/(sum(ana.inv_influence.subj(participant).cued_focus(:,2))+sum(ana.inv_influence.subj(participant).cued_focus(:,4)));
    inv_influence.cued(participant,8) = sum(ana.inv_influence.subj(participant).cued_nonfocus(:,4))/(sum(ana.inv_influence.subj(participant).cued_nonfocus(:,2))+sum(ana.inv_influence.subj(participant).cued_nonfocus(:,4)));
    %Sel_pres_focus(1) and sel_pres_nonfocus(5)
    inv_influence.free(participant,1) = sum(ana.inv_influence.subj(participant).free_focus(:,1))/(sum(ana.inv_influence.subj(participant).free_focus(:,1))+sum(ana.inv_influence.subj(participant).free_focus(:,3)));
    inv_influence.free(participant,5) = sum(ana.inv_influence.subj(participant).free_nonfocus(:,1))/(sum(ana.inv_influence.subj(participant).free_nonfocus(:,1))+sum(ana.inv_influence.subj(participant).free_nonfocus(:,3)));
    %Sel_abs_focus(2) and sel_pres_nonfocus(6)
    inv_influence.free(participant,2) = sum(ana.inv_influence.subj(participant).free_focus(:,2))/(sum(ana.inv_influence.subj(participant).free_focus(:,2))+sum(ana.inv_influence.subj(participant).free_focus(:,4)));
    inv_influence.free(participant,6) = sum(ana.inv_influence.subj(participant).free_nonfocus(:,2))/(sum(ana.inv_influence.subj(participant).free_nonfocus(:,2))+sum(ana.inv_influence.subj(participant).free_nonfocus(:,4)));
    %Rej_pres_focus(3) and rej_pres_nonfocus(7)
    inv_influence.free(participant,3) = sum(ana.inv_influence.subj(participant).free_focus(:,3))/(sum(ana.inv_influence.subj(participant).free_focus(:,1))+sum(ana.inv_influence.subj(participant).free_focus(:,3)));
    inv_influence.free(participant,7) = sum(ana.inv_influence.subj(participant).free_nonfocus(:,3))/(sum(ana.inv_influence.subj(participant).free_nonfocus(:,1))+sum(ana.inv_influence.subj(participant).free_nonfocus(:,3)));
    %Rej_abs_focus(4) and rej_abs_nonfocus(8)
    inv_influence.free(participant,4) =  sum(ana.inv_influence.subj(participant).free_focus(:,4))/(sum(ana.inv_influence.subj(participant).free_focus(:,2))+sum(ana.inv_influence.subj(participant).free_focus(:,4)));
    inv_influence.free(participant,8) =  sum(ana.inv_influence.subj(participant).free_nonfocus(:,4))/(sum(ana.inv_influence.subj(participant).free_nonfocus(:,2))+sum(ana.inv_influence.subj(participant).free_nonfocus(:,4)));
end
figure %16
subplot(2,1,1)
plot([1 2 3 4],inv_influence.cued(:,1:4),'yo')
hold on
plot([1 2 3 4],inv_influence.cued(:,5:8),'c*')
hold on
plot([1 2 3 4],nanmean(inv_influence.cued(:,1:4),1),'ro')
hold on
plot([1 2 3 4],nanmean(inv_influence.cued(:,5:8),1),'b*')
title('Inv choice table cued')
xlabel('Id&pres, id&abs, rej&pres, rej&abs')
ylabel('% of options')
legend('Yel-Focus','Cya-Nonfocus','Red-mean(Focus)','Blu-mean(Nonfocus)')

subplot(2,1,2)
plot([1 2 3 4],inv_influence.free(:,1:4),'yo')
hold on
plot([1 2 3 4],inv_influence.free(:,5:8),'c*')
hold on
plot([1 2 3 4],nanmean(inv_influence.free(:,1:4),1),'ro')
hold on
plot([1 2 3 4],nanmean(inv_influence.free(:,5:8),1),'b*')
title('Inv choice table free')
xlabel('Id&pres, id&abs, rej&pres, rej&abs')
ylabel('% of options')
legend('Yel-Focus','Cya-Nonfocus','Red-mean(Focus)','Blu-mean(Nonfocus)')
        
    %c. Does recall RT influence subsequent recognition answers?
%Per participant, bin trials in three bins. Then use the trials in those bins to calculate ratios.
%Procedure: 
%- Make list of RTs per participant per condition. 
%- Sort list.
%- For each trial, if trial recall_rt<21/41 boundary put trial in
%participant.bin1/2/3(trial,1:4).
%- Average participant bins.
%- Plot inv ratio table for different bins.

%First let's get an idea of RTs
for participant = 1:length(pp_list)
    for block = 1:2
        if strcmp(dat(participant).block_num(block).block_type,'cued')
            recall_rt_list.cued(:,participant) = vertcat(dat(participant).block_num(block).trial(3:end).recall_rt,dat(participant).block_num(block+2).trial(3:end).recall_rt);
        elseif strcmp(dat(participant).block_num(block).block_type,'free')
            recall_rt_list.free(:,participant) = vertcat(dat(participant).block_num(block).trial(3:end).recall_rt,dat(participant).block_num(block+2).trial(3:end).recall_rt);
        end
    end
end
recall_rt_list_sort.cued = sort(recall_rt_list.cued);
recall_rt_list_sort.free = sort(recall_rt_list.free);
for participant = 1:length(pp_list)
    num1 = 1;
    num2 = 1;
    num3 = 1;
    num4 = 1;
    num5 = 1;
    num6 = 1;
    for block = 1:4
        if strcmp(dat(participant).block_num(block).block_type,'cued')
            for trial = 3:32
                if dat(participant).block_num(block).trial(trial).recall_rt < recall_rt_list_sort.cued(21,participant)
                    recog_rt_bin.cued(participant).bin1(num1,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                    num1 = num1+1;
                elseif dat(participant).block_num(block).trial(trial).recall_rt < recall_rt_list_sort.cued(41,participant)
                    recog_rt_bin.cued(participant).bin2(num2,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                    num2 = num2+1;
                else
                    recog_rt_bin.cued(participant).bin3(num3,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                    num3 = num3+1;
                end
            end
        else
            for trial = 3:32
                if dat(participant).block_num(block).trial(trial).recall_rt < recall_rt_list_sort.free(21,participant)
                    recog_rt_bin.free(participant).bin1(num4,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                    num4 = num4+1;
                elseif dat(participant).block_num(block).trial(trial).recall_rt < recall_rt_list_sort.free(41,participant)
                    recog_rt_bin.free(participant).bin2(num5,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                    num5 = num5+1;
                else
                    recog_rt_bin.free(participant).bin3(num6,1:4) = dat(participant).block_num(block).trial(trial).recog_inv;
                    num6 = num6+1;
                end
            end
        end
    end 
    recog_rt_bin.cued_sum.bin1(participant,1) = sum(recog_rt_bin.cued(participant).bin1(:,1),1)/(sum(recog_rt_bin.cued(participant).bin1(:,1),1)+sum(recog_rt_bin.cued(participant).bin1(:,3),1));
    recog_rt_bin.cued_sum.bin1(participant,2) = sum(recog_rt_bin.cued(participant).bin1(:,2),1)/(sum(recog_rt_bin.cued(participant).bin1(:,2),1)+sum(recog_rt_bin.cued(participant).bin1(:,4),1));
    recog_rt_bin.cued_sum.bin1(participant,3) = sum(recog_rt_bin.cued(participant).bin1(:,3),1)/(sum(recog_rt_bin.cued(participant).bin1(:,1),1)+sum(recog_rt_bin.cued(participant).bin1(:,3),1));
    recog_rt_bin.cued_sum.bin1(participant,4) = sum(recog_rt_bin.cued(participant).bin1(:,4),1)/(sum(recog_rt_bin.cued(participant).bin1(:,2),1)+sum(recog_rt_bin.cued(participant).bin1(:,4),1));
    
    recog_rt_bin.cued_sum.bin2(participant,1) = sum(recog_rt_bin.cued(participant).bin2(:,1),1)/(sum(recog_rt_bin.cued(participant).bin2(:,1),1)+sum(recog_rt_bin.cued(participant).bin2(:,3),1));
    recog_rt_bin.cued_sum.bin2(participant,2) = sum(recog_rt_bin.cued(participant).bin2(:,2),1)/(sum(recog_rt_bin.cued(participant).bin2(:,2),1)+sum(recog_rt_bin.cued(participant).bin2(:,4),1));
    recog_rt_bin.cued_sum.bin2(participant,3) = sum(recog_rt_bin.cued(participant).bin2(:,3),1)/(sum(recog_rt_bin.cued(participant).bin2(:,1),1)+sum(recog_rt_bin.cued(participant).bin2(:,3),1));
    recog_rt_bin.cued_sum.bin2(participant,4) = sum(recog_rt_bin.cued(participant).bin2(:,4),1)/(sum(recog_rt_bin.cued(participant).bin2(:,2),1)+sum(recog_rt_bin.cued(participant).bin2(:,4),1));
    
    recog_rt_bin.cued_sum.bin3(participant,1) = sum(recog_rt_bin.cued(participant).bin3(:,1),1)/(sum(recog_rt_bin.cued(participant).bin3(:,1),1)+sum(recog_rt_bin.cued(participant).bin3(:,3),1));
    recog_rt_bin.cued_sum.bin3(participant,2) = sum(recog_rt_bin.cued(participant).bin3(:,2),1)/(sum(recog_rt_bin.cued(participant).bin3(:,2),1)+sum(recog_rt_bin.cued(participant).bin3(:,4),1));
    recog_rt_bin.cued_sum.bin3(participant,3) = sum(recog_rt_bin.cued(participant).bin3(:,3),1)/(sum(recog_rt_bin.cued(participant).bin3(:,1),1)+sum(recog_rt_bin.cued(participant).bin3(:,3),1));
    recog_rt_bin.cued_sum.bin3(participant,4) = sum(recog_rt_bin.cued(participant).bin3(:,4),1)/(sum(recog_rt_bin.cued(participant).bin3(:,2),1)+sum(recog_rt_bin.cued(participant).bin3(:,4),1));
    
    recog_rt_bin.free_sum.bin1(participant,1) = sum(recog_rt_bin.free(participant).bin1(:,1),1)/(sum(recog_rt_bin.free(participant).bin1(:,1),1)+sum(recog_rt_bin.free(participant).bin1(:,3),1));
    recog_rt_bin.free_sum.bin1(participant,2) = sum(recog_rt_bin.free(participant).bin1(:,2),1)/(sum(recog_rt_bin.free(participant).bin1(:,2),1)+sum(recog_rt_bin.free(participant).bin1(:,4),1));
    recog_rt_bin.free_sum.bin1(participant,3) = sum(recog_rt_bin.free(participant).bin1(:,3),1)/(sum(recog_rt_bin.free(participant).bin1(:,1),1)+sum(recog_rt_bin.free(participant).bin1(:,3),1));
    recog_rt_bin.free_sum.bin1(participant,4) = sum(recog_rt_bin.free(participant).bin1(:,4),1)/(sum(recog_rt_bin.free(participant).bin1(:,2),1)+sum(recog_rt_bin.free(participant).bin1(:,4),1));
    
    recog_rt_bin.free_sum.bin2(participant,1) = sum(recog_rt_bin.free(participant).bin2(:,1),1)/(sum(recog_rt_bin.free(participant).bin2(:,1),1)+sum(recog_rt_bin.free(participant).bin2(:,3),1));
    recog_rt_bin.free_sum.bin2(participant,2) = sum(recog_rt_bin.free(participant).bin2(:,2),1)/(sum(recog_rt_bin.free(participant).bin2(:,2),1)+sum(recog_rt_bin.free(participant).bin2(:,4),1));
    recog_rt_bin.free_sum.bin2(participant,3) = sum(recog_rt_bin.free(participant).bin2(:,3),1)/(sum(recog_rt_bin.free(participant).bin2(:,1),1)+sum(recog_rt_bin.free(participant).bin2(:,3),1));
    recog_rt_bin.free_sum.bin2(participant,4) = sum(recog_rt_bin.free(participant).bin2(:,4),1)/(sum(recog_rt_bin.free(participant).bin2(:,2),1)+sum(recog_rt_bin.free(participant).bin2(:,4),1));
    
    recog_rt_bin.free_sum.bin3(participant,1) = sum(recog_rt_bin.free(participant).bin3(:,1),1)/(sum(recog_rt_bin.free(participant).bin3(:,1),1)+sum(recog_rt_bin.free(participant).bin3(:,3),1));
    recog_rt_bin.free_sum.bin3(participant,2) = sum(recog_rt_bin.free(participant).bin3(:,2),1)/(sum(recog_rt_bin.free(participant).bin3(:,2),1)+sum(recog_rt_bin.free(participant).bin3(:,4),1));
    recog_rt_bin.free_sum.bin3(participant,3) = sum(recog_rt_bin.free(participant).bin3(:,3),1)/(sum(recog_rt_bin.free(participant).bin3(:,1),1)+sum(recog_rt_bin.free(participant).bin3(:,3),1));
    recog_rt_bin.free_sum.bin3(participant,4) = sum(recog_rt_bin.free(participant).bin3(:,4),1)/(sum(recog_rt_bin.free(participant).bin3(:,2),1)+sum(recog_rt_bin.free(participant).bin3(:,4),1));
end
figure %17
subplot(2,1,1)
plot([1 2 3 4],recog_rt_bin.cued_sum.bin1,'yo')
hold on
plot([1 2 3 4],mean(recog_rt_bin.cued_sum.bin1,1),'ro-')
hold on
plot([1 2 3 4],recog_rt_bin.cued_sum.bin2,'c*')
hold on
plot([1 2 3 4],mean(recog_rt_bin.cued_sum.bin2,1),'b*-')
hold on
plot([1 2 3 4],recog_rt_bin.cued_sum.bin3,'g+')
hold on
plot([1 2 3 4],mean(recog_rt_bin.cued_sum.bin3,1),'m+-')
title('Changes in inv ratios per RT bin cued')
xlabel('ID&pres, ID&abs, Rej&pres, Rej&abs')
ylabel('Ratio (out of 100)')
legend('bin1:yel/red','bin2:cya/blu','bin3:gre/mag')

subplot(2,1,2)
plot([1 2 3 4],recog_rt_bin.free_sum.bin1,'yo')
hold on
plot([1 2 3 4],mean(recog_rt_bin.free_sum.bin1,1),'ro-')
hold on
plot([1 2 3 4],recog_rt_bin.free_sum.bin2,'c*')
hold on
plot([1 2 3 4],mean(recog_rt_bin.free_sum.bin2,1),'b*-')
hold on
plot([1 2 3 4],recog_rt_bin.free_sum.bin3,'g+')
hold on
plot([1 2 3 4],mean(recog_rt_bin.free_sum.bin3,1),'m+-')
title('Changes in inv ratios per RT bin free')
xlabel('ID&pres, ID&abs, Rej&pres, Rej&abs')
ylabel('Ratio (out of 100)')
legend('bin1:yel/red','bin2:cya/blu','bin3:gre/mag')

%% Post-discussion follow-ups
% Cued answer division: Correct, wrong row, not-in-array, guess
% Run recognition-test ANOVAs (see SPSS)

for participant = 1:length(pp_list)
    ana.cued_ans_div(participant).types(1:60,1:4) = 0;
    if strcmp(dat(participant).block_num(1).block_type,'cued')
        for trial = 3:32
            guess = 0;
            guess2 = 0;
            wrong_row = 0;
            wrong_row2 = 0;
            not_arr = 0;
            not_arr2 = 0;
            for entry = 1:4
                if sum(strcmp(dat(participant).block_num(1).trial(trial).recall_ans{1,entry},dat(participant).block_num(1).trial(trial).cued_let))>0 %Entry was correct
                    ana.cued_ans_div(participant).types(trial-2,1) = sum(dat(participant).block_num(1).trial(trial).recall_correct(1:2));
                elseif strcmp(dat(participant).block_num(1).trial(trial).recall_ans{1,entry},'') %Entry was a guess/incomplete
                    guess = guess+1;
                    ana.cued_ans_div(participant).types(trial-2,4) = guess;
                elseif sum(strcmp(dat(participant).block_num(1).trial(trial).recall_ans{1,entry},dat(participant).block_num(1).trial(trial).let_list))>0 || strcmp(dat(participant).block_num(1).trial(trial).recall_ans{1,entry},dat(participant).block_num(1).trial(trial).inv_letter) %Entry was wrong row
                    wrong_row = wrong_row+1;
                    ana.cued_ans_div(participant).types(trial-2,2) = wrong_row;
                else %Entry was completely wrong
                    not_arr = not_arr+1;
                    ana.cued_ans_div(participant).types(trial-2,3) = not_arr;
                end
                if sum(strcmp(dat(participant).block_num(3).trial(trial).recall_ans{1,entry},dat(participant).block_num(3).trial(trial).cued_let))>0 %Entry was correct
                    ana.cued_ans_div(participant).types(trial-2+30,1) = sum(dat(participant).block_num(3).trial(trial).recall_correct(1:2));
                elseif strcmp(dat(participant).block_num(3).trial(trial).recall_ans{1,entry},'') %Entry was a guess/incomplete
                    guess2 = guess2+1;
                    ana.cued_ans_div(participant).types(trial-2+30,4) = guess2;
                elseif sum(strcmp(dat(participant).block_num(3).trial(trial).recall_ans{1,entry},dat(participant).block_num(3).trial(trial).let_list))>0 || strcmp(dat(participant).block_num(3).trial(trial).recall_ans{1,entry},dat(participant).block_num(3).trial(trial).inv_letter)%Entry was wrong row
                    wrong_row2 = wrong_row2+1;
                    ana.cued_ans_div(participant).types(trial-2+30,2) = wrong_row2;
                else %Entry was completely wrong
                    not_arr2 = not_arr2+1;
                    ana.cued_ans_div(participant).types(trial-2+30,3) = not_arr2;
                end
            end
        end
        if sum(ana.cued_ans_div(participant).types(trial-2,:))~=4 || sum(ana.cued_ans_div(participant).types(trial-2+30,:))~=4
            disp('Warning! Too many answers for participant')
            disp(participant)
            disp(trial-2)
            disp(trial+28)
        end
    else
        for trial = 3:32
            guess = 0;
            guess2 = 0;
            wrong_row = 0;
            wrong_row2 = 0;
            not_arr = 0;
            not_arr2 = 0;
            for entry = 1:4
                if sum(strcmp(dat(participant).block_num(2).trial(trial).recall_ans{1,entry},dat(participant).block_num(2).trial(trial).cued_let))>0 %Entry was correct
                    ana.cued_ans_div(participant).types(trial-2,1) = sum(dat(participant).block_num(2).trial(trial).recall_correct(1:2));
                elseif strcmp(dat(participant).block_num(2).trial(trial).recall_ans{1,entry},'') %Entry was a guess/incomplete
                    guess = guess+1;
                    ana.cued_ans_div(participant).types(trial-2,4) = guess;
                elseif sum(strcmp(dat(participant).block_num(2).trial(trial).recall_ans{1,entry},dat(participant).block_num(2).trial(trial).let_list))>0 || strcmp(dat(participant).block_num(2).trial(trial).recall_ans{1,entry},dat(participant).block_num(2).trial(trial).inv_letter) %Entry was wrong row
                    wrong_row = wrong_row+1;
                    ana.cued_ans_div(participant).types(trial-2,2) = wrong_row;
                else %Entry was completely wrong
                    not_arr = not_arr+1;
                    ana.cued_ans_div(participant).types(trial-2,3) = not_arr;
                end
                if sum(strcmp(dat(participant).block_num(4).trial(trial).recall_ans{1,entry},dat(participant).block_num(4).trial(trial).cued_let))>0 %Entry was correct
                    ana.cued_ans_div(participant).types(trial-2+30,1) = sum(dat(participant).block_num(4).trial(trial).recall_correct(1:2));
                elseif strcmp(dat(participant).block_num(4).trial(trial).recall_ans{1,entry},'') %Entry was a guess/incomplete
                    guess2 = guess2+1;
                    ana.cued_ans_div(participant).types(trial-2+30,4) = guess2;
                elseif sum(strcmp(dat(participant).block_num(4).trial(trial).recall_ans{1,entry},dat(participant).block_num(4).trial(trial).let_list))>0 || strcmp(dat(participant).block_num(4).trial(trial).recall_ans{1,entry},dat(participant).block_num(4).trial(trial).inv_letter) %Entry was wrong row
                    wrong_row2 = wrong_row2+1;
                    ana.cued_ans_div(participant).types(trial-2+30,2) = wrong_row2;
                else %Entry was completely wrong
                    not_arr2 = not_arr2+1;
                    ana.cued_ans_div(participant).types(trial-2+30,3) = not_arr2;
                end
            end
        end
        if sum(ana.cued_ans_div(participant).types(trial-2,:))~=4 || sum(ana.cued_ans_div(participant).types(trial-2+30,:))~=4
            disp('Warning! Too many answers for participant')
            disp(participant)
            disp(trial-2)
            disp(trial+28)
        end
    end
    ana.cued_ans_div_mean(participant,1) = mean(ana.cued_ans_div(participant).types(:,1),1);
    ana.cued_ans_div_mean(participant,2) = mean(ana.cued_ans_div(participant).types(:,2),1);
    ana.cued_ans_div_mean(participant,3) = mean(ana.cued_ans_div(participant).types(:,3),1);
    ana.cued_ans_div_mean(participant,4) = mean(ana.cued_ans_div(participant).types(:,4),1);
end
figure %18
plot([1 2 3 4],ana.cued_ans_div_mean,'ko')
hold on
plot([1 2 3 4],mean(ana.cued_ans_div_mean,1),'ro')
title('Cued recall entries')
xlabel('Correct, wrong row, incorrect, guess')
ylabel('Subject average per trial')

% Redo test3/hyp analysis: Subtract the not-shown values from the inv and not-inv values to see what kind of numbers remain.
    %Cued inv
ana.hyp_count.cor_inv(:,1) = ana.hyp_count.inv(:,2)-ana.hyp_count.n_shown(:,1); %Inv_option ID&upr minus not_shown option ID&upr
ana.hyp_count.cor_inv(:,2) = ana.hyp_count.inv(:,1)-ana.hyp_count.n_shown(:,2); %Inv_option ID&inv minus not_shown option ID&inv
    %Cued not-inverted
ana.hyp_count.cor_n_inv(:,1) = ana.hyp_count.n_inv(:,1)-ana.hyp_count.n_shown(:,1); %N_inv_option ID&upr minus not_shown_option ID&upr
ana.hyp_count.cor_n_inv(:,2) = ana.hyp_count.n_inv(:,2)-ana.hyp_count.n_shown(:,2); %N_inv_option id&inv minus not_shown_option i^&inv
    %Free inv
ana.hyp_count.cor_inv(:,3) = ana.hyp_count.inv(:,6)-ana.hyp_count.n_shown(:,5); %inv option id&upr - n_shown option id&upr for free
ana.hyp_count.cor_inv(:,4) = ana.hyp_count.inv(:,5)-ana.hyp_count.n_shown(:,6);
    %Free not-inverted
ana.hyp_count.cor_n_inv(:,3) = ana.hyp_count.n_inv(:,5)-ana.hyp_count.n_shown(:,5);
ana.hyp_count.cor_n_inv(:,4) = ana.hyp_count.n_inv(:,6)-ana.hyp_count.n_shown(:,6);

figure %19
subplot(1,2,1)
plot([1 2],ana.hyp_count.cor_inv(:,1:2),'yo')
hold on
plot([1 2],mean(ana.hyp_count.cor_inv(:,1:2),1),'ro')
hold on
plot([1 2],ana.hyp_count.cor_n_inv(:,1:2),'c*')
hold on
plot([1 2],mean(ana.hyp_count.cor_n_inv(:,1:2),1),'b*')
title('Corrected upr and inv selections')
xlabel('Cued: id&upr, id&inv')
ylabel('(N)inv_option - nshown option')
legend('yel-Inv','red-M(inv)','cya-Ninv','blu-M(ninv)')

subplot(1,2,2)
plot([1 2],ana.hyp_count.cor_inv(:,3:4),'yo')
hold on
plot([1 2],mean(ana.hyp_count.cor_inv(:,3:4),1),'ro')
hold on
plot([1 2],ana.hyp_count.cor_n_inv(:,3:4),'c*')
hold on
plot([1 2],mean(ana.hyp_count.cor_n_inv(:,3:4),1),'b*')
xlabel('Free: id&upr, id&inv')
ylabel('(N)inv_option - nshown option')
legend('yel-Inv','red-M(inv)','cya-Ninv','red-M(ninv)')
