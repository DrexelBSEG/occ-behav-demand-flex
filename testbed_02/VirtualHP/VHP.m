function Meas=VHP(timestep)
%% global variable
persistent DBName CollName conn SimData FirstTimestep SimDALabel SimDAFields SimCond CtrlSigLabel CtrlSigDAFields CtrlSigCond
% read the data from BD
if timestep==1
    DBName=load('DBLoc.mat').DBName;
    CollName=load('DBLoc.mat').CollName;
    conn = mongo('localhost',27017,DBName);
    SimData=find(conn,CollName,'Query',['{"DocType":"SimData"}']);
    FirstTimestep=SimData(1).Time;
    SimDALabel={'T_z','Tdp_z','w_z','T_out','Tdp_out','w_out','Tz_cspt','Tz_hspt'};
    SimDAFields=label2mongofield_find(SimDALabel);
    SimCond=zeros(1,length(SimDALabel));
    CtrlSigLabel={'sys_status'};
    CtrlSigDAFields=label2mongofield_find(CtrlSigLabel);
    CtrlSigCond=zeros(1,length(CtrlSigLabel));
end
clock=FirstTimestep+(timestep-1)*60;
SimDB=find(conn,CollName,'Query',['{"Time":',num2str(clock),...
    ',"DocType":"SimData"}'],'Projection',SimDAFields);
for i=1:length(SimDALabel)
    SimCond(i)=SimDB.(char(SimDALabel(i)));
end
Tz=SimCond(1);
Tz_d=SimCond(2);
wz=SimCond(3);
To=SimCond(4);
To_d=SimCond(5);
wo=SimCond(6);
TC=SimCond(7);
TH=SimCond(8);
CtrlSigDB=find(conn,CollName,'Query',['{"Time":',num2str(clock),...
    ',"DocType":"SupvCtrlSig"}'],'Projection',CtrlSigDAFields);
HP_status=CtrlSigDB.(char(CtrlSigLabel(1)));
HP_status=HP_status(2);
% run the virtual HP
Meas=VirtualHP(timestep,Tz,Tz_d,wz,To,To_d,wo,TC,TH,HP_status);

end