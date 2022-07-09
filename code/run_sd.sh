#!bin/bash 
set -e
#for var in pr rsds tas tasmax tasmin
#for var in tasrange tasskew rsds tas pr
for var in tas 
do 

    for scenario in ssp126 ssp370 ssp585
    do 

	#        for mod in GFDL-ESM4  IPSL-CM6A-LR  MPI-ESM1-2-HR  MRI-ESM2-0  UKESM1-0-LL
	for mod in CanESM5
        do 
            model=$(echo "$mod" | tr '[:upper:]' '[:lower:]')
            for time_slice in historical near_future middle_future far_future
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
                sbatch sd.sh $var $scenario $model $time_slice 
                echo "waiting 60 seconds to send the next job! "
                echo "-----------------------------------------------------"
                echo " "
                echo " "
                sleep 60
            done 
        done
    done
done


          

