#!/bin/bash 
##SBATCH --qos=short
##SBATCH --qos=priority
##SBATCH --partition=standard
##SBATCH --partition=priority
##SBATCH --account=gvca
##SBATCH --ntasks=1
##SBATCH --cpus-per-task=4
##SBATCH --job-name=gvcabasd
##SBATCH --output=slogs/out.%j
##SBATCH --error=slogs/out.%j

#SBATCH --job-name=BASD
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --exclusive
#SBATCH --time=03:30:00
#SBATCH --mail-type=FAIL
#SBATCH --account=bb1243
#SBATCH --output=slogs/my_job.%j.out


module load nco

set -e
source namelist.txt
latlon="lat${lat0}_${lat1}_lon${lon0}_${lon1}"
####################################################
# create the out_dir if not exist:
mkdir -p ${out_dir}
#####################################################
for var in "${variables[@]}" #loop over variables:
do
    ############ Prepare the coarse OBS ###########################################
    ##### 0.5
    ## create the folder : 
    mkdir -p ${out_dir}OBSinput_coarse
    #####################
    # create the grid information for remapping from a model  
    cdo -O griddes data/merged/canesm5_r1i1p1f1_w5e5_ssp585_tas_global_daily_${latlon}_cut_mergetime.nc > grid_0
#    #cdo -O griddes ${out_dir}GCMinput_coarse/gfdl-esm4_r1i1p1f1_w5e5_ssp585_${var}_global_daily_cut_mergetime_member${member}_near_future.nc > grid_0


    sed -i 's/inc      = -0.5/inc      = 0.5 /g' grid_0
    sed -i 's/inc      = 0.5/inc      = 0.5 /g' grid_0
    sed -i "s%${lat1}%${lat0}%g" grid_0
    sed -i "s/size     = 94/size     = 94 /g" grid_0
    sed -i "s/size     = 47/size     = 47 /g" grid_0
    sed -i 's/gridsize  = 4418/gridsize  = 4418 /g' grid_0
    
    ######## start remapping:
#    cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime${year1obs}_${year2obs}_${res0}.nc
    ##
    #### 0.25
    sed -i 's/= 0.5 /= 0.25 /g' grid_0
    sed -i "s/= 94 /= 188 /g" grid_0
    sed -i "s/= 47 /= 94 /g" grid_0
    sed -i 's/= 4418 /= 17672 /g' grid_0
    sed -i "s/yfirst    = 33.25/yfirst    = 33.125 /g" grid_0
    sed -i "s/xfirst    = 44.25/xfirst    = 44.125 /g" grid_0
    ##


#    echo generating remap weights for aggregation_factor $aggregation_factor ...
#    cdo gencon,grid_0  remap_weights.nc 
    cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime${year1obs}_${year2obs}_${res1}.nc
    break
#    ##
#    ##### 0.125
#    sed -i 's/= 0.21428571428571427 /= 0.1 /g' grid_0
#    sed -i "s/= 40 /= 80 /g" grid_0
#    sed -i 's/= 1600 /= 6400 /g' grid_0
#    cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_${res_obs}arcsec_global_daily__${latlon}_cut_mergetime${year1obs}_${year2obs}_${res2}.nc
    #
#    ##### 0.0625
#    sed -i 's/= 0.1 /= 0.04838709677419355 /g' grid_0
#    sed -i "s/= 16 /= 32 /g" grid_0
#    sed -i 's/= 256 /= 1024 /g' grid_0
#    cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime${year1obs}_${year2obs}_${res3}.nc
    #
#    #### 0.03125
#    sed -i 's/= 0.04838709677419355 /= 0.023809523809523808 /g' grid_0
#    sed -i "s/= 32 /= 64 /g" grid_0
#    sed -i 's/= 1024 /= 4096 /g' grid_0
#    cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime${year1obs}_${year2obs}_${res4}.nc
 #   #
 #   ##### semi final  
 #   ##### 0.03125
 #   sed -i 's/= 0.023809523809523808 /= 0.011811023622047244 /g' grid_0
 #   sed -i "s/= 64 /= 128 /g" grid_0
 #   sed -i 's/= 4096 /= 16384 /g' grid_0
 #   cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-#w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime${year1obs}_${year2obs}_${res5}.nc


    for model in "${models[@]}"
    do 
    
        for scenario in "${scenarios_future[@]}"
        do 
            mod_lower=$(echo "$model" | tr '[:upper:]' '[:lower:]')
            if [ "$mod_lower" == "ukesm1-0-ll" ]
            then 
                realization="r1i1p1f2"
            else
                realization="r1i1p1f1"
            fi  
            model=$(echo $mod_lower)
            echo "Variable "${var}" is being processed for model "${model}", scenario is "${scenario}" and the realization is "${realization}
            # file training 1979-2014 

            file_train=${data_dir}${model}_${realization}_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_1979_2014.nc

            # historical 1958-1993 to avoid over fitting!
	    file_historical=${data_dir}${model}_${realization}_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_1958_1993.nc
            #file_historical=${data_dir}${model}_${realization}_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_1985_2020.nc

            # near future 2015-2050 keeping 2015-2043
            file_near_future=${data_dir}${model}_${realization}_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_2015_2050.nc

            # middle fiture 2040-2075 keeping 2044-2072
            file_middle_future=${data_dir}${model}_${realization}_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_2040_2075.nc

            # far future 2065-2100 keeping 2073-2100
            file_far_future=${data_dir}${model}_${realization}_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_2065_2100.nc


            cdo -O -mergetime ${data_dir}${model}_${realization}_w5e5_historical_${var}_global_daily_${latlon}_cut_mergetime.nc ${data_dir}${model}_${realization}_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime.nc f.nc
            # selyears: 
            # according to the ISIMIP3B fact sheet
            # just the historical period is slightly different

            cdo -selyear,1979/2014 f.nc ${file_train}
            ## cdo -selyear,1985/2020 f.nc ${file_historical}
	    #  to avoid overfitting we select the historical period out of the training period: 
	    cdo -selyear,1958/1993 f.nc ${file_historical}
            cdo -selyear,2015/2050 f.nc ${file_near_future}
            cdo -selyear,2040/2075 f.nc ${file_middle_future}
            cdo -selyear,2065/2100 f.nc ${file_far_future}

            echo 'delete intermediate file'
            rm f.nc
            # create the folder 
            mkdir -p ${out_dir}GCMinput_coarse

            # cut the domain:
            ## train:
            ncks -O -d lat,${lat0},${lat1} -d lon,${lon0},${lon1} ${file_train} ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_train.nc
            ## historical: 
            ncks -O -d lat,${lat0},${lat1} -d lon,${lon0},${lon1} ${file_historical} ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_historical.nc
            ## near future:
            ncks -O -d lat,${lat0},${lat1} -d lon,${lon0},${lon1} ${file_near_future} ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_near_future.nc
            ## middle future:
            ncks -O -d lat,${lat0},${lat1} -d lon,${lon0},${lon1} ${file_middle_future} ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_middle_future.nc
            ## near future:
            ncks -O -d lat,${lat0},${lat1} -d lon,${lon0},${lon1} ${file_far_future} ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_far_future.nc

            # create the grid information for remapping 
            
            cdo -O griddes data/merged/canesm5_r1i1p1f1_w5e5_ssp585_tas_global_daily_${latlon}_cut_mergetime.nc > grid_0

            #cdo -O griddes ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_near_future.nc > grid_0


            sed -i 's/-0.5/0.5/g' grid_0
            sed -i "s%${lat1}%${lat0}%g" grid_0

            ### remapping and correcting the grides
            for mmm in train historical near_future middle_future far_future
            do 

                cdo -O  remapcon,grid_0 ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${mmm}.nc ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${mmm}_f.nc
                rm ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${mmm}.nc 
                mv ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${mmm}_f.nc  ${out_dir}GCMinput_coarse/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${mmm}.nc


            done   # for time-slices 
        done       # for scenario     
    done           # for model
done               # for variable


echo "---------------------------F I N I S H E D ---------------------"
