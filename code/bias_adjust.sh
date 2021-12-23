#!/bin/bash 
#SBATCH --qos=priority
#SBATCH --partition=priority
#SBATCH --job-name=ba_1km
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=8
#SBATCH --output=../data/%j.out 
#SBATCH --account=gvca
var="pr"
scenario="ssp585"
model="gfdl-esm4"
latlon="lat38._40._lon68._70."
mkdir -p ../data/GCMinput_coarse
mkdir -p ../data/GCMoutput_coarse

echo "run the python"
if [ $var == "pr"] 
then 

python ../isimip3basd/bias_adjustment.py --n-processes 8 --step-size 1 --randomization-seed 0 -v precipitation_flux --lower-bound 0 --lower-threshold 0.0000011574 --distribution gamma -t mixed -w 0 -o ../data/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_1979_2014_0.5.nc -s ../data/GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member3_1979_2014.nc -f ../data/GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member3_2015_2050.nc -b ../data/GCMoutput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member3_2015_2050_BA.nc
fi 

# for the historical: 

#python ../isimip3basd/bias_adjustment.py --n-processes 8 --step-size 1 --randomization-seed 0 -v air_temperature --distribution normal -t additive -d 1 -w 0 -o ../data/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_coarse_1979_2014.nc -s ../data/GCMinput_coarse/${model}_r1i1p1f1_w5e5_historical_${var}_global_daily_${latlon}_cut_mergetime_1979_2014.nc -f ../data/GCMinput_coarse/${model}_r1i1p1f1_w5e5_historical_and_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_1994_2029.nc -b ../data/GCMoutput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_1994_2029_BA.nc
