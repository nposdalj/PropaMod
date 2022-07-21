Transmission loss tools

Summary: This set of scripts is designed to run batched transmission loss profiles around a site of interest, by simulating an omni-directional source as the reciever, per the theorem of acoustic reciprocity.

Input:
ESME workbench (http://esme.bu.edu) produces text files describing radials around a site of interest using model-based sound speed profiles, using high resolution bathymetry and incorporating sediment properties. 
After running a simulation in ESME, check this directory for the propagation model input and output files:

C:\Users\Harp\AppData\Roaming\ESME Workbench\Database\scenarios

These files essentially match those used by Mike Porter's ACT, and can be tweaked to run simulations at different frequencies.


Output: 

- Text files matching the format required for input into Bellhop or Ramgeo. These are created by ESME and re-named/modified (if desired) by batch_tl.

- A .mat file containing the following:

rr: a vector of range reciever distances from the source.

thisAngle: Tells you the angle of each radial from the sensor.

botDepthSort: A matrix where each row contains the bottom depth along a radial (direction given by 'thisAngle', range given by rr).

nrr: number of range recievers

rd_all: cell array of reciever depths in meters. Vectors within cells can be longer for radials that contain deeper bathymetry.

sd: source depth in meters.

sortedTLVec: Cell array containing vertical transmission loss profiles for each radial.



Instructions:

Copy the scenario file of interest to a different folder. 

eg. E:\Data\0ycwwb20  

Then run something like:  

batch_tl('E:\Data\0ycwwb20\',2000,'bellhop')  

or multiple frequencies  

batch_tl('E:\Data\0ycwwb20\',[2000:1000:10000],'bellhop')  

or ramgeo  

batch_tl('E:\Data\0ycwwb20\',[20:10:100],'ramgeo')  


The second argument is the new frequency you want to run in Hz. See comments within the script.

You can also modify the sediment composition if it's empty (this happens occasionally for some regions) by including an optional 4th argument:

batch_tl('E:\Data\0ycwwb20\',[2000:1000:10000],'bellhop', '1336.5633 1470 146.7 1.145 0.00148 0')
(Currently only implemented for bellhop. Let me know if you need it for other cases.)



Known issues: 
There seems to be a bug in the RAMgeo step size tool. If you change the default vertical or horizontal steps size, the transmission loss profile size becomes unpredictable.
