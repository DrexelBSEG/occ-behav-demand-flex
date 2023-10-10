# Prerequisite
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


# File description
- **`callSim.m`** The function for all simulation side activity. 
- **`DataDL.m`** Download data from MongoDB, EPlus folder, and HardwareData folder, then save them to a `.mat` file. File name is constructed as foldername_MMDDYYYY_HHMMSS.
- **`/CTRL`** Include control models related scripts. 
- **`/HardwareData`** Place to store hardware data.
- **`/OBM`** OBM related scripts.
- **`/DB`** MongoDB reading/writing related scripts.
- **`/VB`** Virtual building Simulink model.
- **`DBLoc.mat`** It stores the database and collection names for each run. 
- **`ExampleCall.m`** Example file to call `callSim.m`.
