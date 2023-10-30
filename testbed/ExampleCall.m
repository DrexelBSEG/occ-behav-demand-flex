clc
clear all
%% Echo settings
settings = readtable('settings.csv');
switch settings.GEB_case
    case 1
        term1 = 'noDR';
    case 2
        term1 = 'Shed';
end
switch settings.enableAirflowModel
    case 0
        term2 = 'noAF';
    case 1
        term2 = 'AF';
end
OBM_settings = xlsread('OBM/Master_Setup_AC_dense.xlsx',2,'H96:J96');
switch OBM_settings(3)
    case 0
        term31 = '';
    case 1
        term31 = 'T';
end
switch OBM_settings(2)
    case 0
        term32 = '';
    case 2
        term32 = 'F';
end
switch OBM_settings(1)
    case 0
        term33 = '';
    case 2
        term33 = 'H';
end
disp([term1,'-',term2,'-',term31,term32,term33]);
%% Please provide the simulation time period
T = 86400; % length of the simulation period 
ntimestep=T/60; % total number of time step
for timestep=0:ntimestep
    %% At every iteration,update measurements
    HardwareTime = 0.0001*timestep; % Please assign a unique hardware clock time this variable. It can be an index number or the actual hardware time
    % Please refer to the notes in callSim for the meaning of each inputs
    % HP measurements
    if timestep==0
        Meas=[0.1,18,0.009,22,0.0095,28,300];
    else
        Meas=VHP(timestep);
    end
    %% Call Simulation
    [ZoneInfo,CtrlSig]=callSim(HardwareTime,timestep,Meas);
end

% save all data to .mat file
DataDL;
