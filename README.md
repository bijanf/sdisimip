# isimip3b_2_chelsa

-  This is a project to downscaling the ISIMIP3b using the CHELSA data for a selected region. 
-  The anaconda enviornmet's installed libraries are mentiond in the code/enviornment.yml. The other user can run : 
```bash 
conda env create -f environment.yml
```
and the environment will get installed in their default conda environment path.



The workflow right now is as following: 

1- change the namelist accordingly.

2- run the cut_and_prepare.sh script to cut the CHELSA and ISIMIP3b for region of interest. 

3- run the create_obs_coarse.sh to prepare the lower resolution obs for step by step downscaling and for bias adjusting the ISIMIP3b against the CHELSA at 0.5 degree resolution prior to downscaling. 

3- run the run_bias_adjust.sh to send bias adjusting parallel jobs for different variables, scenarios, models and time-slices. Remember to change the SBATCH commands according to your own user info. 

4- edit the downscaling step (1,2,3,4,5) in the sd.sh and run the run_sd.sh to send jobs to  slurm for different variables, scenarios,	models and time-slices. Remember to change the SBATCH commands according to your own user info.

5- run_post_process_products.sh to cut final time-slices and convert tasrange, tasskew and tas to tasmin and tasmax. 


## Example of a run: 

<object data="http://www.pik-potsdam.de/~fallah/presentations/CHELSA/bijan_fallah_20220118.pdf"  type="application/pdf" width="700px" height="700px">
    <embed src="http://www.pik-potsdam.de/~fallah/presentations/CHELSA/bijan_fallah_20220118.pdf">
        <p> Download the PDF to view it: <a href="http://www.pik-potsdam.de/~fallah/presentations/CHELSA/bijan_fallah_20220118.pdf">Download PDF</a>.</p>
    </embed>
</object>


## Report maker code

- the code "report_maker_downscalin.py" will produce a report for time average of ensemble mean and ensemble standard deviation, if all the libraries are installed. 

