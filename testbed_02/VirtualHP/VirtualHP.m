function Meas=VirtualHP(timestep,Tz,Tz_d,wz,To,To_d,wo,TC,TH,HP_status)
%% Notes
%% Inputs
% timestep:    timesetp
% Tz:          zone air temperature [C]
% Tz_d:        zone air dewpoint temperature [C]
% wz:          zone air humidity ratio [kg/kg]
% To:          outdoor air temperature [C]
% TC:          thermostat cooling setpoint [C]
% TH:          thermostat heating setpoint [C]
% HP_status:   heat pump operation status, 1=on, 0=off
%% Outputs
% Meas:
%  m_sup = Meas(1) :             vav discharge air mass flow rate [kg/s]
%  T_sup = Meas(2) :             vav discharge air temperature [°C]
%  w_sup = Meas(3) :             vav discharge air humidity ratio [kg/kg]
%  (Assume emulated side zone/outdoor air is equal to simulation side in pretest)
%  T_z1 = Meas(4) :              zone air temperature [°C]
%  w_z1 = Meas(5) :              humidity ratio of zone [kg/kg]
%  T_out_emulated = Meas(6) :    emulated side outdoor air temperature for ASHP [°C]
%  Power = Meas(7);              Total electric power of HVAC system including primary/secondary system [kW]
%% Global variable
persistent Cooling_HSpeedTable Cooling_LSpeedTable Heating_HSpeedTable Heating_LSpeedTable 
persistent  HP_speed m_sup_all Cap
%% Initialization
if timestep==1
    [Cooling_HSpeedTable]=xlsread('COEF_SS_HIGHSpeed-ALL',1,'B7:K10');
    [Cooling_LSpeedTable]=xlsread('COEF_SS_LowSpeed-ALL',1,'B7:K10');
    [Heating_HSpeedTable]=xlsread('COEF-Heating-HIGH-COMBINED-ALL',1,'B4:K40');
    [Heating_LSpeedTable]=xlsread('COEF-Heating-LOW-COMBINED-ALL',1,'B4:K40');
    HP_speed=0;  % -1=heating low speed, -2=heating high speed, 0=passby, 1=cooling low speed, 2=cooling high speed
    m_sup_all=[0 680 1055 ;0 630 1015];  % the supply air mass flow rate in different HP operation speed [cfm]
    Cap=zeros(1440,3);  % record sensible/total cap/Power
end
%% Determine HP cooling/heating mode and speed
if HP_status==1
    if HP_speed==0   % current status = no running
        if Tz<TC && Tz>TH
            HP_speed=0;
        elseif (Tz-TC)>=0 && (Tz-TC)<(0.5/1.8)
            HP_speed=0;
        elseif (Tz-TC)>=(0.5/1.8) && (Tz-TC)<(1/1.8)
            HP_speed=1;
        elseif (Tz-TC)>=(1/1.8)
            HP_speed=2;
        elseif (TH-Tz)>=0 && (TH-Tz)<(0.5/1.8)
            HP_speed=0;
        elseif (TH-Tz)>=(0.5/1.8) && (TH-Tz)<(1/1.8)
            HP_speed=-1;
        elseif (TH-Tz)>=(1/1.8)
            HP_speed=-2;
        end
    elseif HP_speed==1   % current status = low speed cooling
        if (Tz-TC)<0
            HP_speed=0;
        elseif (Tz-TC)>=0 && (Tz-TC)<(0.5/1.8)
            HP_speed=1;
        elseif (Tz-TC)>=(0.5/1.8) && (Tz-TC)<(1/1.8)
            HP_speed=1;
        elseif (Tz-TC)>=(1/1.8)
            HP_speed=2;
        end
    elseif HP_speed==2   % current status = high speed cooling
        if (Tz-TC)<0
            HP_speed=0;
        elseif (Tz-TC)>=0 && (Tz-TC)<(0.5/1.8)
            HP_speed=1;
        elseif (Tz-TC)>=(0.5/1.8) && (Tz-TC)<(1/1.8)
            HP_speed=2;
        elseif (Tz-TC)>=(1/1.8)
            HP_speed=2;
        end
    elseif HP_speed==-1   % current status = low speed heating
        if (TH-Tz)<0
            HP_speed=0;
        elseif (TH-Tz)>=0 && (TH-Tz)<(0.5/1.8)
            HP_speed=-1;
        elseif (TH-Tz)>=(0.5/1.8) && (TH-Tz)<(1/1.8)
            HP_speed=-1;
        elseif (TH-Tz)>=(1/1.8)
            HP_speed=-2;
        end
    elseif HP_speed==-2   % current status = high speed heating
        if (TH-Tz)<0
            HP_speed=0;
        elseif (TH-Tz)>=0 && (TH-Tz)<(0.5/1.8)
            HP_speed=-1;
        elseif (TH-Tz)>=(0.5/1.8) && (TH-Tz)<(1/1.8)
            HP_speed=-2;
        elseif (TH-Tz)>=(1/1.8)
            HP_speed=-2;
        end
    end
end
%% Calculate the sensible/latant capacity and HP power
if HP_status==1 && HP_speed>0 % cooling case
    x1_real=Tz*1.8+32;     % [F]
    x1=max(min(x1_real,80),65);
    x2_real=Tz_d*1.8+32;   % [F]
    x2=max(min(x2_real,61),50);
    x3_real=To*1.8+32;     % [F]
    if HP_speed==1
        x3=max(min(x3_real,110),75);
    elseif HP_speed==2
        x3=max(min(x3_real,110),80);
    end
    
    if HP_speed==1
        SenCap=Cooling_LSpeedTable(1,1)+Cooling_LSpeedTable(1,2)*x1+Cooling_LSpeedTable(1,3)*x2+...
            Cooling_LSpeedTable(1,4)*x3+Cooling_LSpeedTable(1,5)*x1*x2+Cooling_LSpeedTable(1,6)*x1*x3+...
            Cooling_LSpeedTable(1,7)*x2*x3+Cooling_LSpeedTable(1,8)*x1^2+Cooling_LSpeedTable(1,9)*x2^2+...
            Cooling_LSpeedTable(1,10)*x3^2;  % [btu/hr]
        TotCap=Cooling_LSpeedTable(3,1)+Cooling_LSpeedTable(3,2)*x1+Cooling_LSpeedTable(3,3)*x2+...
            Cooling_LSpeedTable(3,4)*x3+Cooling_LSpeedTable(3,5)*x1*x2+Cooling_LSpeedTable(3,6)*x1*x3+...
            Cooling_LSpeedTable(3,7)*x2*x3+Cooling_LSpeedTable(3,8)*x1^2+Cooling_LSpeedTable(3,9)*x2^2+...
            Cooling_LSpeedTable(3,10)*x3^2;  % [btu/hr]
        Power=Cooling_LSpeedTable(4,1)+Cooling_LSpeedTable(4,2)*x1+Cooling_LSpeedTable(4,3)*x2+...
            Cooling_LSpeedTable(4,4)*x3+Cooling_LSpeedTable(4,5)*x1*x2+Cooling_LSpeedTable(4,6)*x1*x3+...
            Cooling_LSpeedTable(4,7)*x2*x3+Cooling_LSpeedTable(4,8)*x1^2+Cooling_LSpeedTable(4,9)*x2^2+...
            Cooling_LSpeedTable(4,10)*x3^2;  % [W]
    elseif HP_speed==2
        SenCap=Cooling_HSpeedTable(1,1)+Cooling_HSpeedTable(1,2)*x1+Cooling_HSpeedTable(1,3)*x2+...
            Cooling_HSpeedTable(1,4)*x3+Cooling_HSpeedTable(1,5)*x1*x2+Cooling_HSpeedTable(1,6)*x1*x3+...
            Cooling_HSpeedTable(1,7)*x2*x3+Cooling_HSpeedTable(1,8)*x1^2+Cooling_HSpeedTable(1,9)*x2^2+...
            Cooling_HSpeedTable(1,10)*x3^2;  % [btu/hr]
        TotCap=Cooling_HSpeedTable(3,1)+Cooling_HSpeedTable(3,2)*x1+Cooling_HSpeedTable(3,3)*x2+...
            Cooling_HSpeedTable(3,4)*x3+Cooling_HSpeedTable(3,5)*x1*x2+Cooling_HSpeedTable(3,6)*x1*x3+...
            Cooling_HSpeedTable(3,7)*x2*x3+Cooling_HSpeedTable(3,8)*x1^2+Cooling_HSpeedTable(3,9)*x2^2+...
            Cooling_HSpeedTable(3,10)*x3^2;  % [btu/hr]
        Power=Cooling_HSpeedTable(4,1)+Cooling_HSpeedTable(4,2)*x1+Cooling_HSpeedTable(4,3)*x2+...
            Cooling_HSpeedTable(4,4)*x3+Cooling_HSpeedTable(4,5)*x1*x2+Cooling_HSpeedTable(4,6)*x1*x3+...
            Cooling_HSpeedTable(4,7)*x2*x3+Cooling_HSpeedTable(4,8)*x1^2+Cooling_HSpeedTable(4,9)*x2^2+...
            Cooling_HSpeedTable(4,10)*x3^2;  % [W]
    end
    % convert the unit
    m_sup=m_sup_all(1,HP_speed+1)*0.0283*1.225/60;  % cfm to kg/s
    SenCap=SenCap*0.293;  % btu/hr to W
    TotCap=TotCap*0.293;  % btu/hr to W
    Power=0.001*Power;    % W to kW
    Cap(timestep,1)=SenCap;
    Cap(timestep,2)=TotCap;
    Cap(timestep,3)=Power;
    % based on the HP input air (equal to zone air) and sensible/total
    % capacity to calculate the HP output air
    T_sup=Tz-SenCap/(1000*m_sup*(1.006+1.86*0.007))+1.5/1.8;
    w_sup=(1.006*(Tz-(T_sup-1.5/1.8))+1.86*Tz*wz+2501*wz-(TotCap/(1000*m_sup)))/(1.86*(T_sup-1.5/1.8)+2501);
elseif HP_status==1 && HP_speed<0 % heating case
    x1_real=To*1.8+32;     % [F]
    x2_real=To_d*1.8+32;   % [F]
    x3_real=Tz*1.8+32;     % [F]
    if HP_speed==-1
        x1=max(min(x1_real,68.20),45.55);
        x2=max(min(x2_real,41.14),34.48);
        x3=max(min(x3_real,72.16),67.51);
    elseif HP_speed==-2
        x1=max(min(x1_real,60.27),43.10);
        x2=max(min(x2_real,37.64),34.38);
        x3=max(min(x3_real,72.16),67.85);
    end
    
    if HP_speed==-1
        SenCap=Heating_LSpeedTable(35,1)+Heating_LSpeedTable(35,2)*x1+Heating_LSpeedTable(35,3)*x2+...
            Heating_LSpeedTable(35,4)*x3+Heating_LSpeedTable(35,5)*x1*x2+Heating_LSpeedTable(35,6)*x1*x3+...
            Heating_LSpeedTable(35,7)*x2*x3+Heating_LSpeedTable(35,8)*x1*x1+Heating_LSpeedTable(35,9)*x2*x2+...
            Heating_LSpeedTable(35,10)*x3*x3;
        TotCap=Heating_LSpeedTable(37,1)+Heating_LSpeedTable(37,2)*x1+Heating_LSpeedTable(37,3)*x2+...
            Heating_LSpeedTable(37,4)*x3+Heating_LSpeedTable(37,5)*x1*x2+Heating_LSpeedTable(37,6)*x1*x3+...
            Heating_LSpeedTable(37,7)*x2*x3+Heating_LSpeedTable(37,8)*x1*x1+Heating_LSpeedTable(37,9)*x2*x2+...
            Heating_LSpeedTable(37,10)*x3*x3;
        Power=Heating_LSpeedTable(1,1)+Heating_LSpeedTable(1,2)*x1+Heating_LSpeedTable(1,3)*x2+...
            Heating_LSpeedTable(1,4)*x3+Heating_LSpeedTable(1,5)*x1*x2+Heating_LSpeedTable(1,6)*x1*x3+...
            Heating_LSpeedTable(1,7)*x2*x3+Heating_LSpeedTable(1,8)*x1*x1+Heating_LSpeedTable(1,9)*x2*x2+...
            Heating_LSpeedTable(1,10)*x3*x3+...
            Heating_LSpeedTable(4,1)+Heating_LSpeedTable(4,2)*x1+Heating_LSpeedTable(4,3)*x2+...
            Heating_LSpeedTable(4,4)*x3+Heating_LSpeedTable(4,5)*x1*x2+Heating_LSpeedTable(4,6)*x1*x3+...
            Heating_LSpeedTable(4,7)*x2*x3+Heating_LSpeedTable(4,8)*x1*x1+Heating_LSpeedTable(4,9)*x2*x2+...
            Heating_LSpeedTable(4,10)*x3*x3;
    elseif HP_speed==-2
        SenCap=Heating_HSpeedTable(35,1)+Heating_HSpeedTable(35,2)*x1+Heating_HSpeedTable(35,3)*x2+...
            Heating_HSpeedTable(35,4)*x3+Heating_HSpeedTable(35,5)*x1*x2+Heating_HSpeedTable(35,6)*x1*x3+...
            Heating_HSpeedTable(35,7)*x2*x3+Heating_HSpeedTable(35,8)*x1*x1+Heating_HSpeedTable(35,9)*x2*x2+...
            Heating_HSpeedTable(35,10)*x3*x3;
        TotCap=Heating_HSpeedTable(37,1)+Heating_HSpeedTable(37,2)*x1+Heating_HSpeedTable(37,3)*x2+...
            Heating_HSpeedTable(37,4)*x3+Heating_HSpeedTable(37,5)*x1*x2+Heating_HSpeedTable(37,6)*x1*x3+...
            Heating_HSpeedTable(37,7)*x2*x3+Heating_HSpeedTable(37,8)*x1*x1+Heating_HSpeedTable(37,9)*x2*x2+...
            Heating_HSpeedTable(37,10)*x3*x3;
        Power=Heating_HSpeedTable(1,1)+Heating_HSpeedTable(1,2)*x1+Heating_HSpeedTable(1,3)*x2+...
            Heating_HSpeedTable(1,4)*x3+Heating_HSpeedTable(1,5)*x1*x2+Heating_HSpeedTable(1,6)*x1*x3+...
            Heating_HSpeedTable(1,7)*x2*x3+Heating_HSpeedTable(1,8)*x1*x1+Heating_HSpeedTable(1,9)*x2*x2+...
            Heating_HSpeedTable(1,10)*x3*x3+...
            Heating_HSpeedTable(4,1)+Heating_HSpeedTable(4,2)*x1+Heating_HSpeedTable(4,3)*x2+...
            Heating_HSpeedTable(4,4)*x3+Heating_HSpeedTable(4,5)*x1*x2+Heating_HSpeedTable(4,6)*x1*x3+...
            Heating_HSpeedTable(4,7)*x2*x3+Heating_HSpeedTable(4,8)*x1*x1+Heating_HSpeedTable(4,9)*x2*x2+...
            Heating_HSpeedTable(4,10)*x3*x3;
    end
    % convert the unit
    m_sup=m_sup_all(2,(-1)*HP_speed+1)*0.0283*1.225/60;  % cfm to kg/s
    SenCap=SenCap*0.293;  % btu/hr to W
    TotCap=TotCap*0.293;  % btu/hr to W
    Power=0.001*Power;    % W to kW
    Cap(timestep,1)=SenCap;
    Cap(timestep,2)=TotCap;
    Cap(timestep,3)=Power;
    % based on the HP input air (equal to zone air) and sensible/total
    % capacity to calculate the HP output air
    T_sup=Tz+SenCap/(1000*m_sup*(1.006+1.86*0.00875))-1.1/1.8;
    w_sup=(-1.006*(T_sup+1.1/1.8-Tz)+1.86*Tz*wz+2501*wz+(TotCap/(1000*m_sup)))/(1.86*(T_sup+1.1/1.8)+2501);
else  % for the case HP is not running or bypass
    m_sup=0;
    T_sup=Tz;
    w_sup=wz;
    Power=0;
end
    
Meas=[m_sup,T_sup,w_sup,Tz,wz,To,Power];

if timestep==1440
    % save('CapRec.mat','Cap')
    clear Cooling_HSpeedTable Cooling_LSpeedTable Heating_HSpeedTable Heating_LSpeedTable HP_speed m_sup_all Cap
end

end