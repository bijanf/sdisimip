#!/bin/bash 
set -ex



dir_data="/p/projects/gvca/bijan/Zarafshan/"

out_data=${dir_data}merged/
mkdir -p ${out_data}
res="0.04838709677419355"
#for var in pr rsds tas tasmax tasmin
for var in tasmin tasmax rsds tas pr
do 

    for scenario in ssp126 ssp370 ssp585
    do 

        for mod in GFDL-ESM4  IPSL-CM6A-LR  MPI-ESM1-2-HR  MRI-ESM2-0  UKESM1-0-LL
        do 
	    model=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
	    if [ "$model" == "ukesm1-0-ll" ]
            then
                realization="r1i1p1f2"
            else  
                realization="r1i1p1f1"  
            fi  

            
            for time_slice in "historical" "near_future" "middle_future" "far_future" 
            do 
                echo "    time_slice is--------- "$time_slice
                echo 
                echo "    model is-------------- "$mod
                echo 
                echo "    scenario is----------- "$scenario
                echo 
                echo "    variable is----------- "$var 
                echo 
                echo "sending the job to slurm !"
                
		
		
		if [ $time_slice == "historical" ]
                then
		    time_slice_name="1960_1989"
		fi     

	        if [ $time_slice == "near_future" ]
                then
                    time_slice_name="2015_2044"
                fi

                if [ $time_slice == "middle_future" ]
                then
                    time_slice_name="2045_2069"
                fi

                if [ $time_slice == "far_future" ]
                then
                    time_slice_name="2070_2099"
                fi


		for dom in {1..3}
		do 
                    
                   cdo -O remapbil,zerafshan_grids_final ${dir_data}out_domain_0${dom}/GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member4_${time_slice}_BASD_4_${res}_${time_slice_name}.nc    ${out_data}${dom}.nc 


                done
                cdo -O mergegrid ${out_data}1.nc ${out_data}2.nc ${out_data}4.nc
		cdo -O mergegrid ${out_data}3.nc ${out_data}4.nc ${out_data}5.nc
###             ${out_data}${mod}_${realization}_${scenario}_${var}_${time_slice_name}_inter.nc 

		if [ ${var} == "pr" ]
		then 
		    cdo -O mulc,86400 ${out_data}5.nc ${out_data}${mod}_${realization}_${scenario}_${var}_${time_slice_name}.nc
		fi 
		if [ ${var} == "tas" ]
		then
                    cdo -O subc,273.15 ${out_data}5.nc ${out_data}${mod}_${realization}_${scenario}_${var}_${time_slice_name}.nc
		fi
		if [ ${var} == "tasmin" ]
		then
                    cdo -O subc,273.15  ${out_data}5.nc ${out_data}${mod}_${realization}_${scenario}_${var}_${time_slice_name}.nc
		fi
		if [ ${var} == "tasmax" ]
		then
                    cdo -O subc,273.15 ${out_data}5.nc ${out_data}${mod}_${realization}_${scenario}_${var}_${time_slice_name}.nc
		fi
		if [ ${var} == "rsds" ]
                then
                    cdo -O mulc,8.64 ${out_data}5.nc ${out_data}${mod}_${realization}_${scenario}_${var}_${time_slice_name}.nc
                fi
    
		rm ${out_data}1.nc ${out_data}2.nc ${out_data}3.nc ${out_data}4.nc ${out_data}5.nc
		
                echo "-----------------------------------------------------"
                echo " "
                echo " "
                
            done 
        done
    done
done

