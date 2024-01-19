![Banner and logo for PropaMod.](https://github.com/nposdalj/PropaMod/blob/main/PM_GitHub_Banner.png)

# PropaMod

## Introduction

The PropaMod repository contains tools for modeling sound propagation for the purpose of marine animal density estimation.

PropaMod is centered on two main steps, each associated with a particular script. The user must enter their desired parameters in each.
* Creating sound speed profiles with `makeSSP.m`
* Modeling sound propagation with `bellhop_PropMod.m`


## Getting Started
* **Install the Acoustics Toolbox.** Head to http://oalib.hlsresearch.com/AcousticsToolbox/ and download the older of the two versions, which includes the source code.
![Screenshot of Acoustics Toolbox website.](https://github.com/nposdalj/PropaMod/blob/main/PropagationModeling_README_fig1.png)
* The toolbox includes BELLHOP, the program used to model sound propagation. For more information on BELLHOP, see the program’s [documentation](http://oalib.hlsresearch.com/Rays/HLS-2010-1.pdf).
* **Add the toolbox and PropaMod to your MATLAB path.**
* Set up a directory for all of your data with the following subdirectories:
  * HYCOM_oceanState
  * SSPs
  * Radials
  * Plots
  * Bathymetry
  * DetSim_Workspace
  * \Sediment_Data <- ONLY required if using bottom model Options G or Y in bellhop_PropMod.m


## Usage

The workflow for PropaMod is summarized here:
![Workflow diagram for PropaMod.](https://github.com/nposdalj/PropaMod/blob/main/PropagationModeling_README_Figure2.png)

User-operated scripts (bold, color border) contain sections which must be edited by the user; other white scripts are functions called by the user-operated scripts.
Yellow scripts are contained in the Acoustics Toolbox. Red scripts are called are called only when using sediment data. Blue boxes are function outputs.

### U.1 Download ocean state data and generate sound speed profiles: `makeSSP.m`
`makeSSP.m` is responsible for calculating the sound speed profile at each study site.
The script calls the function `hycom_sampleMonths.m`, which samples ocean state data.
* hycom_sampleMonths.m is based on the script `ext_hycom_gofs_3_1.m`, which was created by Ganesh Gopalakrishnan to download HYCOM ocean state data as .mat files for a given region.

#### U.1.1 Required data
* Create a local folder on your device where HYCOM data can be downloaded

#### U.1.2 User input
Before hitting RUN, under Parameters defined by user, enter:
* The information for your input and export directories, as well as your local HYCOM download directory.
* The coordinates of your study sites.
* The start and end months of your study period.
* Select whether or not to plot SSPs as they are calculated. These plots are not saved.

#### U.1.3 Output
`makeSSP.m` will produce 3 tables for each site. These are the average SSP for the entire year, the average SSP for the month with the fastest average sound speed (calculated using the sound speeds every 100m between 200 and 1000m), and the average SSP for the month with the slowest average sound speed. The names of the minimum and maximum tables include the number of the month. Each table lists sound speeds from 0 m to 5000 m, with a resolution of 1 m.

makeSSP.m generates sound speeds down to a depth of 5000 m even if the bathymetry at the site is shallower. This allows the next process (bellhop_PropMod.m) to model sound propagation at locations within a select radius of the site where the bathymetry is deeper.

#### U.1.4 Related scripts
* makeSSP.m calls the function `hycom_sampleMonths.m` to download HYCOM ocean state data.
  * In turn, hycom_sampleMonths.m calls `ext_hycom_gofs_93_0.m` to download the data.
* makeSSP.m calls the function `salt_water_c.m` to calculate sound speed using water temperature, salinity, and depth.
* makeSSP.m calls the function `inpaint_nans.m` to extrapolate theoretical sound speed below the bathymetry, using existing data points at that depth.


### U.2 Model sound propagation: `bellhop_PropMod.m`
`bellhop_PropMod.m` constructs sound propagation radials around your site using your specified parameters, using BELLHOP. It saves .bty, .env, .shd, and .prt files to an intermediate directory (since BELLHOP cannot export files to Google Drive directly), before moving them to your final export directory along with a .txt file listing your parameters. bellhop_PropMod.m also creates radial and polar plots and saves these in the export directory.

#### U.2.1 Required data
* Bathymetry data (under the Bathymetry subdirectory, as a text file titled "bathy.txt")
* Your sound speed profile for the site generated with `makeSSP.m`.

#### U.2.2 User input
Before hitting RUN, under Parameters defined by user, enter:
* Author name and notes (optional)
* Name of site and region
* Input and Export paths, including intermediate save directory on your local machine
* SSP Type (Mean, Maximum, or Minimum)
* Source and hydrophone configuration
  * Source level
  * Source depth
  * Hydrophone latitude, longitude, and depth
  * Source frequency(ies)
* Output range and resolution
  * Range of radials you want to model
  * Range resolution
  * Depth resolution
  * Number of radials (this determines your angular resolution)
* Plot output
  * Specify whether to generate plots or not
  * Minimum received level to plot
  * Received level colorbar maximum
  * Specify minimum depth, maximum depth, and step for polar plots

#### U.2.3 Output
Every time `bellhop_PropMod.m` is run, it creates new folders (with a name in the format YYMMDDx, where x is one letter of the alphabet) under the intermediate, save, and plot directories.

In the intermediate and save directories, this folder contains subfolders for each frequency specified by the user for this run. A .txt file listing the input parameters for this run is also included. In turn, the frequency subfolders include one of the following for each radial:
* Bathymetry (.bty) file
* Environment (.env) file 
* Shade (.shd) file
* Print (.prt) file.

Under the plot directory, this folder contains plots of the received level for each radial, as well as polar plots for the region at the depths requested by the user.

For each frequency, bellhop_PropMod.m also saves a .mat file containing certain values required for animal detection simulation.

#### U.2.4 Related Scripts
bellhop_PropMod.m calls two functions in the PropaMod repository:
* `loadBTY.m`: Loads the GEBCO bathymetry data.
* `getGrainSize.m`: Calculates the grain size of each radial, if grain size is being used.
* `imlgs2hfeva.m`: Converts IMLGS sediment definitions to HFEVA definitions, if IMLGS sediment data is being used.
* `makeBTY.m`: Generates the bathymetry (.bty) file for each radial.
* `makeEnv.m`: Generates the environment (.env) file for each radial.

bellhop_PropMod.m also calls two functions in the Acoustics Toolbox:
* `bellhop.m`: Runs BELLHOP for each radial. Shade (.shd) and print (.prt) files are generated by BELLHOP as a result.
* `read_shd.m`: Reads data from the radial .shd files. Used in bellhop_PropMod.m for plotting.


### U.3 Prepare for detection simulation: `pDetSim_constructWS.m`
A few lines in `bellhop_PropMod.m` serve to package information for animal detection simulation. `pDetSim_constructWS.m` completes this process.


## Support
For questions regarding the PropaMod repository, please reach out to Natalie Posdaljian at nposdalj@ucsd.edu.


## Authors
* Natalie Posdaljian
* Aaron Deans
* Vanessa ZoBell
* Eric Snyder
