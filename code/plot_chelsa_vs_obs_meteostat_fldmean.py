#!/bin/python3.8

# plot the chelsa vs obs from meteostat
from meteostat import Stations
stations = Stations()
# France
lon_c=6.0
lat_c=45.5
stations = stations.nearby(lat_c,lon_c)
stations = stations.inventory('daily')
station = stations.fetch(6)
print(station)
# Import Meteostat library and dependencies
from datetime import datetime
import matplotlib.pyplot as plt
from meteostat import Point, Daily
import os
#!pip3 install netCDF4
from netCDF4 import Dataset
import numpy as np
import pandas as pd
def running_mean(a, n=5):
    return pd.Series(a).rolling(n, min_periods=2).mean().values

fig = plt.figure(figsize=(20,15))
gs = fig.add_gridspec(4, 1, hspace=0, wspace=0)
#gs = fig.add_gridspec(1, 2, hspace=0, wspace=0)

ax = gs.subplots(sharex='col', sharey='row')
fig.suptitle('31-day window running mean TAVG \n Obs.(meteostat) vs. ISIMIP3b \n', fontsize=30)
#fig.suptitle('TAVG for 2015 \n Obs.(meteostat) vs. CHELSA \n', fontsize=30)
print(ax.shape)
# Set time period
start = datetime(2008, 1, 1)
end = datetime(2016, 12, 31)
#start = datetime(2015, 1, 1)
#end = datetime(2015, 12, 31)
file_dir="/p/projects/gvca/bijan/Mats/data/merged/chelsa-w5e5v1.0_obsclim_tas_30arcsec_global_daily__lat44.5_46.5_lon5._7._cut_mergetime.nc"
model="gfdl-esm4"
realization="r1i1p1f1"
file_gcm_dir="/p/projects/gvca/bijan/Mats/data/out/GCMoutput_fine/"
file_gcm_original_dir="/p/projects/gvca/bijan/Mats/data/out/GCMinput_coarse/"
scenario="ssp585"
variable="tas"
time_slice="historical"
#res="0.21428571428571427"
res="0.1"
N=31
gcm=model+"_"+realization+"_w5e5_"+scenario+"_"+variable+"_global_daily_cut_mergetime_member3_"+time_slice+"_BASD_3_"+res+".nc"
gcm_near_future=model+"_"+realization+"_w5e5_"+scenario+"_"+variable+"_global_daily_cut_mergetime_member3_"+"near_future"+"_BASD_3_"+res+".nc"
gcm_middle_future=model+"_"+realization+"_w5e5_"+scenario+"_"+variable+"_global_daily_cut_mergetime_member3_"+"middle_future"+"_BASD_3_"+res+".nc"
gcm_far_future=model+"_"+realization+"_w5e5_"+scenario+"_"+variable+"_global_daily_cut_mergetime_member3_"+"far_future"+"_BASD_3_"+res+".nc"


gcm_original=model+"_"+realization+"_w5e5_"+scenario+"_"+variable+"_global_daily_cut_mergetime_member3_"+time_slice+".nc"
gcm_original_near_future=model+"_"+realization+"_w5e5_"+scenario+"_"+variable+"_global_daily_cut_mergetime_member3_"+"near_future"+".nc"
gcm_original_middle_future=model+"_"+realization+"_w5e5_"+scenario+"_"+variable+"_global_daily_cut_mergetime_member3_"+"middle_future"+".nc"
gcm_original_far_future=model+"_"+realization+"_w5e5_"+scenario+"_"+variable+"_global_daily_cut_mergetime_member3_"+"far_future"+".nc"

k = 0
for i in range(5):
    if station['name'][k] == "Bourg-St-Maurice":
        continue
    for j in range(1):

        #if k==7:
        #    break
        #    break
        #if k==4:
        #    k+=1
#        if k>10:
#            continue
            
        longi = station['longitude'][k]
        lati = station['latitude'][k]
        print(longi, lati)
 
        # chelsa
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" "+file_dir+" file.nc"
        #cmd = "cdo -O fldmean "+file_dir+" file.nc"

        #cmd = "cdo -O fldmean "+" -selyear,1979/2016 "+file_dir+" file.nc"
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(1979,2017,len(tas))
        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='r', label="CHELSA")

        # gcm original historical
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" "+file_gcm_original_dir+gcm_original+" file.nc"
        #cmd = "cdo -O fldmean -selyear,1985/2020 " +file_gcm_original_dir+gcm_original+" file.nc"
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(1985,2021,len(tas))

        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='g',label="ISIMIP3b-no-basd")

        # gcm original near_future
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" -selyear,2015/2043 "+file_gcm_original_dir+gcm_original_near_future+" file.nc"
        #cmd = "cdo -O fldmean -selyear,2015/2043 "+file_gcm_original_dir+gcm_original_near_future+" file.nc"
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(2015,2044,len(tas))
#
        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='g')

        # gcm original middle_future
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" -selyear,2044/2072 "+file_gcm_original_dir+gcm_original_middle_future+" file.nc"
        #cmd = "cdo -O fldmean -selyear,2015/2043 "+file_gcm_original_dir+gcm_original_near_future+" file.nc"
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(2044,2073,len(tas))
#
        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='g')

        # gcm original far_future
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" -selyear,2073/2100 "+file_gcm_original_dir+gcm_original_far_future+" file.nc"
        #cmd = "cdo -O fldmean -selyear,2015/2043 "+file_gcm_original_dir+gcm_original_near_future+" file.nc"
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(2073,2101,len(tas))
        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='g')


        # gcm downscaled historical
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" -selyear,1985/2020 "+file_gcm_dir+gcm+" file.nc"
        #cmd = "cdo -O fldmean -selyear,1985/2020 "+file_gcm_dir+gcm+" file.nc"

        
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(1985,2021,len(tas))

        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='b', label="ISIMIP3b-with-basd")
        ax[i].set_title(station['name'][k])


        ## gcm downscaled near_future:
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" -selyear,2015/2043 "+file_gcm_dir+gcm_near_future+" file.nc"
        #cmd = "cdo -O fldmean -selyear,2015/2043 "+file_gcm_dir+gcm_near_future+" file.nc"
        #
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(2015,2044,len(tas))
#
        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='b')
        ax[i].set_title(station['name'][k])


        ## gcm downscaled middle_future:
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" -selyear,2044/2072 "+file_gcm_dir+gcm_middle_future+" file.nc"
        #cmd = "cdo -O fldmean -selyear,2015/2043 "+file_gcm_dir+gcm_near_future+" file.nc"
        #
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(2044,2073,len(tas))
#
        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='b')
        ax[i].set_title(station['name'][k])

       ## gcm downscaled far_future:
        cmd = "cdo -O -remapnn,lon="+str(longi)+"_lat="+str(lati)+" -selyear,2073/2100 "+file_gcm_dir+gcm_far_future+" file.nc"
        #cmd = "cdo -O fldmean -selyear,2015/2043 "+file_gcm_dir+gcm_near_future+" file.nc"
        #
        print(cmd)
        os.system(cmd)
        fh = Dataset("file.nc", mode='r')
        tas = fh.variables['tas'][:]-273.15
        time=np.linspace(2073,2101,len(tas))
#
        fh.close()
        ax[i].plot(time,running_mean(tas.squeeze(),N), alpha=.4,color='b')
        ax[i].set_title(station['name'][k])
        k +=1
        ax[i].set_ylim([-5,35])


ax[i-1].legend()



fig.text(0.5, 0.09, 'day', ha='center', fontsize=20)
fig.text(0.09, 0.5, 'tas', va='center', rotation='vertical', fontsize=20)
#plt.savefig('Berlin_obs.pdf', dpi=300,bbox_inches='tight')
#plt.savefig('Madrid_obs.pdf', dpi=300,bbox_inches='tight')
#plt.savefig('CA_obs.pdf', dpi=300,bbox_inches='tight')



plt.savefig('France_obs.pdf', dpi=300,bbox_inches='tight')