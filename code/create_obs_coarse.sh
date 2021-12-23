#!/bin/bash 
set -ex
var='tas'
scenario="ssp585"
model="gfdl-esm4"
year1=2015
year2=2050
year1obs=1979
year2obs=2014
member=3
lat1=38.25
lat2=39.75
lon1=68.25
lon2=69.75
latlon="lat38._40._lon68._70."
data_dir="/p/projects/gvca/bijan/1km_out_new/merged/"
out_dir="/home/fallah/scripts/CHELSA/isimip_2_chelsa/data/"
res0=0.5
res1=0.21428571428571427
res2=0.1
res3=0.04838709677419355
res4=0.023809523809523808
res5=0.011811023622047244
####################################################
# create the out_dir if not exist:
mkdir -p ${out_dir}

#####################################################
file=${data_dir}${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime_1979_2050.nc
cdo -O -mergetime ${data_dir}${model}_r1i1p1f1_w5e5_historical_${var}_global_daily_${latlon}_cut_mergetime.nc ${data_dir}${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_${latlon}_cut_mergetime.nc ${file}_f.nc
cdo -selyear,1979/2050 ${file}_f.nc ${file}
echo 'delete intermediate file'
rm ${file}_f.nc
# create the folder 
mkdir -p ${out_dir}GCMinput_coarse
ncks -O -d lat,${lat1},${lat2} -d lon,${lon1},${lon2} ${file} ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}.nc
#future
cdo -O selyear,${year1}/${year2} ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}.nc ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1}_${year2}.nc
#historical
cdo -O selyear,${year1obs}/${year2obs} ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}.nc ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1obs}_${year2obs}.nc
#
#
#
## correct the lat reversed with respect to chelsa : 

cdo -O griddes ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1}_${year2}.nc > grid_0
sed -i 's/-0.5/0.5/g' grid_0
sed -i "s%${lat2}%${lat1}%g" grid_0
#future
cdo -O  remapcon,grid_0 ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1}_${year2}.nc ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1}_${year2}_f.nc
# historical
cdo -O  remapcon,grid_0 ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1obs}_${year2obs}.nc ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1obs}_${year2obs}_f.nc

#
#
rm ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1}_${year2}.nc 
rm ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1obs}_${year2obs}.nc 
#
# future
mv ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1}_${year2}_f.nc ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1}_${year2}.nc
#
##historical
mv ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1obs}_${year2obs}_f.nc ${out_dir}GCMinput_coarse/${model}_r1i1p1f1_w5e5_${scenario}_${var}_global_daily_cut_mergetime_member${member}_${year1obs}_${year2obs}.nc
#
#
#
########### Prepare the coarse OBS ###########################################
#### 0.5
# create the folder : 
mkdir -p ${out_dir}OBSinput_coarse
####################
cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_${year1obs}_${year2obs}_${res0}.nc
#
### 0.25
sed -i 's/= 0.5/= 0.21428571428571427/g' grid_0
sed -i "s/= 4/= 8/g" grid_0
sed -i 's/= 16/= 64/g' grid_0
#
cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_${year1obs}_${year2obs}_${res1}.nc
#
#### 0.125
sed -i 's/= 0.21428571428571427/= 0.1/g' grid_0
sed -i "s/= 8/= 16/g" grid_0
sed -i 's/= 64/= 256/g' grid_0
cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_${year1obs}_${year2obs}_${res2}.nc

#### 0.0625
sed -i 's/= 0.1/= 0.04838709677419355/g' grid_0
sed -i "s/= 16/= 32/g" grid_0
sed -i 's/= 256/= 1024/g' grid_0
cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_${year1obs}_${year2obs}_${res3}.nc

#### 0.03125
sed -i 's/= 0.04838709677419355/= 0.023809523809523808/g' grid_0
sed -i "s/= 32/= 64/g" grid_0
sed -i 's/= 1024/= 4096/g' grid_0
cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_${year1obs}_${year2obs}_${res4}.nc

#### semi final  
#### 0.03125
sed -i 's/= 0.023809523809523808/= 0.011811023622047244/g' grid_0
sed -i "s/= 64/= 128/g" grid_0
sed -i 's/= 4096/= 16384/g' grid_0
cdo -O  selyear,${year1obs}/${year2obs}  -remapcon,grid_0 ${data_dir}chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc  ${out_dir}/OBSinput_coarse/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime_${year1obs}_${year2obs}_${res5}.nc


#### Final 
##lat1="$lat1+0.25"|bc
#lat1=($(python3 -c "print($lat1 + 0.25)"))
#lon1=($(python3 -c "print($lon1 + 0.25)")) 
#num1=0.00833333330001551
#num2=22
#num=($(python3 -c "print($num1*$num2)"))
#lat2=($(python3 -c "print($lat2 - $num)"))
#lon2=($(python3 -c "print($lon2 - $num)")) 
#
#ncks -d lat,${lat1},${lat2} -d lon,${lon1},${lon2} ${data_dir}chelsa-w5e5v1.#0_obsclim_${var}_30arcsec_global_daily__${latlon}_cut_mergetime.nc $#{out_dir}/OBSinput_fine/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__lat39.#_40._lon68._70._cut_mergetime_chesla.nc
#
#cdo selyear,${year1obs}/${year2obs} ${out_dir}/OBSinput_fine/chelsa-w5e5v1.#0_obsclim_${var}_30arcsec_global_daily__lat39._40._lon68._70._cut_mergetime_chesla.nc #${out_dir}/OBSinput_fine/chelsa-w5e5v1.0_obsclim_${var}_30arcsec_global_daily__lat39.#_40._lon68._70._cut_mergetime_${year1obs}_${year2obs}_chesla.nc
#
#rm ${out_dir}/OBSinput_fine/chelsa-w5e5v1.#0_obsclim_${var}_30arcsec_global_daily__lat39._40._lon68._70._cut_mergetime_chesla.nc



##################################################################################