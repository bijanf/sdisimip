#!/bin/bash
##SBATCH --qos=medium
##SBATCH --qos=priority
#SBATCH --qos=short
##SBATCH --partition=priority
#SBATCH --partition=largemem
#SBATCH --job-name=sd01_3
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=16
#SBATCH --output=../../data/%j.out 
#SBATCH --account=swim
#SBATCH --mail-type=FAIL                                                                     
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
var=$1
scenario=$2
model=$3
#latlon="lat44.5_46.5_lon5._7."
latlon="lat38.25_39.75_lon66.25_67.75"
steps="3"
time_slice=$4
data_dir="../../out/"
sd_python_code="../isimip3basd/statistical_downscaling.py"
resume=False
###############################
if [ "$model" == "ukesm1-0-ll" ]
then 
    realization="r1i1p1f2"
else
    realization="r1i1p1f1"
fi  

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
mkdir -p ${data_dir}/GCMoutput_fine/
if [ "${downscaling_to}" == "${res1}" ]
then 
if [ "${var}" == "tas" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v air_temperature -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi 

if [ "${var}" == "pr" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v precipitation_flux --lower-bound 0 --lower-threshold 0.0000011574 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi 

if [ "${var}" == "rsds" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v surface_downwelling_shortwave_flux_in_air --lower-bound 0 --lower-threshold 0.0001 --upper-bound 1 --upper-threshold 0.9999 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi 

if [ "${var}" == "tasrange" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v air_temperature --lower-bound 0 --lower-threshold 0.01 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi

if [ "${var}" == "tasskew" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v air_temperature --lower-bound 0 --lower-threshold .0001 --upper-bound 1 --upper-threshold 0.9999 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi

fi



if [ "${downscaling_to}" != "${res1}" ]
then
#if  [ "${downscaling_to}" != "chesla" ]
#then 
if [ "${var}" == "tas" ]
then

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v air_temperature -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_from}.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi 
if [ "${var}" == "pr" ]
then
python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v precipitation_flux --lower-bound 0 --lower-threshold 0.0000011574 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_from}.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc 

fi 

if [ "${var}" == "rsds" ]
then
python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v surface_downwelling_shortwave_flux_in_air --lower-bound 0 --lower-threshold 0.0001 --upper-bound 1 --upper-threshold 0.9999 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_from}.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc 

fi

if [ "${var}" == "tasrange" ]
then
python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v air_temperature --lower-bound 0 --lower-threshold 0.01 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_from}.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc 

fi

if [ "${var}" == "tasskew" ]
then
python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v air_temperature --lower-bound 0 --lower-threshold .0001 --upper-bound 1 --upper-threshold 0.9999 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_from}.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc 

fi

fi

