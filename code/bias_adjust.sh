#!/bin/bash
#SBATCH --job-name=BASD   
#SBATCH --partition=compute                                                                                                                                                                  
#SBATCH --nodes=1                                                                                                                                                                            
#SBATCH --ntasks-per-node=128                                                                                                                                                                
#SBATCH --exclusive                                                                                                                                                                          
#SBATCH --time=00:30:00                                                                                                                                                                      
#SBATCH --mail-type=FAIL                                                                                                                                                                     
#SBATCH --account=bb1243                                                                                                                                                                     
#SBATCH --output=slogs/my_job.%j.out
#SBATCH --error=slogs/my_job.%j.err

module load cdo 
module load nco
source 0_export.sh
source namelist.txt
set -e
member=4
res="0.5"

##time_slice="historical"
#out_dir="/p/projects/gvca/bijan/Mats/data/out/"
out_dir="./out/"
var=$1
scenario=$2
mod=$3
time_slice=$4
###################################################################
latlon="lat${lat0}_${lat1}_lon${lon0}_${lon1}"
mkdir -p ${out_dir}GCMoutput_coarse
model=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
echo $model
if [ "$model" == "ukesm1-0-ll" ]
then 
    realization="r1i1p1f2"
else
    realization="r1i1p1f1"
fi  
echo "----1"
if [[ "$var" == "tas" ]] || [[ "$var" == "pr" ]] || [[ "$var" == "rsds" ]]
then 
echo "-----2"
ncpdq -O --rdr=lon,lat,time ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}_1.nc
mv ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}_1.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc

$(chunk_time_series ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc .rechunked "-C -v lon,lat,time,$var")

ncpdq -O --rdr=lon,lat,time ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train_1.nc
mv ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train_1.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc
$(chunk_time_series  ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc .rechunked "-C -v lon,lat,time,$var" )


ncpdq -O  --rdr=lon,lat,time ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_1.nc 
mv ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_1.nc  ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc

$(chunk_time_series ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc .rechunked "-C -v lon,lat,time,$var")

fi 




if [ "$var" == "pr" ] 
then 


python ../isimip3basd/code/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v pr --lower-bound 0 --lower-threshold 0.0000011574 --distribution gamma -t mixed -w 0 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi 

if [ "$var" == "tas" ] 
then 
python ../isimip3basd/code/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v tas --distribution normal -t additive -d 1 -w 0 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi 

if [ "$var" == "rsds" ] 
then 
python ../isimip3basd/code/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v rsds --lower-bound 0 --lower-threshold 0.0001 --upper-bound 1 --upper-threshold 0.9999 -t bounded -w 15 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi 

# shall I do the tasmin tasrange for test?
# turn on when doing the real stuff, it is just for the test!!!!!!!!!!!!!!!!!!!!!!!!!
tasmintasrange=False

if [ $tasmintasrange == "True" ]
then
    
########################################
### Implement the tasrange & tasskew:### 
########################################

# Create the tasrange and tasskew:
# Also for finer grids for the statistical downscaling: 
# Using the res option
# tasrange = tasmax − tasmin and tasskew = (tas − tasmin)/(tasmax − tasmin)
# ------------------ obs -------------------: 
# tasrang: 
#if [ $var == "tasrange" ] && [ $scenario == "ssp126" ] && [ $model == "gfdl-esm4" ] && [ $time_slice == "historical" ]

if [ "$var" == "tas" ] && [ "$scenario" == "ssp126" ] && [ "$model" == "canesm5" ] && [ "$time_slice" == "historical" ]
then 

echo "------------doing the tasrange and tasskew making of obs-----------"

for resel in ${res0} ${res1} ${res2} ${res3} ${res4} ${res5}
do 

if [ "$var" == "tasrange" ] 
then 

cdo -O sub ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasmax_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${resel}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasmin_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${resel}.nc  ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasrange_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${resel}.nc
fi 

# tasskew 
#if [ $var == "tasskew" ] 
#then 
echo ""
echo "reselution is "$resel
echo "----------------------------------------------"
echo ""


if [ ! -f tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc ]; then

cdo -O sub ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tas_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${resel}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasmin_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${resel}.nc tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc 
else 
echo "error, the tas_interim exists!"
exit 1
fi 

cdo -O div tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasrange_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${resel}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_tasskew_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${resel}.nc

rm -f tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc
##fi 
done


fi 

fi #########tasmintasrange=False


# ----------------- models -------------------
# train: 
if [ "$var" == "tasrange" ] 
then 
cdo -O -chname,tasmax,tasrange -sub ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmax_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmin_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_train.nc 
fi 
if [ "$var" == "tasskew" ] 
then 

if [ ! -f tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc ]; then
cdo -O sub ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tas_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmin_global_daily_cut_mergetime_member${member}_train.nc tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc
else 
echo "error, the tas_interim exists!"
exit 1
fi 

cdo -O -chanme,tas,tasskew -div tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasskew_global_daily_cut_mergetime_member${member}_train.nc

rm -f tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc 
fi 

# time_slice:
if [ "$var" == "tasrange" ] 
then 
cdo -O -chname,tasmax,tasrange -sub ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmax_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmin_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_${time_slice}.nc 
fi 

if [ "$var" == "tasskew" ] 
then 
if [ ! -f tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc ]; then
cdo -O sub ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tas_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasmin_global_daily_cut_mergetime_member${member}_${time_slice}.nc tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc 
else 
echo "error, the tas_interim exists!"
exit 1
fi 
cdo -O  -chname,tas,tasskew -div tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_tasskew_global_daily_cut_mergetime_member${member}_${time_slice}.nc 

rm -f tas_interim_${resel}_tasskew_${scenario}_${mod}_${time_slice}.nc 
fi 


###############


if [ "$var" == "tasskew" ] || [ $var == "tasrange" ] 
then

ncpdq -O  --rdr=lon,lat,time ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}_1.nc
mv ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}_1.nc ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc

$(chunk_time_series ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc .rechunked "-C -v lon,lat,time,$var")

ncpdq -O  --rdr=lon,lat,time ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train_1.nc
mv ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train_1.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc

$(chunk_time_series {out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc .rechunked "-C -v lon,lat,time,$var")

ncpdq -O  --rdr=lon,lat,time ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_1.nc
mv ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_1.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc
$(chunk_time_series {out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc .rechunked "-C -v lon,lat,time,$var")


fi









# the bias-adjustment of tasrange: 
if [ $var == "tasrange" ] 
then 
python ../isimip3basd/code/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v tasrange --lower-bound 0 --lower-threshold 0.01 --distribution weibull -t mixed -w 0 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi

# the bias-adjustment of tasskew: 
if [ $var == "tasskew" ] 
then 
python ../isimip3basd/code/bias_adjustment.py --n-processes 16 --step-size 1 --randomization-seed 0 -v tasskew --lower-bound 0 --lower-threshold .0001 --upper-bound 1 --upper-threshold 0.9999 -t bounded -w 0 -o ${out_dir}OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime1979_2014_${res}.nc -s ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc -f ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}.nc -b ${out_dir}GCMoutput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BA.nc

fi

echo "---------------------F I N I S H E D-----------------------------------"
