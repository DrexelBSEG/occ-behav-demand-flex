clc
clear all

% subfunctions
addpath('D:\repo\engr_coding_toolkit\matlab_plot');
addpath('D:\repo\engr_coding_toolkit\matlab\kpi');
addpath('D:\repo\engr_coding_toolkit\matlab');

% Get a list of all folders in the raw_data directory
rawdataFolder = 'raw_data';
folderList = dir(rawdataFolder);
folderList = folderList([folderList.isdir]); % only keep directories
folderList = folderList(~ismember({folderList.name},{'.','..'})); % remove '.' and '..'

% for caseIndex = 1:length(folderList)
for caseIndex = 1
% clear all data except folderList and caseIndex
vars = who;
vars(ismember(vars, {'folderList', 'caseIndex'})) = [];
clear(vars{:});
% add data folder to path
% caseName = folderList(caseIndex).name;
caseName = 'noDR-AF-TFH-1hr'; % Manual mode
dataFolder = ['raw_data\', caseName];
dataFolderPath = fullfile(pwd,dataFolder);
addpath(dataFolderPath);

% Get a list of all files in the directory with the desired file name pattern
filePattern = fullfile(dataFolder, '*.mat'); % Change to whatever pattern you want.
theFiles = dir(filePattern);

%% define important parameters for analysis
% labels for naming variables
period_labels = {'peak','nonpeak','precool','rebound','daily'};
tes_period_labels = {'nonpeak_tes','precool_tes'};
zone_labels = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
% whold day 
wholeday = [0:1440];
% occupied period 6am-8pm 
occupied = [6*60+1:20*60];
unoccupied = wholeday(~ismember(wholeday,occupied));
% peak period
%-------------------------------------------------------------
%              |  Atlanta  |  Buffalo  |  NewYork  |  Tucson  |
%--------------------------------------------------------------
% winter       |  NA          5pm-8pm     12pm-8pm    6am-10am|
%              |                                      5pm-9pm |
% shoulder     |  NA          NA          11am-7pm    6am-9am |
%              |                                      4pm-8pm |
% typ summer   |  1pm-6pm     10am-4pm    11am-7pm    1pm-7pm |
% extrm summer |  1pm-6pm     10am-4pm    11am-7pm    1pm-7pm |
%-------------------------------------------------------------
peak = {[13*60+1:18*60],[17*60+1:20*60],[12*60+1:20*60],[[6*60+1:10*60],[17*60+1:21*60]];... % winter
    [13*60+1:18*60],[16*60+1:19*60],[11*60+1:19*60],[[6*60+1:9*60],[16*60+1:20*60]];... % shoulder
    [13*60+1:18*60],[10*60+1:16*60],[11*60+1:19*60],[13*60+1:19*60];... % typical summer
    [13*60+1:18*60],[10*60+1:16*60],[11*60+1:19*60],[13*60+1:19*60];};  % extreme summer
% nonpeak period timesteps
nonpeak = cell(size(peak));
for i = 1:size(peak,1)
    for k = 1:size(peak,2)
        nonpeak{i,k} = wholeday(~ismember(wholeday,peak{i,k}));
    end
end
% precool/preheat period timesteps
%--------------------------------------------------------------------------------------------------------------
%              |        Atlanta       |        Buffalo         |        NewYork       |         Tucson        |
%---------------------------------------------------------------------------------------------------------------
% winter       |          NA               2pm-5pm, TH=73C         10am-12pm, TH=72F      4:30pm-5pm, TH=69F  |
% shoulder     |          NA                      NA              6:30am-11am, TC=77F     3:30pm-4pm, TC=77F  |
% typ summer   |  12:30pm-1pm, TC=76F     9:30am-10am, TC=75F      8am-11am, TC=77F       11:30am-1pm, TC=76F |
% extrm summer |  12:30pm-1pm, TC=76F     9:30am-10am, TC=77F      6am-11am, TC=77F         12pm-1pm, TC=77F  |
%--------------------------------------------------------------------------------------------------------------
precool = {[],[14*60+1:17*60],[10*60+1:12*60],[16.5*60+1:17*60];... % winter
    [],[],[6.5*60+1:11*60],[15.5*60+1:16*60];... % shoulder
    [12.5*60+1:13*60],[9.5*60+1:10*60],[8*60+1:11*60],[11.5*60+1:13*60];... % typical summer
    [12.5*60+1:13*60],[9.5*60+1:10*60],[6*60+1:11*60],[12*60+1:13*60];};  % extreme summer
% rebound period timesteps
rebound = cell(size(peak));
for i = 1:size(peak,1)
    for k = 1:size(peak,2)
        rebound{i,k} = [peak{i,k}(end)+1:peak{i,k}(end)+60];
    end
end
% daily preiod timesteps
daily = cell(size(peak));
for i = 1:size(peak,1)
    for k = 1:size(peak,2)
        daily{i,k} = [1:1440];
    end
end
% time-of-use price
%---------------------------------------------------------------------------------------------
%              |  Atlanta           |  Buffalo          |  NewYork       |  Tucson            |
%---------------------------------------------------------------------------------------------
% winter       |  NA                   offpeak:0.0232      offpeak:8.37     offpeak:0.025651  |
%              |                       shoulder:0.0308     peak:16.56       peak:0.038010     |      
%              |                       peak:0.0332                                            |
% shoulder     |  NA                   NA                  offpeak:8.37     offpeak:0.025651  |
%              |                                           peak:16.56       peak:0.038010     |
%              |                                                                              |
% typ summer   |  offpeak:0.074646     offpeak:0.0298      offpeak:8.37     offpeak:0.025609  |
%              |  peak:0.16923         shoulder:0.0409     peak:21.54       peak:0.071322     |
%              |                       peak:0.113                                             |
% extrm summer |  offpeak:0.074646     offpeak:0.0298      offpeak:8.37     offpeak:0.025609  |
%              |  peak:0.16923         shoulder:0.0409     peak:21.54       peak:0.071322     |
%              |                       peak:0.113                                             |
%---------------------------------------------------------------------------------------------
tou = cell(size(peak));
tou{1,2}(wholeday+1) = 0.0232; tou{1,2}([8*60+1:19*60]+1) = 0.0308; tou{1,2}(peak{1,2}+1) = 0.0332;
tou{1,3}(wholeday+1) = 8.37; tou{1,3}(peak{1,3}+1) = 16.56;
tou{1,4}(wholeday+1) = 0.025651; tou{1,4}(peak{1,4}+1) = 0.038010;
tou{2,3}(wholeday+1) = 8.37; tou{2,3}(peak{2,3}+1) = 16.56;
tou{2,4}(wholeday+1) = 0.025651; tou{2,4}(peak{2,4}+1) = 0.038010;
tou{3,1}(wholeday+1) = 0.074646; tou{3,1}(peak{3,1}+1) = 0.169230; 
tou{3,2}(wholeday+1) = 0.0298; tou{3,2}([7*60+1:19*60]+1) = 0.0409; tou{3,2}(peak{3,2}+1) = 0.113;
tou{3,3}(wholeday+1) = 8.37; tou{3,3}(peak{3,3}+1) = 21.54;
tou{3,4}(wholeday+1) = 0.025609; tou{3,4}(peak{3,4}+1) = 0.071322;
for j=1:size(tou,2)
    tou{4,j} = tou{3,j};
end
% floor area
flr_area = 388.207716526563/2 + 86.2109918921875/2 + 62.8993385;

%% loop through each file
for i = 1 : length(theFiles)
    clear data
    % determine file name
    baseFileName = theFiles(i).name;
    fullFileName = fullfile(dataFolder, baseFileName);
    % load file
    data{i} = load(fullFileName);
    %% HVAC power received at simulation side
    data{i}.hvac_power_sim = [data{i}.Measurements.Power_HVAC]'*1000;
    %% personal equipment usage
    % There are two days data in EnergyPlus. THe first day is purely
    % simulation, it is not involve in the testing. Therefore, the first day
    % data is ignored in the evaluation.
    EPlusRange = [1441:2880]; 
    % EnergyPlus data does not contain timestep 0. To match its size with other
    % arrays, the first row is repeated, so that the total length is 1441.
    EPlusRange = [EPlusRange(1),EPlusRange];  
    % occupancy (ref and var cases should have the same occupancy
    if ~logical(table2array(data{i}.settings(1,5)))
        occ_tot = 7;
    else
        occ_tot = 11;
    end
    % personal fan power
    data{i}.power_pf = data{i}.EPlusOutput.('FMU_PERIMETER_ZN_1_PF:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot*15;
    % personal fan power
    data{i}.power_ph = data{i}.EPlusOutput.('FMU_PERIMETER_ZN_1_PH:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot*1200;
    %% number of occupants
    data{i}.num_occ = size(data{i}.OccupantMatrix(1).OccupantMatrix,1);
    %% Matrix to collect occupant related points
    % Array
    % Timestep | Occ1 | Occ2 | ... | OccN |
    % 0        | xxx  | xxx  | xxx | xxx  |
    % ...      | xxx  | xxx  | xxx | xxx  |
    % 1440     | xxx  | xxx  | xxx | xxx  |
    for k = 1:1441
        for kk = 1:data{i}.num_occ
            data{i}.PMVact(k,kk) = data{i}.OccupantMatrix(k).OccupantMatrix(kk).PMVact;
            prep_data{i}.occ_ph(k,kk) = data{i}.OccupantMatrix(k).OccupantMatrix(kk).InOffice*...
                data{i}.OccupantMatrix(k).OccupantMatrix(kk).BehaviorStatesVector(5);
            prep_data{i}.occ_pf(k,kk) = data{i}.OccupantMatrix(k).OccupantMatrix(kk).InOffice*...
                data{i}.OccupantMatrix(k).OccupantMatrix(kk).BehaviorStatesVector(6);
            prep_data{i}.occ_spt(k,kk) = data{i}.OccupantMatrix(k).OccupantMatrix(kk).InOffice*...
                data{i}.OccupantMatrix(k).OccupantMatrix(kk).BehaviorStatesVector(7);  
            prep_data{i}.in_office(k,kk) = data{i}.OccupantMatrix(k).OccupantMatrix(kk).InOffice;
        end
    end
    %% behaviors
    data{i}.pf = data{i}.power_pf/15;
    data{i}.ph = data{i}.power_ph/1200;
    data{i}.Tz_cspt = round([data{i}.SimData.Tz_cspt]',4);
    data{i}.Tz_hspt = round([data{i}.SimData.Tz_hspt]',4);
    temp = [data{i}.SupvCtrlSig.Tz_cspt]';
    data{i}.Tz_cspt_base = round(temp(:,2),4);
    temp = [data{i}.SupvCtrlSig.Tz_hspt]';
    data{i}.Tz_hspt_base = round(temp(:,2),4);
    %% decide critical periods for each case
    % row and column of each period from the period table
    data{i}.period_table_loc = [data{i}.settings.SeasonType(1),data{i}.settings.Location(1)];
    % determine corresponding timesteps according to the predefined table
    for k = 1:length(period_labels)
        eval(['data{i}.' period_labels{k} '= cell2mat(' period_labels{k} '(data{i}.period_table_loc(1),data{i}.period_table_loc(2)))'';']);
    end
    %% pre-process data for KPI calculation
    % reset hvac_power_sim unoccupied time values
    data{i}.hvac_power_sim(unoccupied+1) = 0;
    % new variable based on existing variables
    data{i}.Q_hvac = data{i}.hvac_power_sim;        
    data{i}.Q_all = data{i}.Q_hvac + data{i}.power_pf + data{i}.power_ph;
    % divide time-series data into different periods
    for k = 1:length(period_labels) 
        eval(['rows = data{i}.' period_labels{k} '+1;']);
        % power
        eval(['kpi.Q_hvac{i}.' period_labels{k} ' = data{i}.Q_hvac(rows);']);
        eval(['kpi.Q_pf{i}.' period_labels{k} ' = data{i}.power_pf(rows);']);
        eval(['kpi.Q_ph{i}.' period_labels{k} ' = data{i}.power_ph(rows);']);
        eval(['kpi.Q_all{i}.' period_labels{k} ' = data{i}.Q_all(rows);']);
        % PMVacts
        eval(['kpi.PMVcool{i}.' period_labels{k} ' = data{i}.PMVact(rows,:)<0;']);
        eval(['kpi.PMVwarm{i}.' period_labels{k} ' = data{i}.PMVact(rows,:)>0;']);
        % behaviors
        eval(['kpi.pf{i}.' period_labels{k} ' = data{i}.pf(rows);']); 
        eval(['kpi.ph{i}.' period_labels{k} ' = data{i}.ph(rows);']);  
        eval(['kpi.Tz_cspt_adjust{i}.' period_labels{k} ' = -data{i}.Tz_cspt_base(rows) + data{i}.Tz_cspt(rows);']);
        eval(['kpi.Tz_hspt_adjust{i}.' period_labels{k} ' = -data{i}.Tz_hspt_base(rows) + data{i}.Tz_hspt(rows);']);
    end    
    % time-of-use for each case
    kpi.tou{i} = tou{data{i}.settings.SeasonType(1),data{i}.settings.Location(1)}';
    %% KPI (without ref)
%     % daily energy use
%     kpi.daily.E_hvac(i) = sum(data{i}.Q_hvac/1000/60); 
%     kpi.daily.E_all(i) = sum(data{i}.Q_all/1000/60); 
    % hvac power only
    x1 = kpi.Q_hvac{i}.nonpeak;
    x2 = length(data{i}.nonpeak)/60;
    x3 = kpi.Q_hvac{i}.peak;
    x4 = length(data{i}.peak)/60;
    kpi.FF_hvac(i) = kpi_flex_factor(x1,x2,x3,x4);
    % hvac and personal equipment power
    x1 = kpi.Q_all{i}.nonpeak;
    x2 = length(data{i}.nonpeak)/60;
    x3 = kpi.Q_all{i}.peak;
    x4 = length(data{i}.peak)/60;
    kpi.FF_all(i) = kpi_flex_factor(x1,x2,x3,x4);
    % time-of-use hvac power only
    if data{i}.settings.Location(1)~=3
        x1 = data{i}.Q_hvac/1000.0;
        x2 = kpi.tou{i};
        x3 = 1/60;
        kpi.cost_hvac(i) = kpi_tou_cost_acc(x1,x2,x3);
    else
        x1 = kpi.Q_hvac{i}.peak/1000.0;
        x2 = kpi.Q_hvac{i}.nonpeak/1000.0;
        x3 = max(kpi.tou{i});
        x4 = min(kpi.tou{i});
        % assuming 30 days in a billing cycle
        kpi.cost_hvac(i) = kpi_tou_cost_aasc2_oneday(x1,x2,x3,x4)/30;          
    end
    % time-of-use hvac and personal equipment power
    if data{i}.settings.Location(1)~=3
        x1 = data{i}.Q_all/1000.0;
        x2 = kpi.tou{i};
        x3 = 1/60;
        kpi.cost_all(i) = kpi_tou_cost_acc(x1,x2,x3);
    else
        x1 = kpi.Q_all{i}.peak/1000.0;
        x2 = kpi.Q_all{i}.nonpeak/1000.0;
        x3 = max(kpi.tou{i});
        x4 = min(kpi.tou{i});
        % assuming 30 days in a billing cycle
        kpi.cost_all(i) = kpi_tou_cost_aasc2_oneday(x1,x2,x3,x4)/30;          
    end
    % simple kpi for each period
    for k = 1:length(period_labels) 
        eval(['rows = data{i}.' period_labels{k} '+1;']);       
        % average demand
        eval(['kpi.' period_labels{k} '.Qbar_hvac(i) = mean(data{i}.Q_hvac(rows));']);
        eval(['kpi.' period_labels{k} '.Qbar_all(i) = mean(data{i}.Q_all(rows));']);
        % average demand intensity
        eval(['kpi.' period_labels{k} '.Qbar_int_hvac(i) = mean(data{i}.Q_hvac(rows)/flr_area);']);
        eval(['kpi.' period_labels{k} '.Qbar_int_all(i) = mean(data{i}.Q_all(rows)/flr_area);']);            
        % average peak average demand
        eval(['kpi.' period_labels{k} '.Qmax_hvac_1min(i) = max(data{i}.Q_hvac(rows));']);
        eval(['kpi.' period_labels{k} '.Qmax_hvac_15min(i) = max(movmean(data{i}.Q_hvac(rows),15,''Endpoints'',''discard''));']);
        eval(['kpi.' period_labels{k} '.Qmax_hvac_30min(i) = max(movmean(data{i}.Q_hvac(rows),30,''Endpoints'',''discard''));']);
        eval(['kpi.' period_labels{k} '.Qmax_all_1min(i) = max(data{i}.Q_all(rows));']);
        eval(['kpi.' period_labels{k} '.Qmax_all_15min(i) = max(movmean(data{i}.Q_all(rows),15,''Endpoints'',''discard''));']);
        eval(['kpi.' period_labels{k} '.Qmax_all_30min(i) = max(movmean(data{i}.Q_all(rows),30,''Endpoints'',''discard''));']);
        if length(rows)>=60
            eval(['kpi.' period_labels{k} '.Qmax_hvac_60min(i) = max(movmean(data{i}.Q_hvac(rows),60,''Endpoints'',''discard''));']);
            eval(['kpi.' period_labels{k} '.Qmax_all_60min(i) = max(movmean(data{i}.Q_all(rows),60,''Endpoints'',''discard''));']);   
        end
        % energy use
        eval(['kpi.' period_labels{k} '.E_hvac(i) = mean(data{i}.Q_hvac(rows))/1000*length(rows)/60;']);
        eval(['kpi.' period_labels{k} '.E_all(i) = mean(data{i}.Q_all(rows))/1000*length(rows)/60;']); 
        % comfort and behavior duration by occupant
        for kk = 1:data{i}.num_occ
            eval(['kpi.' period_labels{k} '.PMVcool_occ(i,kk) = sum(data{i}.PMVact(rows,kk)<0);']); 
            eval(['kpi.' period_labels{k} '.PMVwarm_occ(i,kk) = sum(data{i}.PMVact(rows,kk)>0);']);
            eval(['kpi.' period_labels{k} '.ph_occ(i,kk) = sum(prep_data{i}.occ_ph(rows,kk)>0);']);
            eval(['kpi.' period_labels{k} '.pf_occ(i,kk) = sum(prep_data{i}.occ_pf(rows,kk)<0);']);
            eval(['kpi.' period_labels{k} '.sptup_occ(i,kk) = sum(prep_data{i}.occ_spt(rows,kk)>0);']);
            eval(['kpi.' period_labels{k} '.sptdown_occ(i,kk) = sum(prep_data{i}.occ_spt(rows,kk)<0);']);
            eval(['kpi.' period_labels{k} '.in_office(i,kk) = sum(prep_data{i}.in_office(rows,kk)>0);']);
        end
        % cool (or warm) discomfort duration of all occupants
        eval(['kpi.' period_labels{k} '.PMVcool_sum(i) = sum(data{i}.PMVact(rows,:)<0,''all'');']); 
        eval(['kpi.' period_labels{k} '.PMVwarm_sum(i) = sum(data{i}.PMVact(rows,:)>0,''all'');']); 
        % cool (or warm) discomfort duration per occupant
        eval(['kpi.' period_labels{k} '.PMVcool_per(i) = kpi.' period_labels{k} '.PMVcool_sum(i)/occ_tot;']);
        eval(['kpi.' period_labels{k} '.PMVwarm_per(i) = kpi.' period_labels{k} '.PMVwarm_sum(i)/occ_tot;']);
        % duration of personal equipment use of all occupants
        eval(['kpi.' period_labels{k} '.pf_sum(i) = sum(data{i}.pf(rows));']);
        eval(['kpi.' period_labels{k} '.ph_sum(i) = sum(data{i}.ph(rows));']);
        % duration of personal equipment use per occupant
        eval(['kpi.' period_labels{k} '.pf_sum(i) = sum(data{i}.pf(rows))/occ_tot;']);
        eval(['kpi.' period_labels{k} '.ph_sum(i) = sum(data{i}.ph(rows))/occ_tot;']); 
        % duration of setpoint adjustment
        eval(['kpi.' period_labels{k} '.Tz_cspt_up(i) = sum(kpi.Tz_cspt_adjust{i}.' period_labels{k} ' >0);']);
        eval(['kpi.' period_labels{k} '.Tz_cspt_down(i) = sum(kpi.Tz_cspt_adjust{i}.' period_labels{k} ' <0);']);
    end
end
%% write csv file
% assemble data to a table
output = table(kpi.peak.E_hvac',kpi.peak.E_all',...
    kpi.daily.E_hvac',kpi.daily.E_all',...
    kpi.FF_hvac',kpi.FF_all',...
    kpi.cost_hvac',kpi.cost_all',...
    kpi.peak.PMVcool_occ(:,1),kpi.peak.PMVwarm_occ(:,1),...
    kpi.peak.PMVcool_occ(:,2),kpi.peak.PMVwarm_occ(:,2),...
    kpi.peak.PMVcool_occ(:,3),kpi.peak.PMVwarm_occ(:,3),...
    kpi.peak.PMVcool_occ(:,4),kpi.peak.PMVwarm_occ(:,4),...
    kpi.peak.PMVcool_occ(:,5),kpi.peak.PMVwarm_occ(:,5),...
    kpi.peak.PMVcool_occ(:,6),kpi.peak.PMVwarm_occ(:,6),...
    kpi.peak.PMVcool_occ(:,7),kpi.peak.PMVwarm_occ(:,7),...
    kpi.peak.PMVcool_occ(:,8),kpi.peak.PMVwarm_occ(:,8),...
    kpi.peak.PMVcool_occ(:,9),kpi.peak.PMVwarm_occ(:,9),...
    kpi.peak.PMVcool_occ(:,10),kpi.peak.PMVwarm_occ(:,10),...
    kpi.peak.PMVcool_occ(:,11),kpi.peak.PMVwarm_occ(:,11),...
    kpi.peak.PMVcool_per(:),kpi.peak.PMVwarm_per(:),...
    kpi.daily.PMVcool_occ(:,1),kpi.daily.PMVwarm_occ(:,1),...
    kpi.daily.PMVcool_occ(:,2),kpi.daily.PMVwarm_occ(:,2),...
    kpi.daily.PMVcool_occ(:,3),kpi.daily.PMVwarm_occ(:,3),...
    kpi.daily.PMVcool_occ(:,4),kpi.daily.PMVwarm_occ(:,4),...
    kpi.daily.PMVcool_occ(:,5),kpi.daily.PMVwarm_occ(:,5),...
    kpi.daily.PMVcool_occ(:,6),kpi.daily.PMVwarm_occ(:,6),...
    kpi.daily.PMVcool_occ(:,7),kpi.daily.PMVwarm_occ(:,7),...
    kpi.daily.PMVcool_occ(:,8),kpi.daily.PMVwarm_occ(:,8),...
    kpi.daily.PMVcool_occ(:,9),kpi.daily.PMVwarm_occ(:,9),...
    kpi.daily.PMVcool_occ(:,10),kpi.daily.PMVwarm_occ(:,10),...
    kpi.daily.PMVcool_occ(:,11),kpi.daily.PMVwarm_occ(:,11),...
    kpi.daily.PMVcool_per(:),kpi.daily.PMVwarm_per(:),...
    kpi.peak.in_office(:,1),kpi.daily.in_office(:,1),...
    kpi.peak.in_office(:,2),kpi.daily.in_office(:,2),...
    kpi.peak.in_office(:,3),kpi.daily.in_office(:,3),...
    kpi.peak.in_office(:,4),kpi.daily.in_office(:,4),...
    kpi.peak.in_office(:,5),kpi.daily.in_office(:,5),...
    kpi.peak.in_office(:,6),kpi.daily.in_office(:,6),...
    kpi.peak.in_office(:,7),kpi.daily.in_office(:,7),...
    kpi.peak.in_office(:,8),kpi.daily.in_office(:,8),...
    kpi.peak.in_office(:,9),kpi.daily.in_office(:,9),...
    kpi.peak.in_office(:,10),kpi.daily.in_office(:,10),...
    kpi.peak.in_office(:,11),kpi.daily.in_office(:,11),...
    'VariableNames',...
    {'Peak Energy Use (HVAC) [kWh]','Peak Energy Use (HVAC and Personal Equipment) [kWh]',...
    'Daily Energy Use (HVAC) [kWh]','Daily Energy Use (HVAC and Personal Equipment) [kWh]',...
    'Daily FF (HVAC)','Daily FF (HVAC and Personal Equipment)',...
    'Daily Cost (HVAC) [$]','Daily Cost (HVAC and Personal Equipment) [$]',...
    'Peak Occ#1 Cool Duration [mins]','Peak Occ#1 Warm Duration [mins]',...
    'Peak Occ#2 Cool Duration [mins]','Peak Occ#2 Warm Duration [mins]',...
    'Peak Occ#3 Cool Duration [mins]','Peak Occ#3 Warm Duration [mins]',...
    'Peak Occ#4 Cool Duration [mins]','Peak Occ#4 Warm Duration [mins]',...
    'Peak Occ#5 Cool Duration [mins]','Peak Occ#5 Warm Duration [mins]',...
    'Peak Occ#6 Cool Duration [mins]','Peak Occ#6 Warm Duration [mins]',...
    'Peak Occ#7 Cool Duration [mins]','Peak Occ#7 Warm Duration [mins]',...
    'Peak Occ#8 Cool Duration [mins]','Peak Occ#8 Warm Duration [mins]',...
    'Peak Occ#9 Cool Duration [mins]','Peak Occ#9 Warm Duration [mins]',...
    'Peak Occ#10 Cool Duration [mins]','Peak Occ#10 Warm Duration [mins]',...
    'Peak Occ#11 Cool Duration [mins]','Peak Occ#11 Warm Duration [mins]',...
    'Peak Average Cool Duratin [mins]','Peak Average Cool Duration [mins]',...
    'Daily Occ#1 Cool Duration [mins]','Daily Occ#1 Warm Duration [mins]',...
    'Daily Occ#2 Cool Duration [mins]','Daily Occ#2 Warm Duration [mins]',...
    'Daily Occ#3 Cool Duration [mins]','Daily Occ#3 Warm Duration [mins]',...
    'Daily Occ#4 Cool Duration [mins]','Daily Occ#4 Warm Duration [mins]',...
    'Daily Occ#5 Cool Duration [mins]','Daily Occ#5 Warm Duration [mins]',...
    'Daily Occ#6 Cool Duration [mins]','Daily Occ#6 Warm Duration [mins]',...
    'Daily Occ#7 Cool Duration [mins]','Daily Occ#7 Warm Duration [mins]',...
    'Daily Occ#8 Cool Duration [mins]','Daily Occ#8 Warm Duration [mins]',...
    'Daily Occ#9 Cool Duration [mins]','Daily Occ#9 Warm Duration [mins]',...
    'Daily Occ#10 Cool Duration [mins]','Daily Occ#10 Warm Duration [mins]',...
    'Daily Occ#11 Cool Duration [mins]','Daily Occ#11 Warm Duration [mins]',...
    'Daily Average Cool Duration [mins]','Daily Average Warm Duration [mins]',...
    'Peak Occ#1 In-Office Duration [mins]','Daily Occ#1 In-Office Duration [mins]',...
    'Peak Occ#2 In-Office Duration [mins]','Daily Occ#2 In-Office Duration [mins]',...
    'Peak Occ#3 In-Office Duration [mins]','Daily Occ#3 In-Office Duration [mins]',...
    'Peak Occ#4 In-Office Duration [mins]','Daily Occ#4 In-Office Duration [mins]',...
    'Peak Occ#5 In-Office Duration [mins]','Daily Occ#5 In-Office Duration [mins]',...
    'Peak Occ#6 In-Office Duration [mins]','Daily Occ#6 In-Office Duration [mins]',...
    'Peak Occ#7 In-Office Duration [mins]','Daily Occ#7 In-Office Duration [mins]',...
    'Peak Occ#8 In-Office Duration [mins]','Daily Occ#8 In-Office Duration [mins]',...
    'Peak Occ#9 In-Office Duration [mins]','Daily Occ#9 In-Office Duration [mins]',...
    'Peak Occ#10 In-Office Duration [mins]','Daily Occ#10 In-Office Duration [mins]',...
    'Peak Occ#11 In-Office Duration [mins]','Daily Occ#11 In-Office Duration [mins]'});

output_peak_occ = array2table([[kpi.peak.pf_occ(:,1),kpi.peak.ph_occ(:,1),kpi.peak.sptup_occ(:,1),kpi.peak.sptdown_occ(:,1),kpi.peak.in_office(:,1),kpi.peak.PMVcool_occ(:,1),kpi.peak.PMVwarm_occ(:,1),1+zeros(length(kpi.peak.pf_occ(:,1)),1)];...
                        [kpi.peak.pf_occ(:,2),kpi.peak.ph_occ(:,2),kpi.peak.sptup_occ(:,2),kpi.peak.sptdown_occ(:,2),kpi.peak.in_office(:,2),kpi.peak.PMVcool_occ(:,2),kpi.peak.PMVwarm_occ(:,2),2+zeros(length(kpi.peak.pf_occ(:,2)),1)];...
                        [kpi.peak.pf_occ(:,3),kpi.peak.ph_occ(:,3),kpi.peak.sptup_occ(:,3),kpi.peak.sptdown_occ(:,3),kpi.peak.in_office(:,3),kpi.peak.PMVcool_occ(:,3),kpi.peak.PMVwarm_occ(:,3),3+zeros(length(kpi.peak.pf_occ(:,3)),1)];...
                        [kpi.peak.pf_occ(:,4),kpi.peak.ph_occ(:,4),kpi.peak.sptup_occ(:,4),kpi.peak.sptdown_occ(:,4),kpi.peak.in_office(:,4),kpi.peak.PMVcool_occ(:,4),kpi.peak.PMVwarm_occ(:,4),4+zeros(length(kpi.peak.pf_occ(:,4)),1)];...
                        [kpi.peak.pf_occ(:,5),kpi.peak.ph_occ(:,5),kpi.peak.sptup_occ(:,5),kpi.peak.sptdown_occ(:,5),kpi.peak.in_office(:,5),kpi.peak.PMVcool_occ(:,5),kpi.peak.PMVwarm_occ(:,5),5+zeros(length(kpi.peak.pf_occ(:,5)),1)];...
                        [kpi.peak.pf_occ(:,6),kpi.peak.ph_occ(:,6),kpi.peak.sptup_occ(:,6),kpi.peak.sptdown_occ(:,6),kpi.peak.in_office(:,6),kpi.peak.PMVcool_occ(:,6),kpi.peak.PMVwarm_occ(:,6),6+zeros(length(kpi.peak.pf_occ(:,6)),1)];...
                        [kpi.peak.pf_occ(:,7),kpi.peak.ph_occ(:,7),kpi.peak.sptup_occ(:,7),kpi.peak.sptdown_occ(:,7),kpi.peak.in_office(:,7),kpi.peak.PMVcool_occ(:,7),kpi.peak.PMVwarm_occ(:,7),7+zeros(length(kpi.peak.pf_occ(:,7)),1)];...
                        [kpi.peak.pf_occ(:,8),kpi.peak.ph_occ(:,8),kpi.peak.sptup_occ(:,8),kpi.peak.sptdown_occ(:,8),kpi.peak.in_office(:,8),kpi.peak.PMVcool_occ(:,8),kpi.peak.PMVwarm_occ(:,8),8+zeros(length(kpi.peak.pf_occ(:,8)),1)];...
                        [kpi.peak.pf_occ(:,9),kpi.peak.ph_occ(:,9),kpi.peak.sptup_occ(:,9),kpi.peak.sptdown_occ(:,9),kpi.peak.in_office(:,9),kpi.peak.PMVcool_occ(:,9),kpi.peak.PMVwarm_occ(:,9),9+zeros(length(kpi.peak.pf_occ(:,9)),1)];...
                        [kpi.peak.pf_occ(:,10),kpi.peak.ph_occ(:,10),kpi.peak.sptup_occ(:,10),kpi.peak.sptdown_occ(:,10),kpi.peak.in_office(:,10),kpi.peak.PMVcool_occ(:,10),kpi.peak.PMVwarm_occ(:,10),10+zeros(length(kpi.peak.pf_occ(:,10)),1)];...
                        [kpi.peak.pf_occ(:,11),kpi.peak.ph_occ(:,11),kpi.peak.sptup_occ(:,11),kpi.peak.sptdown_occ(:,11),kpi.peak.in_office(:,11),kpi.peak.PMVcool_occ(:,11),kpi.peak.PMVwarm_occ(:,11),11+zeros(length(kpi.peak.pf_occ(:,11)),1)]],...
                         'VariableNames',{'Personal Fan Duration [mins]','Personal Heater Duration [mins]','Cooling Setpoint Up Duration [mins]','Cooling Setpoint Down Duration [mins]','In-Office Duration [mins]','Cool Duration [mins]','Warm Duration [mins]','Occupant #'});
                     
% write table to csv
writetable(output,['post_data\',caseName,'.csv']);
writetable(output_peak_occ,['post_data\',caseName,'_peak_occ.csv']);

end