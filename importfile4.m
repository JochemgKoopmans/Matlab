function tableout = importfile4(workbookFile,sheetName,startRow,endRow)
%IMPORTFILE4 Import data from a spreadsheet
%   DATA = IMPORTFILE4(FILE) reads data from the first worksheet in the
%   Microsoft Excel spreadsheet file named FILE and returns the data as a
%   table.
%
%   DATA = IMPORTFILE4(FILE,SHEET) reads from the specified worksheet.
%
%   DATA = IMPORTFILE4(FILE,SHEET,STARTROW,ENDROW) reads from the specified
%   worksheet for the specified row interval(s). Specify STARTROW and
%   ENDROW as a pair of scalars or vectors of matching size for
%   dis-contiguous row intervals. To read to the end of the file specify an
%   ENDROW of inf.
%
%	Non-numeric cells are replaced with: NaN
%
% Example:
%   SESSION2021101315h33 =
%   importfile4('88651_SESSION_2021-10-13_15h33.34.260.xlsx','Jochem_Pilot3_AFC_88651_SES
%   (2)',2,607);
%
%   See also XLSREAD.

% Auto-generated by MATLAB on 2021/10/18 10:34:14

%% Input handling

% If no sheet is specified, read first sheet
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% If row start and end points are not specified, define defaults
if nargin <= 3
    startRow = 2;
    endRow = 607;
end

%% Import the data
[~, ~, raw] = xlsread(workbookFile, sheetName, sprintf('A%d:AH%d',startRow(1),endRow(1)));
for block=2:length(startRow)
    [~, ~, tmpRawBlock] = xlsread(workbookFile, sheetName, sprintf('A%d:AH%d',startRow(block),endRow(block)));
    raw = [raw;tmpRawBlock]; %#ok<AGROW>
end
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};
cellVectors = raw(:,[1,4,6,7,10,11,12,13,14,15,16,17,18,19,20,21,22,23,27,28,29,30]);
raw = raw(:,[2,3,5,8,9,24,25,26,31,32,33,34]);

%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
I = cellfun(@(x) ischar(x), raw);
raw(I) = {NaN};
data = reshape([raw{:}],size(raw));

%% Create table
tableout = table;

%% Allocate imported array to column variable names
tableout.trial_type = cellVectors(:,1);
tableout.trial_index = data(:,1);
tableout.time_elapsed = data(:,2);
tableout.internal_node_id = cellVectors(:,2);
tableout.rt = data(:,3);
tableout.stimulus = cellVectors(:,3);
tableout.response = cellVectors(:,4);
tableout.success = data(:,4);
tableout.timeout = data(:,5);
tableout.failed_images = cellVectors(:,5);
tableout.failed_audio = cellVectors(:,6);
tableout.failed_video = cellVectors(:,7);
tableout.view_history = cellVectors(:,8);
tableout.cor_ans = cellVectors(:,9);
tableout.block_num = cellVectors(:,10);
tableout.cor_loc = cellVectors(:,11);
tableout.incor_loc = cellVectors(:,12);
tableout.wrong = cellVectors(:,13);
tableout.sel_letters = cellVectors(:,14);
tableout.question_order = cellVectors(:,15);
tableout.recog_corr = cellVectors(:,16);
tableout.recog_list = cellVectors(:,17);
tableout.recog_options_list = cellVectors(:,18);
tableout.sel_cor = data(:,6);
tableout.sel_incor = data(:,7);
tableout.block_number = data(:,8);
tableout.num_rates = cellVectors(:,19);
tableout.inv_rates = cellVectors(:,20);
tableout.non_inv_rates = cellVectors(:,21);
tableout.not_shown_rates = cellVectors(:,22);
tableout.performance_correct = data(:,9);
tableout.performance_wrong_place = data(:,10);
tableout.recog_performance_correct = data(:,11);
tableout.recog_performance_incorrect = data(:,12);

