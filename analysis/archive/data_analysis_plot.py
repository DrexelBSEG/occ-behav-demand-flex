#%% import
import pandas as pd
import seaborn as sns
import itertools
import matplotlib.pyplot as plt
#sns.set(style="darkgrid")
#sns.set(style="whitegrid")
#sns.set_style("white")
sns.set(style="whitegrid",font_scale=2)
import matplotlib.collections as clt


import ptitprince as pt

#%% load data
df1 = pd.read_csv ("eff_peak.csv", sep= ",")
df2 = pd.read_csv ("shed_peak.csv", sep= ",")
# Add a column to df2 indicating the source
df1['Source'] = 'Baseline'
df2['Source'] = 'Shedding'
# Append df2 to df1 and create a new data frame
df = pd.concat([df2,df1], ignore_index=True)
# Create a new data frame for calculating difference between each possible pair
dff = pd.DataFrame()
combinations = list(itertools.product(df1['Energy Use (HVAC and Personal Equipment) [kWh]'], df2['Energy Use (HVAC and Personal Equipment) [kWh]']))
dff['Energy Saving (HVAC and Personal Equipment) [kWh]'] = [x[0] - x[1] for x in combinations]
dff['Energy Saving (HVAC and Personal Equipment) [%]'] = [(x[0] - x[1])/x[0]*100 for x in combinations]
dff['Type'] = 'Change'
# create a new data frame for occupant cool period plot
df1_cool = pd.melt(df1,value_vars=['Occ#1 Cool Duration [mins]','Occ#2 Cool Duration [mins]','Occ#3 Cool Duration [mins]', \
                                  'Occ#4 Cool Duration [mins]','Occ#5 Cool Duration [mins]','Occ#6 Cool Duration [mins]', \
                                  'Occ#7 Cool Duration [mins]'],var_name='Occupant #', value_name='Cool Duration [mins]')
df1_cool['Occupant #'] = df1_cool['Occupant #'].replace({'Occ#1 Cool Duration [mins]': '1', 'Occ#2 Cool Duration [mins]': '2', \
                                                       'Occ#3 Cool Duration [mins]': '3', 'Occ#4 Cool Duration [mins]': '4', \
                                                       'Occ#5 Cool Duration [mins]': '5', 'Occ#6 Cool Duration [mins]': '6', \
                                                       'Occ#7 Cool Duration [mins]': '7'})
df2_cool = pd.melt(df2,value_vars=['Occ#1 Cool Duration [mins]','Occ#2 Cool Duration [mins]','Occ#3 Cool Duration [mins]', \
                                  'Occ#4 Cool Duration [mins]','Occ#5 Cool Duration [mins]','Occ#6 Cool Duration [mins]', \
                                  'Occ#7 Cool Duration [mins]'],var_name='Occupant #', value_name='Cool Duration [mins]')
df2_cool['Occupant #'] = df2_cool['Occupant #'].replace({'Occ#1 Cool Duration [mins]': '1', 'Occ#2 Cool Duration [mins]': '2', \
                                                       'Occ#3 Cool Duration [mins]': '3', 'Occ#4 Cool Duration [mins]': '4', \
                                                       'Occ#5 Cool Duration [mins]': '5', 'Occ#6 Cool Duration [mins]': '6', \
                                                       'Occ#7 Cool Duration [mins]': '7'})
df1_cool['Source'] = 'Baseline'
df2_cool['Source'] = 'Shedding'    
df_cool = pd.concat([df2_cool,df1_cool], ignore_index=True)

df1_warm = pd.melt(df1,value_vars=['Occ#1 Warm Duration [mins]','Occ#2 Warm Duration [mins]','Occ#3 Warm Duration [mins]', \
                                  'Occ#4 Warm Duration [mins]','Occ#5 Warm Duration [mins]','Occ#6 Warm Duration [mins]', \
                                  'Occ#7 Warm Duration [mins]'],var_name='Occupant #', value_name='Warm Duration [mins]')
df1_warm['Occupant #'] = df1_warm['Occupant #'].replace({'Occ#1 Warm Duration [mins]': '1', 'Occ#2 Warm Duration [mins]': '2', \
                                                       'Occ#3 Warm Duration [mins]': '3', 'Occ#4 Warm Duration [mins]': '4', \
                                                       'Occ#5 Warm Duration [mins]': '5', 'Occ#6 Warm Duration [mins]': '6', \
                                                       'Occ#7 Warm Duration [mins]': '7'})
df2_warm = pd.melt(df2,value_vars=['Occ#1 Warm Duration [mins]','Occ#2 Warm Duration [mins]','Occ#3 Warm Duration [mins]', \
                                  'Occ#4 Warm Duration [mins]','Occ#5 Warm Duration [mins]','Occ#6 Warm Duration [mins]', \
                                  'Occ#7 Warm Duration [mins]'],var_name='Occupant #', value_name='Warm Duration [mins]')
df2_warm['Occupant #'] = df2_warm['Occupant #'].replace({'Occ#1 Warm Duration [mins]': '1', 'Occ#2 Warm Duration [mins]': '2', \
                                                       'Occ#3 Warm Duration [mins]': '3', 'Occ#4 Warm Duration [mins]': '4', \
                                                       'Occ#5 Warm Duration [mins]': '5', 'Occ#6 Warm Duration [mins]': '6', \
                                                       'Occ#7 Warm Duration [mins]': '7'})
df1_warm['Source'] = 'Baseline'
df2_warm['Source'] = 'Shedding'    
df_warm = pd.concat([df2_warm,df1_warm], ignore_index=True)
#
df1_occ = pd.read_csv ("eff_peak_occ.csv", sep= ",")
df2_occ = pd.read_csv ("shed_peak_occ.csv", sep= ",")
# Add a column to df2 indicating the source
df1_occ['Source'] = 'Baseline'
df2_occ['Source'] = 'Shedding'
# Append df2 to df1 and create a new data frame
df_occ = pd.concat([df2_occ,df1_occ], ignore_index=True)
#%% rain cloud plot
# dx = "Source"
dx = "Type"
# dy = "Occ#2 Cool Duration [mins]"
dy = "Energy Saving (HVAC and Personal Equipment) [%]"
# dy = "Energy Saving [kWh]"
# dy = "Energy Use (HVAC and Personal Equipment) [kWh]"
# dy = "Average Demand (HVAC and Personal Equipment) [W]"
# dy = "Average Warm Duration [mins]"
# dy = "Average Cool Duration [mins]"
ort = "h"
pal = "Set2"
sigma = 0.01
f, ax = plt.subplots(figsize=(14, 6))

pt.RainCloud(x = dx, y = dy, data = dff, palette = pal, bw = sigma,
                 width_viol = .6, ax = ax, orient = ort)
ax.set_xlim(left=-10,right=40)
ax.set_ylabel("Energy Saving against Baseline")
# ax.set_xlabel("Energy [kWh]")
# ax.set_xticks(range(8,15,1))
ax.set_xlabel("Percentage [%]")
ax.set_xticks(range(-10,50,10))
ax.set_yticks([])
#%%
dx = "Source"; dy = "Cool Duration [mins]"; dhue = "Occupant #"; ort = "h"; pal = "Set2"; sigma = .2
f, ax = plt.subplots(figsize=(14, 8))

ax=pt.RainCloud(x = dx, y = dy, hue = dhue, data = df_cool, palette = pal, bw = sigma, width_viol = .7,
                ax = ax, orient = ort , alpha = .65, dodge = True, pointplot = True, move = .2)
ax.set_ylabel("")
ax.set_xlim(left=0,right=25)
#%%
dx = "Source"
# dy = "Personal Heater Duration [mins]"
dy = "Cooling Setpoint Down Duration [mins]"
dhue = "Occupant #"
ort = "h"; pal = "Set2"; sigma = .2
f, ax = plt.subplots(figsize=(14, 8))

ax=pt.RainCloud(x = dx, y = dy, hue = dhue, data = df_occ, palette = pal, bw = sigma, width_viol = .7,
                ax = ax, orient = ort , alpha = .65, dodge = True, pointplot = True, move = .2)
ax.set_ylabel("")
ax.set_xlim(left=0,right=14)