### Description
This repo is developed for the STBE journal paper **Advanced Co-simulation Framework for Assessing the Interplay between Occupant Behaviors and Demand Flexibility in Commercial Buildings**.

### Prerequisite
**Matlab 2020a**
- Simulink
- Parallel Computing Toolbox
- Database Toolbox
- Database Toolbox Interface for MongoDB
- Deep Learning Toolbox 
- Deep Learning Toolbox Converter for TensorFlow Models
- Statistics and Machine Learning Toolbox
- Optimization Toolbox

**MongoDB 4.0**
- Download here: [MongoDB community version](https://www.mongodb.com/try/download/community)
- Other versions may work as well, but not verified.
- Install it with default settings.
- Create `C:\data\db\` after installation.

**Matlab MongoDB connection** 
- Create database `HILFT` in MongoDB.
- If `conn = mongo(server,port,dbname)` run into an issue, make sure server, port, dbname match your MongoDB. By default these inputs should be: `server=’localhost’`; `port=27017`; `dbname='[data base you created]'`. The easiest way to find this information is to connect the database using MongDB Compass, and the host information can be found in the left panel.

**EnergyPlus 9.3**
- Directory must be added to the path.

### File description
- **`testbed/callSim.m`** The function for all simulation except HVAC.
- **`testbed/VirtualHP`** The function for a virtual air source heat pump.
- **`testbed/DataDL.m`** Download data from MongoDB, EPlus folder, and HardwareData folder, then save them to a `.mat` file. File name is constructed as foldername_MMDDYYYY_HHMMSS.
- **`testbed/CTRL`** Include control models related scripts. 
- **`testbed/HardwareData`** Place to store hardware data. This is an optional folder, only for hardware-in-the-loop simulation.
- **`testbed/OBM`** OBM related scripts.
- **`testbed/DB`** MongoDB reading/writing related scripts.
- **`testbed/VB`** Virtual building Simulink model.
- **`testbed/DBLoc.mat`** It stores the database and collection names for each run. 
- **`testbed/ExampleCall.m`** Example master script to run the simulation.
