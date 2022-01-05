#!/bin/bash 
#SBATCH --qos=priority
#SBATCH --partition=priority
#SBATCH --job-name=ba_1km
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=16
#SBATCH --output=../data/%j.out 
#SBATCH --account=gvca
##var="pr"
##scenario="ssp585"
##model="gfdl-esm4"
member=3
res="0.5"
lat0=44.5 # south lat
lat1=46.5 # north lat 
lon0=5. # west lon
lon1=7. # east lon
##time_slice="historical"
out_dir="/p/projects/gvca/bijan/Mats/data/out/"
var=$1
scenario=$2
mod=$3
time_slice=$4
###################################################################
latlon="lat${lat0}_${lat1}_lon${lon0}_${lon1}"
mkdir -p ${out_dir}GCMoutput_coarse
model=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
if [ "$model" == "ukesm1-0-ll" ]
then 
    realization="r1i1p1f2"
else
    realization="r1i1p1f1"
fi  

if [ $var == "pr" ] 
then 
python ../isimip3basd/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v precipitation_flux --lower-bound 0 --lower-threshold 0.0000011574 --distribution gamma -t mixed -w 0 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi 

if [ $var == "tas" ] 
then 
python ../isimip3basd/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v air_temperature --distribution normal -t additive -d 1 -w 0 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi 

if [ $var == "rsds" ] 
then 
python ../isimip3basd/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v surface_downwelling_shortwave_flux_in_air --lower-bound 0 --lower-threshold 0.0001 --upper-bound 1 --upper-threshold 0.9999 --distribution beta -t bounded -w 15 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi 


########################################
### Implement the tasrange & tasskew:### 
########################################

# 1- Create the tasrange and tasskew:
# tasrange = tasmax − tasmin and tasskew = (tas − tasmin)/(tasmax − tasmin)
# tasrange:
# obs: 
if [ $var == "tasrange" ] 
then 
cdo -O sub ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasmax_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasmin_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc  ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasrange_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc
fi 
if [ $var == "tasskew" ] 
then 

if [ ! -f tas_interim.nc ]; then
cdo -O sub ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tas_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasmin_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc tas_interim.nc 
else 
echo "error, the tas_interim exists!"
exit 1
fi 

cdo -O div tas_interim.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasrange_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasskew_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc

rm -f tas_interim.nc
fi 

# train: 
if [ $var == "tasrange" ] 
then 
cdo -O sub ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmax_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmax_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_train.nc 
fi 
if [ $var == "tasskew" ] 
then 

if [ ! -f tas_interim.nc ]; then
cdo -O sub ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tas_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmax_global_daily_cut_mergetime_member${member}_train.nc tas_interim.nc
else 
echo "error, the tas_interim exists!"
exit 1
fi 

cdo -O div tas_interim.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasskew_global_daily_cut_mergetime_member${member}_train.nc

rm -f tas_interim.nc 
fi 

# time_slice:
if [ $var == "tasrange" ] 
then 
cdo -O sub ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmax_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmin_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_${time_slice}.nc 
fi 

if [ $var == "tasskew" ] 
then 
if [ ! -f tas_interim.nc ]; then
cdo -O sub ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmax_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmin_global_daily_cut_mergetime_member${member}_${time_slice}.nc tas_interim.nc 
else 
echo "error, the tas_interim exists!"
exit 1
fi 
cdo -O div tas_interim.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasskew_global_daily_cut_mergetime_member${member}_${time_slice}.nc 

rm -f tas_interim.nc 
fi 
###############


# the bias-adjustment of tasrange: 
if [ $var == "tasrange" ] 
then 
python ../isimip3basd/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v air_temperature --lower-bound 0 --lower-threshold 0.01 --distribution weibull -t mixed -w 0 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi
# the bias-adjustment of tasskew: 
if [ $var == "tasskew" ] 
then 
python ../isimip3basd/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v air_temperature --lower-bound 0 --lower-threshold .0001 --upper-bound 1 --upper-threshold 0.9999 -t bounded -w 0 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi

