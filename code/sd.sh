#!/bin/bash
#SBATCH --qos=medium
##SBATCH --qos=priority
##SBATCH --partition=priority
#SBATCH --partition=largemem
#SBATCH --job-name=sd_mem3
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=16
#SBATCH --output=../data/%j.out 
#SBATCH --account=swim
#SBATCH --mail-type=BEGIN,FAIL,END                                                                     
#SBATCH --mail-user=fallah
########################## NAMELIST ###################################
set -ex 
member=3
res1=0.21428571428571427
res2=0.1
res3=0.04838709677419355
res4=0.023809523809523808
res5=0.011811023622047244

###############################
var="pr"
scenario="ssp585"
model="gfdl-esm4"
latlon="lat38._40._lon68._70."
steps="2"
future_time_step="2015_2050"
###############################





if [ "${steps}" == "1" ]
then 
   downscaling_to=${res1}

fi 

if [ "${steps}" == "2" ]
then
   downscaling_from=${res1}
   downscaling_to=${res2}
fi 

if [ "${steps}" == "3" ]
then
    downscaling_from=${res2}
    downscaling_to=${res3}
fi 

if [ "${steps}" == "4" ]
then
    downscaling_from=${res3}
    downscaling_to=${res4}
fi 

if [ "${steps}" == "5" ]
then
    downscaling_from=${res4}
    downscaling_to=${res5}
fi 

########################## End NAMELIST ###############################

#################### 0.5  to 0.25 #####################################
mkdir -p ../data/GCMoutput_fine/
if [ "${downscaling_to}" == "${res1}" ]
then 
if [ "${var}" == "tas" ]
then 

python ../isimip3basd/statistical_downscaling.py --n-processes 8 --resume-job False --randomization-seed 0 -v air_temperature -o ../data/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_1979_2014_${downscaling_to}.nc -s ../data/GCMoutput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BA.nc -f ../data/GCMoutput_fine/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BASD_${member}_${downscaling_to}.nc

fi 

if [ "${var}" == "pr" ]
then 

python ../isimip3basd/statistical_downscaling.py --n-processes 16 --resume-job False --randomization-seed 0 -v precipitation_flux --lower-bound 0 --lower-threshold 0.0000011574 -o ../data/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_1979_2014_${downscaling_to}.nc -s ../data/GCMoutput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BA.nc -f ../data/GCMoutput_fine/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BASD_${member}_${downscaling_to}.nc

fi 

fi



if [ "${downscaling_to}" != "${res1}" ]
then
#if  [ "${downscaling_to}" != "chesla" ]
#then 
if [ "${var}" == "tas" ]
then

python ../isimip3basd/statistical_downscaling.py --n-processes 16 --resume-job False --randomization-seed 0 -v air_temperature -o ../data/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_1979_2014_${downscaling_to}.nc -s ../data/GCMoutput_fine/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BASD_${member}_${downscaling_from}.nc -f ../data/GCMoutput_fine/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BASD_${member}_${downscaling_to}.nc

fi 
if [ "${var}" == "pr" ]
then
python ../isimip3basd/statistical_downscaling.py --n-processes 16 --resume-job False --randomization-seed 0 -v precipitation_flux --lower-bound 0 --lower-threshold 0.0000011574 -o ../data/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_1979_2014_${downscaling_to}.nc -s ../data/GCMoutput_fine/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BASD_${member}_${downscaling_from}.nc -f ../data/GCMoutput_fine/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BASD_${member}_${downscaling_to}.nc 

fi 



fi

#if [ "${downscaling_to}" == "chesla" ]
#then 
#python ../isimip3basd/statistical_downscaling.py --n-processes 16 --resume-job False --randomization-seed 0 -v air_temperature -o ../data/OBSinput_fine/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__lat39._40._lon68._70._cut_mergetime_1979_2014_${downscaling_to}.nc -s ../data/GCMoutput_fine/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BASD_${member}_${downscaling_from}.nc -f ../data/GCMoutput_fine/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${future_time_step}_BASD_${member}_${downscaling_to}.nc
#fi

