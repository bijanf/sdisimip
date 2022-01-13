#!bin/bash 
set -e

for var in "tasrange" "tasskew" "rsds" "tas" "pr"
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
                echo "sending the job to slurm !"
                sbatch bias_adjust.sh $var $scenario $model $time_slice 
                
                echo " "
                echo " "
                if [ $var == "tasrange" ] && [ $scenario == "ssp126" ] && [ $model == "gfdl-esm4" ] && [ $time_slice == "historical" ]
		then
		    echo "waiting 240 seconds to send the next job! "
                    echo "-----------------------------------------------------"
                    echo " "
                    echo " "

		    sleep 240
		else
		    echo "waiting 150 seconds to send the next job! "
                    echo "-----------------------------------------------------"
                    echo " "
                    echo " "

    
                    sleep 150
		fi 
            done 
        done
    done
done


          

