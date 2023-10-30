clc
clear all
%% Echo settings
settings = readtable('settings.csv');
switch settings.GEB_case
    case 1
        disp("GEB scenario: Efficiency (no demand response)");
    case 2
        disp("GEB scenario: Shedding");
end
switch settings.enableAirflowModel
    case 0
        disp("Airflow model: Disable")
    case 1
        disp("Airflow model: Active")
end
OBM_settings = xlsread('OBM/Master_Setup_AC_dense.xlsx',2,'H96:J96');
switch OBM_settings(3)
    case 0
        disp("Thermostat: Not Allowed");
    case 1
        disp("Thermostat: Allowed");
end
switch OBM_settings(2)
    case 0
        disp("Fan: Not Allowed");
    case 2
        disp("Fan: Allowed");
end
switch OBM_settings(1)
    case 0
        disp("Heater: Not Allowed");
    case 2
        disp("Heater: Allowed");
end
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
