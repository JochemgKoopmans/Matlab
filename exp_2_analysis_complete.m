%% CNS Internship Data Processing Pipeline: Exp2 recog 2
%Jochem Koopmans

%% clear and close
clear
close all

%% List of participants; organisational data
% 44, 49 removed for not doing task properly
% PPs with 'c' are recoded because of spaced answers
tab_list = {'1','2','3','4','5','6','7','8','9','10','11','12c','13','14','15','16','17','18','19','20','21',...
    '22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40','41','42',...
    '43','45','46','47','48c'};
row_focus_list = {'1','2','3','15','25','35'};

%%Organising data
block_starts = [26 207 388 569];
UPR_2corr = zeros(length(tab_list),5); %Trial-selection follow-up: 2+ entries correct
INV_2corr = zeros(length(tab_list),5); %Trial count, sum(targ_upr,targ_inv,foil_upr,foil_inv)
UPR_nonfoc = zeros(length(tab_list),5); %Trial-selection follow-up: 2+ entries non-targ row
INV_nonfoc = zeros(length(tab_list),5);
UPR_foc = zeros(length(tab_list),5); %Attention strategy follow-up: 2+ entries from targ row
INV_foc = zeros(length(tab_list),5);
UPR_targfoc = zeros(length(tab_list),5); %Attention strategy follow-up: 2+ ent from targ row & targ entered
INV_targfoc = zeros(length(tab_list),5);
spss_ma = zeros(length(tab_list),52);
spss_fu = zeros(length(tab_list),52);
gender = [0,0,0];
age = zeros(length(tab_list),1);
recall = zeros(length(tab_list),5);
recog = zeros(length(tab_list),5);
recog_upr_block = zeros(length(tab_list),16);
recog_inv_block = zeros(length(tab_list),16);
recog_upr = zeros(length(tab_list),4);
recog_inv = zeros(length(tab_list),4);
recog_upr_3bl = zeros(length(tab_list),4);
recog_inv_3bl = zeros(length(tab_list),4);
durations = zeros(length(tab_list),6);
bl_dur = zeros(length(tab_list),4);

%% Importing data from subject data files
for pp = 1:length(tab_list)
    disp('Participant:')
    disp(pp)
    if sum(strcmp(tab_list(pp),row_focus_list))>0
        dat(pp).row_focus = 1;
        spss_ma(pp,1) = 1;
        spss_fu(pp,1) = 1;
    else
        dat(pp).row_focus = 0;
        spss_ma(pp,1) = 0;
        spss_fu(pp,1) = 0;
    end
    %% Import datafile
    subj_data = importfile1('data.xlsx',tab_list{1,pp});
    
    %% Subject information
    delim = [];
    for count = 11:length(subj_data{7,7}{1,1})
        if strcmp(',',subj_data{7,7}{1,1}(count))
            delim(end+1)=count;
        end
    end
    dat(pp).age = str2num(subj_data{7,7}{1,1}(delim(1)+8:delim(2)-2));
    age(pp,1) = str2num(subj_data{7,7}{1,1}(delim(1)+8:delim(2)-2));
    spss_ma(pp,2) = str2num(subj_data{7,7}{1,1}(delim(1)+8:delim(2)-2));
    dat(pp).gender = subj_data{7,7}{1,1}(delim(2)+11:length(subj_data{7,7}{1,1})-2);
    female = {'f','v','w'};
    if pp == 6;
        gender(3) = gender(3)+1;
        spss_ma(pp,3) = 2;
    elseif sum(strcmpi(dat(pp).gender(1),female))>0 %CHECK that this works for a larger dataset as well (e.g. entries 'vrouw')
        gender(2) = gender(2)+1;
        spss_ma(pp,3) = 0; % 0 is for female
    elseif strcmpi(dat(pp).gender(1),'m')
        gender(1) = gender(1)+1;
        spss_ma(pp,3) = 1; % 1 is for male
    else
        gender(3) = gender(3)+1;
        spss_ma(pp,3) = 2; % 2 is for other
    end
    %% Extract relevant information first
    % Recall performance
    dat(pp).recall(1) = str2double(subj_data{202,37});
    dat(pp).recall(2) = str2double(subj_data{383,37});
    dat(pp).recall(3) = str2double(subj_data{564,37});
    dat(pp).recall(4) = str2double(subj_data{745,37});
    recall(pp,1) = str2double(subj_data{202,37});
    recall(pp,2) = str2double(subj_data{383,37});
    recall(pp,3) = str2double(subj_data{564,37});
    recall(pp,4) = str2double(subj_data{745,37});
    recall(pp,5) = mean(recall(pp,1:4),2);
    % Recog performance
    dat(pp).recog(1) = str2double(subj_data{202,38});
    dat(pp).recog(2) = str2double(subj_data{383,38});
    dat(pp).recog(3) = str2double(subj_data{564,38});
    dat(pp).recog(4) = str2double(subj_data{745,38});
    recog(pp,1) = str2double(subj_data{202,38});
    recog(pp,2) = str2double(subj_data{383,38});
    recog(pp,3) = str2double(subj_data{564,38});
    recog(pp,4) = str2double(subj_data{745,38});
    recog(pp,5) = mean(recog(pp,1:4),2);
    % Recog ratios; columns indicate targ_upr, targ_inv, foil_upr, foil_inv, rows correspond to the blocks.
    delim = [];
    for count = 17:57
        if strcmp(subj_data{202,36}{1,1}(count),',')
            delim(end+1) = count;
        end
    end
    %Rows are the blocks, columns show target-upright, target-upside-down,
    %foil-upright, foil-upside-down selections
    dat(pp).recog_rates.upr_trial(1,1) = str2double(subj_data{202,36}{1,1}(16:delim(1)-1));
    dat(pp).recog_rates.upr_trial(1,2) = str2double(subj_data{202,36}{1,1}(delim(1)+1:delim(2)-1));
    dat(pp).recog_rates.upr_trial(1,3) = str2double(subj_data{202,36}{1,1}(delim(2)+1:delim(3)-1));
    dat(pp).recog_rates.upr_trial(1,4) = str2double(subj_data{202,36}{1,1}(delim(3)+1:delim(4)-2));
    spss_ma(pp,21) = str2double(subj_data{202,36}{1,1}(16:delim(1)-1))/.15; %Turns selections into percentage
    spss_ma(pp,22) = str2double(subj_data{202,36}{1,1}(delim(1)+1:delim(2)-1))/.15;
    spss_ma(pp,23) = str2double(subj_data{202,36}{1,1}(delim(2)+1:delim(3)-1))/.15;
    spss_ma(pp,24) = str2double(subj_data{202,36}{1,1}(delim(3)+1:delim(4)-2))/.15;
    
    dat(pp).recog_rates.upr_trial(2,1) = str2double(subj_data{202,36}{1,1}(delim(4)+2:delim(5)-1));
    dat(pp).recog_rates.upr_trial(2,2) = str2double(subj_data{202,36}{1,1}(delim(5)+1:delim(6)-1));
    dat(pp).recog_rates.upr_trial(2,3) = str2double(subj_data{202,36}{1,1}(delim(6)+1:delim(7)-1));
    dat(pp).recog_rates.upr_trial(2,4) = str2double(subj_data{202,36}{1,1}(delim(7)+1:delim(8)-2));
    spss_ma(pp,25) = str2double(subj_data{202,36}{1,1}(delim(4)+2:delim(5)-1))/.15;
    spss_ma(pp,26) = str2double(subj_data{202,36}{1,1}(delim(5)+1:delim(6)-1))/.15;
    spss_ma(pp,27) = str2double(subj_data{202,36}{1,1}(delim(6)+1:delim(7)-1))/.15;
    spss_ma(pp,28) = str2double(subj_data{202,36}{1,1}(delim(7)+1:delim(8)-2))/.15;
    
    dat(pp).recog_rates.upr_trial(3,1) = str2double(subj_data{202,36}{1,1}(delim(8)+2:delim(9)-1));
    dat(pp).recog_rates.upr_trial(3,2) = str2double(subj_data{202,36}{1,1}(delim(9)+1:delim(10)-1));
    dat(pp).recog_rates.upr_trial(3,3) = str2double(subj_data{202,36}{1,1}(delim(10)+1:delim(11)-1));
    dat(pp).recog_rates.upr_trial(3,4) = str2double(subj_data{202,36}{1,1}(delim(11)+1:delim(12)-2));
    spss_ma(pp,29) = str2double(subj_data{202,36}{1,1}(delim(8)+2:delim(9)-1))/.15;
    spss_ma(pp,30) = str2double(subj_data{202,36}{1,1}(delim(9)+1:delim(10)-1))/.15;
    spss_ma(pp,31) = str2double(subj_data{202,36}{1,1}(delim(10)+1:delim(11)-1))/.15;
    spss_ma(pp,32) = str2double(subj_data{202,36}{1,1}(delim(11)+1:delim(12)-2))/.15;
    
    dat(pp).recog_rates.upr_trial(4,1) = str2double(subj_data{202,36}{1,1}(delim(12)+2:delim(13)-1));
    dat(pp).recog_rates.upr_trial(4,2) = str2double(subj_data{202,36}{1,1}(delim(13)+1:delim(14)-1));
    dat(pp).recog_rates.upr_trial(4,3) = str2double(subj_data{202,36}{1,1}(delim(14)+1:delim(15)-1));
    dat(pp).recog_rates.upr_trial(4,4) = str2double(subj_data{202,36}{1,1}(delim(15)+1:delim(16)-3));
    spss_ma(pp,33) = str2double(subj_data{202,36}{1,1}(delim(12)+2:delim(13)-1))/.15;
    spss_ma(pp,34) = str2double(subj_data{202,36}{1,1}(delim(13)+1:delim(14)-1))/.15;
    spss_ma(pp,35) = str2double(subj_data{202,36}{1,1}(delim(14)+1:delim(15)-1))/.15;
    spss_ma(pp,36) = str2double(subj_data{202,36}{1,1}(delim(15)+1:delim(16)-3))/.15;
    
    %Inverted trials:
    delim = [];
    for count = 67:(length(subj_data{202,36}{1,1})-3)
        if (strcmp(subj_data{202,36}{1,1}(count),',') || strcmp(subj_data{202,36}{1,1}(count),':'))
            delim(end+1) = count;
        end
    end
    dat(pp).recog_rates.inv_trial(1,1) = str2double(subj_data{202,36}{1,1}(delim(1)+3:delim(2)-1));
    dat(pp).recog_rates.inv_trial(1,2) = str2double(subj_data{202,36}{1,1}(delim(2)+1:delim(3)-1));
    dat(pp).recog_rates.inv_trial(1,3) = str2double(subj_data{202,36}{1,1}(delim(3)+1:delim(4)-1));
    dat(pp).recog_rates.inv_trial(1,4) = str2double(subj_data{202,36}{1,1}(delim(4)+1:delim(5)-2));
    spss_ma(pp,37) = str2double(subj_data{202,36}{1,1}(delim(1)+3:delim(2)-1))/.15;
    spss_ma(pp,38) = str2double(subj_data{202,36}{1,1}(delim(2)+1:delim(3)-1))/.15;
    spss_ma(pp,39) = str2double(subj_data{202,36}{1,1}(delim(3)+1:delim(4)-1))/.15;
    spss_ma(pp,40) = str2double(subj_data{202,36}{1,1}(delim(4)+1:delim(5)-2))/.15;
    
    dat(pp).recog_rates.inv_trial(2,1) = str2double(subj_data{202,36}{1,1}(delim(5)+2:delim(6)-1));
    dat(pp).recog_rates.inv_trial(2,2) = str2double(subj_data{202,36}{1,1}(delim(6)+1:delim(7)-1));
    dat(pp).recog_rates.inv_trial(2,3) = str2double(subj_data{202,36}{1,1}(delim(7)+1:delim(8)-1));
    dat(pp).recog_rates.inv_trial(2,4) = str2double(subj_data{202,36}{1,1}(delim(8)+1:delim(9)-2));
    spss_ma(pp,41) = str2double(subj_data{202,36}{1,1}(delim(5)+2:delim(6)-1))/.15;
    spss_ma(pp,42) = str2double(subj_data{202,36}{1,1}(delim(6)+1:delim(7)-1))/.15;
    spss_ma(pp,43) = str2double(subj_data{202,36}{1,1}(delim(7)+1:delim(8)-1))/.15;
    spss_ma(pp,44) = str2double(subj_data{202,36}{1,1}(delim(8)+1:delim(9)-2))/.15;
    
    dat(pp).recog_rates.inv_trial(3,1) = str2double(subj_data{202,36}{1,1}(delim(9)+2:delim(10)-1));
    dat(pp).recog_rates.inv_trial(3,2) = str2double(subj_data{202,36}{1,1}(delim(10)+1:delim(11)-1));
    dat(pp).recog_rates.inv_trial(3,3) = str2double(subj_data{202,36}{1,1}(delim(11)+1:delim(12)-1));
    dat(pp).recog_rates.inv_trial(3,4) = str2double(subj_data{202,36}{1,1}(delim(12)+1:delim(13)-2));
    spss_ma(pp,45) = str2double(subj_data{202,36}{1,1}(delim(9)+2:delim(10)-1))/.15;
    spss_ma(pp,46) = str2double(subj_data{202,36}{1,1}(delim(10)+1:delim(11)-1))/.15;
    spss_ma(pp,47) = str2double(subj_data{202,36}{1,1}(delim(11)+1:delim(12)-1))/.15;
    spss_ma(pp,48) = str2double(subj_data{202,36}{1,1}(delim(12)+1:delim(13)-2))/.15;
    
    dat(pp).recog_rates.inv_trial(4,1) = str2double(subj_data{202,36}{1,1}(delim(13)+2:delim(14)-1));
    dat(pp).recog_rates.inv_trial(4,2) = str2double(subj_data{202,36}{1,1}(delim(14)+1:delim(15)-1));
    dat(pp).recog_rates.inv_trial(4,3) = str2double(subj_data{202,36}{1,1}(delim(15)+1:delim(16)-1));
    dat(pp).recog_rates.inv_trial(4,4) = str2double(subj_data{202,36}{1,1}(delim(16)+1:end-3));
    spss_ma(pp,49) = str2double(subj_data{202,36}{1,1}(delim(13)+2:delim(14)-1))/.15;
    spss_ma(pp,50) = str2double(subj_data{202,36}{1,1}(delim(14)+1:delim(15)-1))/.15;
    spss_ma(pp,51) = str2double(subj_data{202,36}{1,1}(delim(15)+1:delim(16)-1))/.15;
    spss_ma(pp,52) = str2double(subj_data{202,36}{1,1}(delim(16)+1:end-3))/.15;
    
    %Recog figurable numbers
    for alt = 1:4
        recog_upr_block(pp,alt) = dat(pp).recog_rates.upr_trial(1,alt);
        recog_upr_block(pp,alt+4) = dat(pp).recog_rates.upr_trial(2,alt);
        recog_upr_block(pp,alt+8) = dat(pp).recog_rates.upr_trial(3,alt);
        recog_upr_block(pp,alt+12) = dat(pp).recog_rates.upr_trial(4,alt);
        
        recog_inv_block(pp,alt) = dat(pp).recog_rates.inv_trial(1,alt);
        recog_inv_block(pp,alt+4) = dat(pp).recog_rates.inv_trial(2,alt);
        recog_inv_block(pp,alt+8) = dat(pp).recog_rates.inv_trial(3,alt);
        recog_inv_block(pp,alt+12) = dat(pp).recog_rates.inv_trial(4,alt);
        %Averages selections per recog option over blocks
        recog_upr(pp,alt) = sum(dat(pp).recog_rates.upr_trial(:,alt));
        recog_inv(pp,alt) = sum(dat(pp).recog_rates.inv_trial(:,alt));
        %Averages selections per recog option over last three blocks
        recog_upr_3bl(pp,alt) = sum(dat(pp).recog_rates.upr_trial(2:4,alt));
        recog_inv_3bl(pp,alt) = sum(dat(pp).recog_rates.inv_trial(2:4,alt));
    end
    
    %Cued answer option types
    colons = [];
    delim = [];
    for count = 17:length(subj_data{202,35}{1,1})
        if strcmp(subj_data{202,35}{1,1}(count),':')
            colons(end+1) = count;
        elseif strcmp(subj_data{202,35}{1,1}(count),',')
            delim(end+1) = count;
        end
    end
    dat(pp).recall_rates.cor_place(1) = str2double(subj_data{202,35}{1,1}(colons(1)+2:delim(1)-1));
    dat(pp).recall_rates.cor_place(2) = str2double(subj_data{202,35}{1,1}(delim(1)+1:delim(2)-1));
    dat(pp).recall_rates.cor_place(3) = str2double(subj_data{202,35}{1,1}(delim(2)+1:delim(3)-1));
    dat(pp).recall_rates.cor_place(4) = str2double(subj_data{202,35}{1,1}(delim(3)+1:delim(4)-2));
    
    dat(pp).recall_rates.cor_row(1) = str2double(subj_data{202,35}{1,1}(colons(2)+2:delim(5)-1));
    dat(pp).recall_rates.cor_row(2) = str2double(subj_data{202,35}{1,1}(delim(5)+1:delim(6)-1));
    dat(pp).recall_rates.cor_row(3) = str2double(subj_data{202,35}{1,1}(delim(6)+1:delim(7)-1));
    dat(pp).recall_rates.cor_row(4) = str2double(subj_data{202,35}{1,1}(delim(7)+1:delim(8)-2));
    
    dat(pp).recall_rates.in_grid(1) = str2double(subj_data{202,35}{1,1}(colons(3)+2:delim(9)-1));
    dat(pp).recall_rates.in_grid(2) = str2double(subj_data{202,35}{1,1}(delim(9)+1:delim(10)-1));
    dat(pp).recall_rates.in_grid(3) = str2double(subj_data{202,35}{1,1}(delim(10)+1:delim(11)-1));
    dat(pp).recall_rates.in_grid(4) = str2double(subj_data{202,35}{1,1}(delim(11)+1:delim(12)-2));
    
    dat(pp).recall_rates.n_in_grid(1) = str2double(subj_data{202,35}{1,1}(colons(4)+2:delim(13)-1));
    dat(pp).recall_rates.n_in_grid(2) = str2double(subj_data{202,35}{1,1}(delim(13)+1:delim(14)-1));
    dat(pp).recall_rates.n_in_grid(3) = str2double(subj_data{202,35}{1,1}(delim(14)+1:delim(15)-1));
    dat(pp).recall_rates.n_in_grid(4) = str2double(subj_data{202,35}{1,1}(delim(15)+1:delim(16)-2));
    
    dat(pp).recall_rates.not_entered(1) = str2double(subj_data{202,35}{1,1}(colons(5)+2:delim(17)-1));
    dat(pp).recall_rates.not_entered(2) = str2double(subj_data{202,35}{1,1}(delim(17)+1:delim(18)-1));
    dat(pp).recall_rates.not_entered(3) = str2double(subj_data{202,35}{1,1}(delim(18)+1:delim(19)-1));
    dat(pp).recall_rates.not_entered(4) = str2double(subj_data{202,35}{1,1}(delim(19)+1:end-2));
    
    %% Experiment durations: Instructions, bl1:4 and tot
    durations(pp,1) = subj_data{21,3}/60000; %after instructions
    durations(pp,2) = subj_data{202,3}/60000; %after block 1
    durations(pp,3) = subj_data{383,3}/60000; %after block 2
    durations(pp,4) = subj_data{564,3}/60000; %after block 3
    durations(pp,5) = subj_data{745,3}/60000; %after block 4
    durations(pp,6) = subj_data{747,3}/60000; %End of exp
    
    bl_dur(pp,1) = durations(pp,2)-durations(pp,1);
    bl_dur(pp,2) = durations(pp,3)-durations(pp,2);
    bl_dur(pp,3) = durations(pp,4)-durations(pp,3);
    bl_dur(pp,4) = durations(pp,5)-durations(pp,4);
    
    %% Trial selection and -rejection
    for bl = 1:4
        tally_UPR = 0;
        tally_INV = 0;
        for count = 0:6:174 %Every new answer is 6 rows down from the previous
            targ_ind = subj_data{count+block_starts(bl),20}{1,1} + 1;
            sel_option = subj_data{count+block_starts(bl)+1,33};
            targ_row_ent = 0;
            ntarg_row_ent = 0;
            targ_ent = 0;
            entries = {};
            %Listing subject entries
            for i = 14:length(subj_data{count+block_starts(bl),7}{1,1})
                if strcmp(subj_data{count+block_starts(bl),7}{1,1}(i),'"')
                    break
                elseif sum(strcmp(subj_data{count+block_starts(bl),7}{1,1}(i),{' ' ',' ';'}))>0
                    continue
                else
                    entries{1,end+1} = subj_data{count+block_starts(bl),7}{1,1}(i);
                    if length(entries)==4
                        break
                    end
                end
            end
            if (subj_data{count+block_starts(bl),19}{1,1} == 0) % Trial is UPR
                tally_UPR = tally_UPR +1;
                %Condition-level correctness
                dat(pp).block(bl).upr(tally_UPR,1) = subj_data{count+block_starts(bl),24} + ...
                    subj_data{count+block_starts(bl),25}; %Number of correct entries
                dat(pp).block(bl).upr(tally_UPR,2) = sel_option; %Selected recognition option (0-3)
                dat(pp).block(bl).upr(tally_UPR,3) = strcmp(subj_data{count+block_starts(bl)+1,31},...
                    subj_data{count+block_starts(bl)+1,32});
                if (dat(pp).block(bl).upr(tally_UPR,1) > 1) %At least two entries were correct
                    UPR_2corr(pp,1) = UPR_2corr(pp,1) + 1;
                    UPR_2corr(pp,sel_option+2) = UPR_2corr(pp,sel_option+2) + 1;
                end
                %Follow-up analyses: >1corr, non-targ row entries, targ row entries, -with targ entered
                grid = {subj_data{count+block_starts(bl),14}{1,1}(3) subj_data{count+block_starts(bl),14}{1,1}(7) ...
                    subj_data{count+block_starts(bl),14}{1,1}(11) subj_data{count+block_starts(bl),14}{1,1}(15) ...
                    subj_data{count+block_starts(bl),14}{1,1}(19) subj_data{count+block_starts(bl),14}{1,1}(23) ...
                    subj_data{count+block_starts(bl),14}{1,1}(27) subj_data{count+block_starts(bl),14}{1,1}(31) ...
                    subj_data{count+block_starts(bl),14}{1,1}(35) subj_data{count+block_starts(bl),14}{1,1}(39) ...
                    subj_data{count+block_starts(bl),14}{1,1}(43) subj_data{count+block_starts(bl),14}{1,1}(47)};
                %Checking subj entries against target row and target letter
                for i = 1:length(entries)
                    if targ_ind == find(strcmpi(entries{1,i},grid))
                        targ_ent = 1;
                        targ_row_ent = targ_row_ent + 1;
                    elseif ceil(targ_ind/4) == ceil(find(strcmpi(entries{1,i},grid))/4)
                        targ_row_ent = targ_row_ent + 1;
                    elseif sum(strcmpi(entries{1,i},grid)) > 0
                        ntarg_row_ent = ntarg_row_ent + 1;
                    end
                end
                if ntarg_row_ent > 1 && targ_row_ent == 0
                    UPR_nonfoc(pp,1)  = UPR_nonfoc(pp,1) + 1;
                    UPR_nonfoc(pp,sel_option+2) = UPR_nonfoc(pp,sel_option+2) + 1;
                elseif targ_row_ent > 1
                    UPR_foc(pp,1) = UPR_foc(pp,1) + 1;
                    UPR_foc(pp,sel_option+2) = UPR_foc(pp,sel_option+2) + 1;
                    if targ_ent == 1
                        UPR_targfoc(pp,1) = UPR_targfoc(pp,1) + 1;
                        UPR_targfoc(pp,sel_option+2) = UPR_targfoc(pp,sel_option+2) + 1;
                    end
                end
            else % Trial is INV
                tally_INV = tally_INV +1;
                dat(pp).block(bl).inv(tally_INV,1) = subj_data{count+block_starts(bl),24} + ...
                    subj_data{count+block_starts(bl),25};
                dat(pp).block(bl).inv(tally_INV,2) = sel_option; %Selected recognition option (0-3)
                dat(pp).block(bl).inv(tally_INV,3) = strcmp(subj_data{count+block_starts(bl)+1,31},...
                    subj_data{count+block_starts(bl)+1,32});
                if (dat(pp).block(bl).inv(tally_INV,1) > 1) % At least two entries were correct
                    INV_2corr(pp,1) = INV_2corr(pp,1) + 1;
                    INV_2corr(pp,sel_option+2) = INV_2corr(pp,sel_option+2) + 1;
                end
                delim = [3 7 11 15 19 23 27 31 35 39 43 47]; %The standard non-inv grid letter positions in subj_data
                if targ_ind < 12
                    for i = targ_ind:11
                        delim(i+1) = delim(i+1)+4;
                    end
                end
                grid = {subj_data{count+block_starts(bl),14}{1,1}(delim(1)) subj_data{count+block_starts(bl),14}{1,1}(delim(2)) ...
                    subj_data{count+block_starts(bl),14}{1,1}(delim(3)) subj_data{count+block_starts(bl),14}{1,1}(delim(4)) ...
                    subj_data{count+block_starts(bl),14}{1,1}(delim(5)) subj_data{count+block_starts(bl),14}{1,1}(delim(6)) ...
                    subj_data{count+block_starts(bl),14}{1,1}(delim(7)) subj_data{count+block_starts(bl),14}{1,1}(delim(8)) ...
                    subj_data{count+block_starts(bl),14}{1,1}(delim(9)) subj_data{count+block_starts(bl),14}{1,1}(delim(10)) ...
                    subj_data{count+block_starts(bl),14}{1,1}(delim(11)) subj_data{count+block_starts(bl),14}{1,1}(delim(12))};
                %Checking subj entries against target row and target letter
                for i = 1:length(entries)
                    if targ_ind == find(strcmpi(entries{1,i},grid))
                        targ_ent = 1;
                        targ_row_ent = targ_row_ent + 1;
                    elseif ceil(targ_ind/4) == ceil(find(strcmpi(entries{1,i},grid))/4)
                        targ_row_ent = targ_row_ent + 1;
                    elseif sum(strcmpi(entries{1,i},grid)) > 0
                        ntarg_row_ent = ntarg_row_ent + 1;
                    end
                end
                if ntarg_row_ent > 1 && targ_row_ent == 0
                    INV_nonfoc(pp,1)  = INV_nonfoc(pp,1) + 1;
                    INV_nonfoc(pp,sel_option+2) = INV_nonfoc(pp,sel_option+2) + 1;
                elseif targ_row_ent > 1
                    INV_foc(pp,1) = INV_foc(pp,1) + 1;
                    INV_foc(pp,sel_option+2) = INV_foc(pp,sel_option+2) + 1;
                    if targ_ent == 1
                        INV_targfoc(pp,1) = INV_targfoc(pp,1) + 1;
                        INV_targfoc(pp,sel_option+2) = INV_targfoc(pp,sel_option+2) + 1;
                    end
                end
            end
        end
    end
    spss_ma(pp,5) = sum(dat(pp).block(1).upr(:,1))/.6; % Recall performance block 1 (percentage)
    spss_ma(pp,6) = sum(dat(pp).block(2).upr(:,1))/.6;
    spss_ma(pp,7) = sum(dat(pp).block(3).upr(:,1))/.6;
    spss_ma(pp,8) = sum(dat(pp).block(4).upr(:,1))/.6;
    spss_ma(pp,9) = sum(dat(pp).block(1).inv(:,1))/.6;
    spss_ma(pp,10) = sum(dat(pp).block(2).inv(:,1))/.6;
    spss_ma(pp,11) = sum(dat(pp).block(3).inv(:,1))/.6;
    spss_ma(pp,12) = sum(dat(pp).block(4).inv(:,1))/.6;
    
    spss_ma(pp,13) = mean(dat(pp).block(1).upr(:,3))*100; % Recog performance block 1 (percentage)
    spss_ma(pp,14) = mean(dat(pp).block(2).upr(:,3))*100;
    spss_ma(pp,15) = mean(dat(pp).block(3).upr(:,3))*100;
    spss_ma(pp,16) = mean(dat(pp).block(4).upr(:,3))*100;
    spss_ma(pp,17) = mean(dat(pp).block(1).inv(:,3))*100;
    spss_ma(pp,18) = mean(dat(pp).block(2).inv(:,3))*100;
    spss_ma(pp,19) = mean(dat(pp).block(3).inv(:,3))*100;
    spss_ma(pp,20) = mean(dat(pp).block(4).inv(:,3))*100;
    if UPR_2corr(pp,1) ~= 0
        UPR_2corr(pp,2) = UPR_2corr(pp,2)/UPR_2corr(pp,1);
        UPR_2corr(pp,3) = UPR_2corr(pp,3)/UPR_2corr(pp,1);
        UPR_2corr(pp,4) = UPR_2corr(pp,4)/UPR_2corr(pp,1);
        UPR_2corr(pp,5) = UPR_2corr(pp,5)/UPR_2corr(pp,1);
    else
        UPR_2corr(pp,2:5) = NaN;
    end
    if INV_2corr(pp,1) ~= 0
        INV_2corr(pp,2) = INV_2corr(pp,2)/INV_2corr(pp,1);
        INV_2corr(pp,3) = INV_2corr(pp,3)/INV_2corr(pp,1);
        INV_2corr(pp,4) = INV_2corr(pp,4)/INV_2corr(pp,1);
        INV_2corr(pp,5) = INV_2corr(pp,5)/INV_2corr(pp,1);
    else
        INV_2corr(pp,2:5) = NaN;
    end
    if UPR_nonfoc(pp,1) ~= 0
        UPR_nonfoc(pp,2) = UPR_nonfoc(pp,2)/UPR_nonfoc(pp,1);
        UPR_nonfoc(pp,3) = UPR_nonfoc(pp,3)/UPR_nonfoc(pp,1);
        UPR_nonfoc(pp,4) = UPR_nonfoc(pp,4)/UPR_nonfoc(pp,1);
        UPR_nonfoc(pp,5) = UPR_nonfoc(pp,5)/UPR_nonfoc(pp,1);
    else
        UPR_nonfoc(pp,2:5) = NaN;
    end
    if INV_nonfoc(pp,1) ~= 0
        INV_nonfoc(pp,2) = INV_nonfoc(pp,2)/INV_nonfoc(pp,1);
        INV_nonfoc(pp,3) = INV_nonfoc(pp,3)/INV_nonfoc(pp,1);
        INV_nonfoc(pp,4) = INV_nonfoc(pp,4)/INV_nonfoc(pp,1);
        INV_nonfoc(pp,5) = INV_nonfoc(pp,5)/INV_nonfoc(pp,1);
    else
        INV_nonfoc(pp,2:5) = NaN;
    end
    if UPR_foc(pp,1) ~= 0
        UPR_foc(pp,2) = UPR_foc(pp,2)/UPR_foc(pp,1);
        UPR_foc(pp,3) = UPR_foc(pp,3)/UPR_foc(pp,1);
        UPR_foc(pp,4) = UPR_foc(pp,4)/UPR_foc(pp,1);
        UPR_foc(pp,5) = UPR_foc(pp,5)/UPR_foc(pp,1);
    else
        UPR_foc(pp,2:5) = NaN;
    end
    if INV_foc(pp,1) ~= 0
        INV_foc(pp,2) = INV_foc(pp,2)/INV_foc(pp,1);
        INV_foc(pp,3) = INV_foc(pp,3)/INV_foc(pp,1);
        INV_foc(pp,4) = INV_foc(pp,4)/INV_foc(pp,1);
        INV_foc(pp,5) = INV_foc(pp,5)/INV_foc(pp,1);
    else
        INV_foc(pp,2:5) = NaN;
    end
    if UPR_targfoc(pp,1) ~= 0
        UPR_targfoc(pp,2) = UPR_targfoc(pp,2)/UPR_targfoc(pp,1);
        UPR_targfoc(pp,3) = UPR_targfoc(pp,3)/UPR_targfoc(pp,1);
        UPR_targfoc(pp,4) = UPR_targfoc(pp,4)/UPR_targfoc(pp,1);
        UPR_targfoc(pp,5) = UPR_targfoc(pp,5)/UPR_targfoc(pp,1);
    else
        UPR_targfoc(pp,2:5) = NaN;
    end
    if INV_targfoc(pp,1) ~= 0
        INV_targfoc(pp,2) = INV_targfoc(pp,2)/INV_targfoc(pp,1);
        INV_targfoc(pp,3) = INV_targfoc(pp,3)/INV_targfoc(pp,1);
        INV_targfoc(pp,4) = INV_targfoc(pp,4)/INV_targfoc(pp,1);
        INV_targfoc(pp,5) = INV_targfoc(pp,5)/INV_targfoc(pp,1);
    else
        INV_targfoc(pp,2:5) = NaN;
    end
end

%% Making the SPSS matrix - main analysis
spss_ma(:,4) = durations(:,6); %in minutes

%% Making the SPSS matrix - Follow-ups
% spss_fu(:,1) = row_focus;% 1=yes, 0=no
spss_fu(:,2) = durations(:,6); % Duration of the experiment
spss_fu(:,3) = recall(:,5); % Average recall performance
spss_fu(:,4) = recog(:,5); % Average recog performance
spss_fu(:,5:8) = recog_upr(:,1:4); % Recog UPR selections averaged over blocks
spss_fu(:,9:12) = recog_inv(:,1:4); % Recog UPR selections averaged over blocks
spss_fu(:,13:17) = UPR_2corr(:,1:5);
spss_fu(:,18:22) = INV_2corr(:,1:5);
spss_fu(:,23:27) = UPR_nonfoc(:,1:5);
spss_fu(:,28:32) = INV_nonfoc(:,1:5);
spss_fu(:,33:37) = UPR_foc(:,1:5);
spss_fu(:,38:42) = INV_foc(:,1:5);
spss_fu(:,43:47) = UPR_targfoc(:,1:5);
spss_fu(:,48:52) = INV_targfoc(:,1:5);

%% Add figures for these main results. Other analyses will have to follow from these data.
figure;
plot([1 2 3 4],recall(:,1:4),'yo-')
hold on
plot([1 2 3 4],mean(recall(:,1:4),1),'ro-')
title('Recall performance')
xlabel('Block')
ylabel('Percentage correct')

figure;
plot([1 2 3 4],recog_upr,'c*')
hold on
plot([1 2 3 4],mean(recog_upr,1),'b*')
title('Recog alternative selection: upright-trial')
xlabel('targ-upr, targ-inv, foil-upr, foil-inv')
ylabel('count (15max)')

figure;
plot([1 2 3 4],recog_inv,'c*')
hold on
plot([1 2 3 4],mean(recog_inv,1),'b*')
title('Recog alternative selection: inverted-trial')
xlabel('targ-upr, targ-inv, foil-upr, foil-inv')
ylabel('count (15max)')