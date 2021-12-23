#!/bin/bash 
##SBATCH --qos=priority
##SBATCH --partition=priority
##SBATCH --job-name=sd_1km
###SBATCH --ntasks-per-node=1 
##SBATCH --ntasks=1 
##SBATCH --cpus-per-task=1
##SBATCH --mem=60000
##SBATCH --output=%j.out 
##SBATCH --account=gvca
#=============================================
#code to prepare the obs_hist,sim_hist,sim_fut
# and cut the domain for the Target
#=============================================
set -ex
#========= NAMELIST ==========================
lat0=38. # south lat
lat1=40. # north lat 
lon0=68. # west lon
lon1=70. # east lon
header="chelsa-w5e5v1.0_obsclim_"
suffix="_30arcsec_global_daily_"
chelsa_dir="/p/projects/proclias/1km/data/chelsa_w5e5/nc/"
out_dir="/p/projects/gvca/bijan/1km_out_new/"
isimip3b_dir="/p/projects/isimip/isimip/ISIMIP3b/InputData/climate/atmosphere/bias-adjusted/global/daily/"
#isimip3b_dir_2nd="/p/projects/isimip/isimip/ISIMIP3b/SecondaryInputData/climate/atmosphere/bias-adjusted/global/daily/"

# declare the variables:
scenarios=(historical ssp126 ssp370 ssp585)
models=(GFDL-ESM4  IPSL-CM6A-LR  MPI-ESM1-2-HR  MRI-ESM2-0  UKESM1-0-LL)
#models_2nd=(CanESM5  CNRM-CM6-1  CNRM-ESM2-1  EC-Earth3  MIROC6)
#variables=(pr rsds tas tasmax tasmin)
variable="tas"
#========== END NAMELIST ======================

cutoff_do="yes"
mkdir -p ${out_dir}
if [ "${cutoff_do}"  == "yes" ]
then 
# cutoff the region for chelsa
for var in $variable #######"${variables[@]}"
do 
    echo "The variable is "$var
    for year in {1979..2016}
    do 
        echo "The year is "$year
        for mon in {01..12}
        do 
            echo "The month is "$mon
            ncks -O -d lat,${lat0},${lat1} -d lon,${lon0},${lon1} ${chelsa_dir}${header}${var}${suffix}${year}${mon}.nc ${out_dir}${header}${var}${suffix}${year}${mon}_lat${lat0}_${lat1}_lon${lon0}_${lon1}_cut.nc

        done
    done


    for scen in "${scenarios[@]}"
    do 
    for mod in "${models[@]}"
        do  
            if [ "$scen" == "historical" ]
            then 

                for yy in 1971_1980 1981_1990 1991_2000 2001_2010 2011_2014
                do 

                    echo 
                    echo "----------cuttiung the scenarios---------------"
                    echo "scenario is"$scen "and model i "$mod  
                    echo 
                    mod_lower=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
                    if [ "$mod_lower" == "ukesm1-0-ll" ]
                    then 
                       realization="r1i1p1f2"
                    else
                       realization="r1i1p1f1"
                    fi  
                    ncks -O -d lat,${lat0},${lat1} -d lon,${lon0},${lon1} ${isimip3b_dir}${scen}/${mod}/${mod_lower}_${realization}_w5e5_${scen}_${var}_global_daily_${yy}.nc ${out_dir}${mod_lower}_${realization}_w5e5_${scen}_${var}_global_daily_${yy}_lat${lat0}_${lat1}_lon${lon0}_${lon1}_cut.nc 

                done
            else
                for yy in 2015_2020 2021_2030 2031_2040 2041_2050 2051_2060 2061_2070 2071_2080 2081_2090 2091_2100
                do 

                    echo 
                    echo "----------cuttiung the scenarios---------------"
                    echo "scenario is"$scen "and model i "$mod  
                    echo 
                    mod_lower=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
                    if [ "$mod_lower" == "ukesm1-0-ll" ]
                    then 
                        realization="r1i1p1f2"
                    else
                        realization="r1i1p1f1"
                    fi  

                    ncks -O -d lat,${lat0},${lat1} -d lon,${lon0},${lon1} ${isimip3b_dir}${scen}/${mod}/${mod_lower}_${realization}_w5e5_${scen}_${var}_global_daily_${yy}.nc ${out_dir}${mod_lower}_${realization}_w5e5_${scen}_${var}_global_daily_${yy}_lat${lat0}_${lat1}_lon${lon0}_${lon1}_cut.nc 


                
                done


            fi  




        done
    done
done
fi



echo "merging..................."
merging_do="yes"
if [ "${merging_do}"  == "yes" ]
then 
## merge single data to a complete data: 
## observations
for var in $variable ####"${variables[@]}"
do 
#    if [ ! -f ${out_dir}/merged/${header}${var}${suffix}_cutoff_lat${lat0}${lat1}_lon${lon0}_${lon1}mergetime.nc ]
#    then 

        cdo -O -mergetime ${out_dir}${header}${var}${suffix}*_lat${lat0}_${lat1}_lon${lon0}_${lon1}_cut.nc ${out_dir}${header}${var}${suffix}_lat${lat0}_${lat1}_lon${lon0}_${lon1}_cut_mergetime.nc 
#    fi

done 
#
## models

for var in $variable ####"${variables[@]}"
do 
    for scen in "${scenarios[@]}"
    do 
        for mod in "${models[@]}"
        do    
            mod_lower=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
            if [ "$mod_lower" == "ukesm1-0-ll" ]
            then 
                realization="r1i1p1f2"
            else
                realization="r1i1p1f1"
            fi  
#            if [ ! -f ${out_dir}/merged/${mod_lower}_${realization}_w5e5_${scen}_${var}_global_daily_cutoff_lat${lat0}${lat1}_lon${lon0}_${lon1}mergetime.nc ]    
#            then 

                cdo -O -mergetime   ${out_dir}${mod_lower}_${realization}_w5e5_${scen}_${var}_global_daily_*_lat${lat0}_${lat1}_lon${lon0}_${lon1}_cut.nc ${out_dir}${mod_lower}_${realization}_w5e5_${scen}_${var}_global_daily_lat${lat0}_${lat1}_lon${lon0}_${lon1}_cut_mergetime.nc
#            fi

        done
    done



done 
fi

mkdir -p ${out_dir}/merged
mv ${out_dir}/*mergetime.nc ${out_dir}/merged/
rm ${out_dir}/*mergetime.nc
