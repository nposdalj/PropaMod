# PropagationModeling

## Introduction

The PropagationModeling repository contains tools for modeling sound propagation for the purpose of marine animal density estimation.

PropagationModeling is centered on two main steps and their associated scripts:
* Creating sound speed profiles (makeSSP.m)
* Modeling sound propagation (bellhopPropMod.m)


## Getting Started
* **Install the Acoustics Toolbox.** Head to http://oalib.hlsresearch.com/AcousticsToolbox/ and download the older of the two versions, which includes the source code.
![Screenshot of Acoustics Toolbox website.](https://github.com/nposdalj/PropagationModeling/blob/main/PropagationModeling_README_fig1.png)
* The toolbox includes BELLHOP, the program used to model sound propagation. For more information on BELLHOP, see the program’s [documentation](http://oalib.hlsresearch.com/Rays/HLS-2010-1.pdf).
* **Add the toolbox and PropagationModeling to your MATLAB path.**
* Set up a directory for all of your data with the following subdirectories:
  * HYCOM_oceanState
  * SSPs
  * Radials
  * Plots


## Usage

### U.1 Download ocean state data and generate sound speed profiles: `plotSSP.m`
`plotSSP.m` is responsible for calculating the sound speed profile at each study site.
The script calls the function `hycom_sampleMonths.m`, which samples ocean state data.
* `hycom_sampleMonths.m` is based on the script `ext_hycom_gofs_3_1.m`, which was created by Ganesh Gopalakrishnan to download HYCOM ocean state data as .mat files for a given region.

#### U.1.1 Required data
* Create a local folder on your device where HYCOM data can be downloaded

#### U.1.2 User input
Before hitting RUN, under Parameters defined by user, enter:
* The information for your input and export directories.
* Coordinates of your study sites.
* The months when your downloaded HYCOM data begins and ends.
* Select whether or not to plot SSPs as they are calculated. These plots are not saved.

#### U.1.3 Output
`plotSSP.m` will produce 3 tables for each site. These are the average SSP for the entire year, the average SSP for the month with the fastest average sound speed (calculated using the sound speeds between 200 and 1000 m *note to change: it doesn't use ALL of these points), and the average SSP for the month with the slowest average sound speed. The names of the minimum and maximum tables include the number of the month. Each table lists sound speeds from 0 m to 5000 m, with a resolution of 1 m.

plotSSP.m generates sound speeds down to a depth of 5000 m even if the bathymetry at the site is shallower. This allows the next process (bellhopDetRange.m) to model sound propagation at locations within a select radius of the site where the bathymetry is deeper.

#### U.1.4 Related scripts
* `plotSSP.m` calls the function `hycom_sampleMonths.m` to download HYCOM ocean state data.
  * In turn, `hycom_sampleMonths.m` calls `ext_hycom_gofs_93_0.m` to download the data.
* `plotSSP.m` calls the function `salt_water_c.m` to calculate sound speed using water temperature, salinity, and depth.
* `plotSSP.m` calls the function `inpaint_nans.m` to extrapolate theoretical sound speed below the bathymetry, using existing data points at that depth.


### U.2 Model sound propagation: `bellhopDetRange.m`
`bellhopDetRange.m` constructs sound propagation radials around your site using your specified parameters, using BELLHOP. It saves .bty, .env, .shd, and .prt files to an intermediate directory, before moving them to your final export directory along with a .txt file listing your parameters. `bellhopDetRange.m` also creates radial and polar plots and saves these in the export directory.

#### U.2.1 Required data
* Bathymetry data.
* Your sound speed profile for the site generated with `plotSSP.m`.

#### U.2.2 User input
Before hitting RUN, under Parameters defined by user, enter:
* Author name and notes (optional)
* Name of site and region
* Input and Export paths:
  * Google Drive character (if using Google Drive File Stream)
  * Input directory
  * Intermediate save directory on your local machine
  * Final save directory
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
Every time `bellhopDetRange.m` is run, it creates new folders (with a name in the format YYMMDDx, where x is one letter of the alphabet) under the intermediate, save, and plot directories.

In the intermediate and save directories, this folder contains subfolders for each frequency specified by the user for this run. A .txt file listing the input parameters for this run is also included. In turn, the frequency subfolders include one of the following for each radial:
* Bathymetry (.bty) file
* Environment (.env) file
* Shade (.shd) file
* Print (.prt) file.

Under the plot directory, this folder contains plots of the received level for each radial, as well as polar plots for the region at the depths requested by the user.

For each frequency, `bellhopDetRange.m` also saves a .mat file containing certain values required for animal detection simulation.

#### U.2.4 Related Scripts
`bellhopDetRange.m` calls two functions in the PropagationModeling repository:
* `makeBTY.m`: Generates the bathymetry (.bty) file for each radial.
* `makeEnv.m`: Generates the environment (.env) file for each radial.

`bellhopDetRange.m` also calls two functions in the Acoustics Toolbox:
* `bellhop.m`: Runs BELLHOP for each radial. Shade (.shd) and print (.prt) files are generated by BELLHOP as a result.
* `read_shd.m`: Reads data from the radial .shd files. Used in bellhopDetRange.m for plotting.


### U.3 Prepare for detection simulation: `pDetSim_constructWS.m`
A few lines in `bellhopDetRange.m` serve to package information for animal detection simulation. `pDetSim_constructWS.m` completes this process.


## Support
For questions regarding the PropagationModeling repository, please reach out to Natalie Posdaljian at nposdalj@ucsd.edu.


## Authors
* Natalie Posdaljian
* Aaron Deans
* Vanessa ZoBell
* Eric Snyder
