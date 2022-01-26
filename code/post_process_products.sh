#!/bin/bash 
set -ex 

res1=0.21428571428571427
res2=0.1
res3=0.04838709677419355
res4=0.023809523809523808
res5=0.011811023622047244
downscaling_to=$res1
data_dir="/p/projects/gvca/bijan/Mats_02/out/"
member="4"
for var in "tasmin" "tasmax" "rsds" "tas" "pr"
do 
    for scenario in "ssp126" "ssp370" "ssp585"
    do 
        for mod in "GFDL-ESM4"  "IPSL-CM6A-LR"  "MPI-ESM1-2-HR"  "MRI-ESM2-0"  "UKESM1-0-LL"
        do 
            model=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
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
                if [ "$model" == "ukesm1-0-ll" ]
                then 
                    realization="r1i1p1f2"
                else
                    realization="r1i1p1f1"
                fi  

                if [ $var == "tasmin" ]
                then 

                    cdo -O mul ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_tasskew_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_1.nc 

                    cdo -O sub ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_tas_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_1.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_2.nc 

                    cdo -O -chname,tas,tasmin ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_2.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

                    rm ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_2.nc 

                    rm ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_1.nc 

                fi


                if [ $var == "tasmax" ]
                then 

                    cdo -O add ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_tasmin_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_tasrange_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_1.nc  

                    cdo -O -chname,tasmin,tasmax ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_1.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc

                    rm ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_1.nc

                fi 

                # cutting the time steps: 

                if [ $time_slice == "historical" ]
                then 

                    cdo -O selyear,1960/1989 ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_1960_1989.nc
                fi

                if [ $time_slice == "near_future" ]
                then 
                    cdo -O selyear,2015/2044 ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_2015_2044.nc
                fi

                if [ $time_slice == "middle_future" ]
                then 
                    cdo -O selyear,2045/2069 ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_2045_2069.nc
                fi

                if [ $time_slice == "far_future" ]
                then 
                    cdo -O selyear,2070/2099 ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}.nc ${data_dir}GCMoutput_fine/${model}_${realization}_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${time_slice}_BASD_${member}_${downscaling_to}_2070_2099.nc
                fi
            done
        done
    done

done







