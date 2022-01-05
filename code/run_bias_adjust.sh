#!bin/bash 
set -e
for var in pr rsds tas tasmax tasmin
do 
    echo "Variable is "$var 
    for scenario in ssp126 ssp370 ssp585
    do 
        echo "scenario is "$scenario
        for mod in GFDL-ESM4  IPSL-CM6A-LR  MPI-ESM1-2-HR  MRI-ESM2-0  UKESM1-0-LL
        do 
            echo "model is "$mod
            model=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
            for time_slice in historical near_future middle_future far_future
            do 
                echo "time_slice is "$time_slice
                echo "sending the job to slurm !"
                sbatch bias_adjust.sh $var $scenario $model $time_slice 
                echo "waiting 3 minutes to send the next job! "
                sleep 180
            done 
        done
    done
done


          

