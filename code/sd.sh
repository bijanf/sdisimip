#!/bin/bash
#SBATCH --job-name=BASD
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=256
#SBATCH --exclusive
#SBATCH --time=04:30:00
#SBATCH --mail-type=FAIL
#SBATCH --account=bb1243
#SBATCH --output=slogs/my_job.%j.out
#SBATCH --error=slogs/my_job.%j.err

########################## NAMELIST ###################################
set -ex 
member=4
res1=0.25
res2=0.125
res3=0.04838709677419355
res4=0.023809523809523808
res5=0.011811023622047244

###############################
source namelist.txt
source 0_export.sh
var=$1
scenario=$2
model=$3
latlon=lat${lat0}_${lat1}_lon${lon0}_${lon1}
steps="1"
time_slice=$4
data_dir="out/"
sd_python_code="../isimip3basd/code/statistical_downscaling.py"
resume=False
###############################
if [ "$model" == "ukesm1-0-ll" ] || [ "$mod_lower" == "cnrm-cm6-1" ] || [ "$mod_lower" == "cnrm-esm2-1" ]
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

    ncpdq --rdr=lon,lat,time ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_1.nc
    mv ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_1.nc ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc
    $(chunk_time_series ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc .rechunked "-C -v lon,lat,time,$var")
    ncks -O --fix_rec_dmn lon ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc  ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_1.nc
    ncap2 -s 'tas=float(tas)' ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_1.nc ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_2.nc
    mv ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_2.nc ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc
    rm ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_1.nc
    ncatted -a _FillValue,tas,o,f,1.e+20 ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc
    ncatted -a missing_value,tas,o,f,1.e+20 ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc
    #TODO: do it for other variables and res!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ncpdq --rdr=lon,lat,time ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA_1.nc
    mv ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA_1.nc  ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc
    $(chunk_time_series ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc .rechunked "-C -v lon,lat,time,$var")
    
    
python ${sd_python_code} --n-processes 256 --randomization-seed 0 -v tas -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi 

if [ "${var}" == "pr" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v precipitation_flux --lower-bound 0 --lower-threshold 0.0000011574 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi 

if [ "${var}" == "rsds" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v surface_downwelling_shortwave_flux_in_air --lower-bound 0 --lower-threshold 0.0001 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi 

if [ "${var}" == "tasrange" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v air_temperature --lower-bound 0 --lower-threshold 0.01 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi

if [ "${var}" == "tasskew" ]
then 

python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v air_temperature --lower-bound 0 --lower-threshold .0001 --upper-bound 1 --upper-threshold .9999 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi

fi



if [ "${downscaling_to}" != "${res1}" ]
then
#if  [ "${downscaling_to}" != "chesla" ]
#then 
if [ "${var}" == "tas" ]
then

    ncpdq --rdr=lon,lat,time ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_1.nc
    mv ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}_1.nc ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc
    
    $(chunk_time_series ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc ./rechunk "-C -v lon,lat,time,$var")

python ${sd_python_code} --n-processes 256 --randomization-seed 0 -v tas -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_from}.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

fi 
if [ "${var}" == "pr" ]
then
python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v precipitation_flux --lower-bound 0 --lower-threshold 0.0000011574 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_from}.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc 

fi 

if [ "${var}" == "rsds" ]
then
python ${sd_python_code} --n-processes 16 --resume-job ${resume} --randomization-seed 0 -v surface_downwelling_shortwave_flux_in_air --lower-bound 0 --lower-threshold 0.0001 -o ${data_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${downscaling_to}.nc -s ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_from}.nc -f ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc 

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

