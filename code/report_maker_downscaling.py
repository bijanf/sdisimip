#!/usr/bin/env python3
# Program to create automatic report from downscaling results: 
# It should plot the maps for ensemble std and mean
# The ensmeble members are the 5 ISIMIP3b models
# The maps for all the 5 variables of the CHELSA
# 
#----------------- Import libraries: 
from netCDF4 import Dataset
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import matplotlib.ticker as mticker
import os
import matplotlib as mpl
import cartopy.feature as cfeature
import numpy as np
###os.system("pip3 install fpdf")
from fpdf import FPDF
from matplotlib import rcParams
rcParams['axes.spines.top'] = False
rcParams['axes.spines.right'] = False

# ----------------- own functions & classes--------------------: 
def read_nc(file,dir, var):
    print(dir+file)
    fh = Dataset(dir+file, mode='r')
    #print(fh)
    lon = fh.variables['lon'][:]
    lat = fh.variables['lat'][:]
    varss = fh.variables[var][:]
    fh.close()
    
    return lon,lat,varss



class PDF(FPDF):
    def __init__(self):
        super().__init__()
        self.WIDTH = 210
        self.HEIGHT = 297
        
    def header(self):
        # Custom logo and positioning
        # Create an `assets` folder and put any wide and short image inside
        # Name the image `logo.png`
        #self.image('logo.png', 10, 8, 33)
        self.set_font('Arial', 'B', 11)
        self.cell(self.WIDTH - 80)
        self.cell(0, 1, 'The report on the ISIMIP3b downscaling outputs', 0, 0, 'R')
        self.ln(20)
        
    def footer(self):
        # Page numbers in the footer
        self.set_y(-15)
        self.set_font('Arial', 'I', 8)
        self.set_text_color(128)
        self.cell(0, 10, 'Page ' + str(self.page_no()), 0, 0, 'C')

    def page_body(self, images):
        # Determine how many plots there are per page and set positions
        # and margins accordingly
        if len(images) == 3:
            self.image(images[0], 15, 25, self.WIDTH - 30)
            self.image(images[1], 15, self.WIDTH / 2 + 5, self.WIDTH - 30)
            self.image(images[2], 15, self.WIDTH / 2 + 90, self.WIDTH - 30)
        elif len(images) == 2:
                       
            self.image(images[0], 5, 14, self.HEIGHT*.75 - 30)
            self.image(images[1], 10, self.HEIGHT*.75 -20 , self.HEIGHT*.75 - 30)
        else:
            self.image(images[0], 15, 25, self.WIDTH - 30)
            
    def print_page(self, images):
        # Generates the report
        self.add_page()
        self.page_body(images)




def plot_tasmax(time_slice,scenario,data,prefix,res, member,vmin,
 vmax,N,out, formats, ensoperator, timing):
    '''
    function to plot the ensmean and ensstd of the near surface air temperature

    - input: 
        tim_slice: string, time_slice of the simulations. 
        scenario:  string, scenario of the simulations. 
        data:      string, the directory of the data. 
        prefix:    string, prefix of the data name.
        res:       string, the resolution of the output data. 
        member:    string, the experiment number. 
        vmin:      float,  minimum value for the pcolor.
        vmax:      float,  maximum value for the pcolor.
        N:         integer, number of colors.    
        out:       string the directory where the plots have to be stored. 
        formats:    string, the format of the plots, e.g. pdf, png, etc.
        ensoperator: string, the operator for ensemble : ensmean or ensstd.
        timing:    string, time-slice of the simulation. 

    - output: 
        Plots. 
    '''

    if res == "0.5":
        data += "/GCMinput_coarse/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+".nc"
    else:
        data += "/GCMoutput_fine/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+"_BASD_"+member+"_"+res+timing+".nc"
    
    cmd = "cdo -O -"+ensoperator+" "+data+files+" out_1.nc"
    os.system(cmd)
    cmd = "cdo -O timmean out_1.nc out.nc"
    os.system(cmd)

    cmap = plt.cm.coolwarm # define the colormap
    bounds = np.linspace(vmin, vmax, N)
    lon,lat,vari = read_nc("out.nc","./", "tasmax")
    # make a meshgrid matrix from lon and lat : 
    lons,lats = np.meshgrid(lon,lat)
    # set up a map
    fig = plt.figure()
    ax = plt.axes(projection=ccrs.PlateCarree())
    # extract all colors from the .jet map
    cmaplist = [cmap(i) for i in range(cmap.N)]
    # create the new map
    cmap = mpl.colors.LinearSegmentedColormap.from_list('Custom cmap', cmaplist, cmap.N)
    norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    # plot the data:
    plot_1 = plt.pcolormesh(lons, lats,vari.squeeze() ,transform=ccrs.PlateCarree(),vmin=vmin,vmax=vmax,cmap=cmap, norm=norm,linewidth=0,rasterized=True)
    plot_1.set_edgecolor('face')
    # add coastlines:
    ax.coastlines()
    # add some features:
    
    #coastline = cfeature.COASTLINE
    borders = cfeature.BORDERS
    #ax.add_feature(borders)
    #lakes = cfeature.LAKES
    #rivers = cfeature.RIVERS
    #ax.add_feature(rivers)
    # add grids:
    gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True, linewidth=0.33, color='k',alpha=0.5)
    gl.xlabels_top = False
    gl.ylabels_right = False
    lat0=lat.min() # south lat
    lat1=lat.max() # north lat 
    lon0=lon.min() # west lon
    lon1=lon.max() # east lon

    gl.xlocator = mticker.FixedLocator(np.linspace(lon0,lon1,4))
    gl.ylocator = mticker.FixedLocator(np.linspace(lat0,lat1,4))


    if (time_slice == "near_future") & (res =="0.5") :
        tim = "_2015_2044"
    elif (time_slice == "middle_future") & (res =="0.5") : 
        tim = "_2045_2069"
    elif (time_slice == "far_future") & (res =="0.5") :
        tim = "_2070_2099"
    if (res == "0.5" ):
        plt.title("tasmax "+scenario+" "+tim+" "+res[0:5]+"° "+ensoperator)
    else:
        plt.title("tasmax "+scenario+" "+timing+" "+res[0:5]+"° "+ensoperator)
    
    #plt.colorbar()
    # Save the plot:
    plt.savefig(out+"tasmax_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+'.'+formats,dpi=300,bbox_inches='tight')
    cmd = "rm out_1.nc out.nc"
    os.system(cmd)
    #plt.show()
    plt.close()
    fig = plt.figure()
    cbar_ax = fig.add_axes([0.17, 0.17, 0.60, 0.04])
    cbar = fig.colorbar(plot_1, cax=cbar_ax, orientation="horizontal", extend="both")
    cbar.ax.set_xlabel('Temperature [K]')
    plt.savefig(out+"tasmax_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+"_colorbar.png",dpi=300,bbox_inches='tight')
    plt.close()






def plot_tas(time_slice,scenario,data,prefix,res, member,vmin,
 vmax,N,out, formats, ensoperator, timing):
    '''
    function to plot the ensmean and ensstd of the near surface air temperature

    - input: 
        tim_slice: string, time_slice of the simulations. 
        scenario:  string, scenario of the simulations. 
        data:      string, the directory of the data. 
        prefix:    string, prefix of the data name.
        res:       string, the resolution of the output data. 
        member:    string, the experiment number. 
        vmin:      float,  minimum value for the pcolor.
        vmax:      float,  maximum value for the pcolor.
        N:         integer, number of colors.    
        out:       string the directory where the plots have to be stored. 
        formats:    string, the format of the plots, e.g. pdf, png, etc.
        ensoperator: string, the operator for ensemble : ensmean or ensstd.
        timing:    string, time-slice of the simulation. 

    - output: 
        Plots. 
    '''

    if res == "0.5":
        data += "/GCMinput_coarse/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+".nc"
    else:
        data += "/GCMoutput_fine/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+"_BASD_"+member+"_"+res+timing+".nc"
    
    cmd = "cdo -O -"+ensoperator+" "+data+files+" out_1.nc"
    os.system(cmd)
    cmd = "cdo -O timmean out_1.nc out.nc"
    os.system(cmd)

    cmap = plt.cm.coolwarm # define the colormap
    bounds = np.linspace(vmin, vmax, N)
    lon,lat,vari = read_nc("out.nc","./", "tas")
    # make a meshgrid matrix from lon and lat : 
    lons,lats = np.meshgrid(lon,lat)
    # set up a map
    fig = plt.figure()
    ax = plt.axes(projection=ccrs.PlateCarree())
    # extract all colors from the .jet map
    cmaplist = [cmap(i) for i in range(cmap.N)]
    # create the new map
    cmap = mpl.colors.LinearSegmentedColormap.from_list('Custom cmap', cmaplist, cmap.N)
    norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    # plot the data:
    plot_1 = plt.pcolormesh(lons, lats,vari.squeeze() ,transform=ccrs.PlateCarree(),vmin=vmin,vmax=vmax,cmap=cmap, norm=norm,linewidth=0,rasterized=True)
    plot_1.set_edgecolor('face')
    # add coastlines:
    ax.coastlines()
    # add some features:
    
    #coastline = cfeature.COASTLINE
    borders = cfeature.BORDERS
    #ax.add_feature(borders)
    #lakes = cfeature.LAKES
    #rivers = cfeature.RIVERS
    #ax.add_feature(rivers)
    # add grids:
    gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True, linewidth=0.33, color='k',alpha=0.5)
    gl.xlabels_top = False
    gl.ylabels_right = False
    lat0=lat.min() # south lat
    lat1=lat.max() # north lat 
    lon0=lon.min() # west lon
    lon1=lon.max() # east lon

    gl.xlocator = mticker.FixedLocator(np.linspace(lon0,lon1,4))
    gl.ylocator = mticker.FixedLocator(np.linspace(lat0,lat1,4))


    if (time_slice == "near_future") & (res =="0.5") :
        tim = "_2015_2044"
    elif (time_slice == "middle_future") & (res =="0.5") : 
        tim = "_2045_2069"
    elif (time_slice == "far_future") & (res =="0.5") :
        tim = "_2070_2099"
    if (res == "0.5" ):
        plt.title("tas "+scenario+" "+tim+" "+res[0:5]+"° "+ensoperator)
    else:
        plt.title("tas "+scenario+" "+timing+" "+res[0:5]+"° "+ensoperator)
    
    #plt.colorbar()
    # Save the plot:
    plt.savefig(out+"tas_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+'.'+formats,dpi=300,bbox_inches='tight')
    cmd = "rm out_1.nc out.nc"
    os.system(cmd)
    #plt.show()
    plt.close()
    fig = plt.figure()
    cbar_ax = fig.add_axes([0.17, 0.17, 0.60, 0.04])
    cbar = fig.colorbar(plot_1, cax=cbar_ax, orientation="horizontal", extend="both")
    cbar.ax.set_xlabel('Temperature [K]')
    plt.savefig(out+"tas_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+"_colorbar.png",dpi=300,bbox_inches='tight')
    plt.close()









def plot_tasmin(time_slice,scenario,data,prefix,res, member,vmin,
 vmax,N,out, formats, ensoperator, timing):
    '''
    function to plot the ensmean and ensstd of the near surface air temperature

    - input: 
        tim_slice: string, time_slice of the simulations. 
        scenario:  string, scenario of the simulations. 
        data:      string, the directory of the data. 
        prefix:    string, prefix of the data name.
        res:       string, the resolution of the output data. 
        member:    string, the experiment number. 
        vmin:      float,  minimum value for the pcolor.
        vmax:      float,  maximum value for the pcolor.
        N:         integer, number of colors.    
        out:       string the directory where the plots have to be stored. 
        formats:    string, the format of the plots, e.g. pdf, png, etc.
        ensoperator: string, the operator for ensemble : ensmean or ensstd.
        timing:    string, time-slice of the simulation. 

    - output: 
        Plots. 
    '''

    if res == "0.5":
        data += "/GCMinput_coarse/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+".nc"
    else:
        data += "/GCMoutput_fine/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+"_BASD_"+member+"_"+res+timing+".nc"
    
    cmd = "cdo -O -"+ensoperator+" "+data+files+" out_1.nc"
    os.system(cmd)
    cmd = "cdo -O timmean out_1.nc out.nc"
    os.system(cmd)

    cmap = plt.cm.coolwarm # define the colormap
    bounds = np.linspace(vmin, vmax, N)
    lon,lat,vari = read_nc("out.nc","./", "tasmin")
    # make a meshgrid matrix from lon and lat : 
    lons,lats = np.meshgrid(lon,lat)
    # set up a map
    fig = plt.figure()
    ax = plt.axes(projection=ccrs.PlateCarree())
    # extract all colors from the .jet map
    cmaplist = [cmap(i) for i in range(cmap.N)]
    # create the new map
    cmap = mpl.colors.LinearSegmentedColormap.from_list('Custom cmap', cmaplist, cmap.N)
    norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    # plot the data:
    plot_1 = plt.pcolormesh(lons, lats,vari.squeeze() ,transform=ccrs.PlateCarree(),vmin=vmin,vmax=vmax,cmap=cmap, norm=norm,linewidth=0,rasterized=True)
    plot_1.set_edgecolor('face')
    # add coastlines:
    ax.coastlines()
    # add some features:
    
    #coastline = cfeature.COASTLINE
    borders = cfeature.BORDERS
    #ax.add_feature(borders)
    #lakes = cfeature.LAKES
    #rivers = cfeature.RIVERS
    #ax.add_feature(rivers)
    # add grids:
    gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True, linewidth=0.33, color='k',alpha=0.5)
    gl.xlabels_top = False
    gl.ylabels_right = False
    lat0=lat.min() # south lat
    lat1=lat.max() # north lat 
    lon0=lon.min() # west lon
    lon1=lon.max() # east lon

    gl.xlocator = mticker.FixedLocator(np.linspace(lon0,lon1,4))
    gl.ylocator = mticker.FixedLocator(np.linspace(lat0,lat1,4))


    if (time_slice == "near_future") & (res =="0.5") :
        tim = "_2015_2044"
    elif (time_slice == "middle_future") & (res =="0.5") : 
        tim = "_2045_2069"
    elif (time_slice == "far_future") & (res =="0.5") :
        tim = "_2070_2099"
    if (res == "0.5" ):
        plt.title("tasmin "+scenario+" "+tim+" "+res[0:5]+"° "+ensoperator)
    else:
        plt.title("tasmin "+scenario+" "+timing+" "+res[0:5]+"° "+ensoperator)
    
    #plt.colorbar()
    # Save the plot:
    plt.savefig(out+"tasmin_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+'.'+formats,dpi=300,bbox_inches='tight')
    cmd = "rm out_1.nc out.nc"
    os.system(cmd)
    #plt.show()
    plt.close()
    fig = plt.figure()
    cbar_ax = fig.add_axes([0.17, 0.17, 0.60, 0.04])
    cbar = fig.colorbar(plot_1, cax=cbar_ax, orientation="horizontal", extend="both")
    cbar.ax.set_xlabel('Temperature [K]')
    plt.savefig(out+"tasmin_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+"_colorbar.png",dpi=300,bbox_inches='tight')
    plt.close()



def plot_pr(time_slice,scenario,data,prefix,res, member,vmin,
 vmax,N,out, formats, ensoperator, timing):
    '''
    function to plot the ensmean and ensstd of the near surface air temperature

    - input: 
        tim_slice: string, time_slice of the simulations. 
        scenario:  string, scenario of the simulations. 
        data:      string, the directory of the data. 
        prefix:    string, prefix of the data name.
        res:       string, the resolution of the output data. 
        member:    string, the experiment number. 
        vmin:      float,  minimum value for the pcolor.
        vmax:      float,  maximum value for the pcolor.
        N:         integer, number of colors.    
        out:       string the directory where the plots have to be stored. 
        formats:    string, the format of the plots, e.g. pdf, png, etc.
        ensoperator: string, the operator for ensemble : ensmean or ensstd.
        timing:    string, time-slice of the simulation. 


    - output: 
        Plots. 
    '''

    if res == "0.5":
        data += "/GCMinput_coarse/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+".nc"
    else:
        data += "/GCMoutput_fine/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+"_BASD_"+member+"_"+res+timing+".nc"
    
    cmd = "cdo -O -"+ensoperator+" "+data+files+" out_1.nc"
    os.system(cmd)
    
    cmd = "cdo -O timmean out_1.nc out.nc"
    os.system(cmd)

    cmap = plt.cm.gist_ncar_r # define the colormap
    bounds = np.linspace(vmin, vmax, N)
    lon,lat,vari = read_nc("out.nc","./", "pr")
    # make a meshgrid matrix from lon and lat : 
    lons,lats = np.meshgrid(lon,lat)
    # set up a map
    fig = plt.figure()
    ax = plt.axes(projection=ccrs.PlateCarree())
    # extract all colors from the .jet map
    cmaplist = [cmap(i) for i in range(cmap.N)]
    # create the new map
    cmap = mpl.colors.LinearSegmentedColormap.from_list('Custom cmap', cmaplist, cmap.N)
    norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    # plot the data:
    plot_1 = plt.pcolormesh(lons, lats,vari.squeeze()*86400 ,transform=ccrs.PlateCarree(),vmin=vmin,vmax=vmax,cmap=cmap, norm=norm,linewidth=0,rasterized=True)
    plot_1.set_edgecolor('face')
    # add coastlines:
    ax.coastlines()
    # add some features:
    
    #coastline = cfeature.COASTLINE
    borders = cfeature.BORDERS
    #ax.add_feature(borders)
    #lakes = cfeature.LAKES
    #rivers = cfeature.RIVERS
    #ax.add_feature(rivers)
    # add grids:
    
    # add grids:
    gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True, linewidth=0.33, color='k',alpha=0.5)
    gl.xlabels_top = False
    gl.ylabels_right = False
    lat0=lat.min() # south lat
    lat1=lat.max() # north lat 
    lon0=lon.min() # west lon
    lon1=lon.max() # east lon

    gl.xlocator = mticker.FixedLocator(np.linspace(lon0,lon1,4))
    gl.ylocator = mticker.FixedLocator(np.linspace(lat0,lat1,4))

    if (time_slice == "near_future") & (res =="0.5") :
        tim = "_2015_2044"
    elif (time_slice == "middle_future") & (res =="0.5") : 
        tim = "_2045_2069"
    elif (time_slice == "far_future") & (res =="0.5") :
        tim = "_2070_2099"
    if (res == "0.5" ):
        plt.title("pr "+scenario+" "+tim+" "+res[0:5]+"° "+ensoperator)
    else:
        plt.title("pr "+scenario+" "+timing+" "+res[0:5]+"° "+ensoperator)

    #plt.colorbar()
    # Save the plot:
    plt.savefig(out+"pr_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+'.'+formats,dpi=300,bbox_inches='tight')
    cmd = "rm out_1.nc out.nc"
    os.system(cmd)
    #plt.show()
    plt.close()
    fig = plt.figure()
    cbar_ax = fig.add_axes([0.17, 0.17, 0.60, 0.04])
    cbar = fig.colorbar(plot_1, cax=cbar_ax, orientation="horizontal", extend="both")
    cbar.ax.set_xlabel('Precipitation [mm/day]')
    plt.savefig(out+"pr_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+"_colorbar.png",dpi=300,bbox_inches='tight')
    plt.close()






def plot_rsds(time_slice,scenario,data,prefix,res, member,vmin,
 vmax,N,out, formats, ensoperator, timing):
    '''
    function to plot the ensmean and ensstd of the near surface air temperature

    - input: 
        tim_slice: string, time_slice of the simulations. 
        scenario:  string, scenario of the simulations. 
        data:      string, the directory of the data. 
        prefix:    string, prefix of the data name.
        res:       string, the resolution of the output data. 
        member:    string, the experiment number. 
        vmin:      float,  minimum value for the pcolor.
        vmax:      float,  maximum value for the pcolor.
        N:         integer, number of colors.    
        out:       string the directory where the plots have to be stored. 
        formats:    string, the format of the plots, e.g. pdf, png, etc.
        ensoperator: string, the operator for ensemble : ensmean or ensstd.
        timing:    string, time-slice of the simulation. 


    - output: 
        Plots. 
    '''

    if res == "0.5":
        data += "/GCMinput_coarse/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+".nc"
    else:
        data += "/GCMoutput_fine/"
        files="*_w5e5_"+scenario+"_"+prefix+time_slice+"_BASD_"+member+"_"+res+timing+".nc"
    
    cmd = "cdo -O -"+ensoperator+" "+data+files+" out_1.nc"
    os.system(cmd)
    
    cmd = "cdo -O timmean out_1.nc out.nc"
    os.system(cmd)

    cmap = plt.cm.gist_ncar_r # define the colormap
    bounds = np.linspace(vmin, vmax, N)
    lon,lat,vari = read_nc("out.nc","./", "rsds")
    # make a meshgrid matrix from lon and lat : 
    lons,lats = np.meshgrid(lon,lat)
    # set up a map
    fig = plt.figure()
    ax = plt.axes(projection=ccrs.PlateCarree())
    # extract all colors from the .jet map
    cmaplist = [cmap(i) for i in range(cmap.N)]
    # create the new map
    cmap = mpl.colors.LinearSegmentedColormap.from_list('Custom cmap', cmaplist, cmap.N)
    norm = mpl.colors.BoundaryNorm(bounds, cmap.N)
    # plot the data:
    plot_1 = plt.pcolormesh(lons, lats,vari.squeeze() ,transform=ccrs.PlateCarree(),vmin=vmin,vmax=vmax,cmap=cmap, norm=norm,linewidth=0,rasterized=True)
    plot_1.set_edgecolor('face')
    # add coastlines:
    ax.coastlines()
    # add some features:
    
    #coastline = cfeature.COASTLINE
    borders = cfeature.BORDERS
    #ax.add_feature(borders)
    #lakes = cfeature.LAKES
    #rivers = cfeature.RIVERS
    #ax.add_feature(rivers)
    # add grids:
    #gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True,x_inline=False, #y_inline=False, linewidth=.5, color='gray', alpha=0.5, linestyle='--')

    gl = ax.gridlines(crs=ccrs.PlateCarree(), draw_labels=True, linewidth=0.33, color='k',alpha=0.5)
    gl.xlabels_top = False
    gl.ylabels_right = False
    # add grids:
    
    lat0=lat.min() # south lat
    lat1=lat.max() # north lat 
    lon0=lon.min() # west lon
    lon1=lon.max() # east lon

    gl.xlocator = mticker.FixedLocator(np.linspace(lon0,lon1,4))
    gl.ylocator = mticker.FixedLocator(np.linspace(lat0,lat1,4))


    if (time_slice == "near_future") & (res =="0.5") :
        tim = "_2015_2044"
    elif (time_slice == "middle_future") & (res =="0.5") : 
        tim = "_2045_2069"
    elif (time_slice == "far_future") & (res =="0.5") :
        tim = "_2070_2099"
    if (res == "0.5" ):
        plt.title("rsds "+scenario+" "+tim+" "+res[0:5]+"° "+ensoperator)
    else:
        plt.title("rsds "+scenario+" "+timing+" "+res[0:5]+"° "+ensoperator)
    #plt.colorbar()
    # Save the plot:
    plt.savefig(out+"rsds_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+'.'+formats,dpi=300,bbox_inches='tight')
    cmd = "rm out_1.nc out.nc"
    os.system(cmd)
    #plt.show()
    plt.close()
    fig = plt.figure()
    cbar_ax = fig.add_axes([0.17, 0.17, 0.60, 0.04])
    cbar = fig.colorbar(plot_1, cax=cbar_ax, orientation="horizontal", extend="both")
    cbar.ax.set_xlabel(r'rsds [$W/m^{2}$]')
    plt.savefig(out+"rsds_"+scenario+"_"+time_slice+"_"+res+"_"+ensoperator+"_colorbar.png",dpi=300,bbox_inches='tight')
    plt.close()







##---------------- the namelist
#res='0.5' # this is the original ISIMIP3b !!!
res="0.1"
#res="0.21428571428571427"
#res="0.04838709677419355"
#res="0.023809523809523808"
data = "/p/projects/gvca/bijan/Mats_02/out/"
os.system("mkdir -p ./plots")







pdf = PDF()
for time_slice in ["near_future",'middle_future','far_future']:
#for time_slice in ['far_future']:
    if (time_slice == "near_future") & (res !="0.5") :
        timing = "_2015_2044"
    elif (time_slice == "middle_future") & (res !="0.5") : 
        timing = "_2045_2069"
    elif (time_slice == "far_future") & (res !="0.5") :
        timing = "_2070_2099"
    elif (res =="0.5") :
        #TODO:

        timing = ""
    

    for scenario in ["ssp126","ssp370","ssp585"]:
#    for scenario in ["ssp126"]:



        # rsds -------------------------------------------
                  
        plot_rsds(time_slice=time_slice,scenario=scenario,data=data,prefix="rsds_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=100, vmax=300,N=21,out="./plots/", formats="png",
        ensoperator="ensmean", timing=timing)

        for elem in [["plots/rsds_"+scenario+"_"+time_slice+"_"+res+"_ensmean.png",
        "plots/rsds_"+scenario+"_"+time_slice+"_"+res+"_ensmean_colorbar.png"]]:
            pdf.print_page(elem)
    

        plot_rsds(time_slice=time_slice,scenario=scenario,data=data,prefix="rsds_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=25, vmax=50,N=26,out="./plots/", formats="png",
        ensoperator="ensstd", timing=timing)
        for elem in [["plots/rsds_"+scenario+"_"+time_slice+"_"+res+"_ensstd.png",
        "plots/rsds_"+scenario+"_"+time_slice+"_"+res+"_ensstd_colorbar.png"]]:
            pdf.print_page(elem)
        
        # tas -------------------------------------------

        plot_tas(time_slice=time_slice,scenario=scenario,data=data,
        prefix="tas_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=270, vmax=300,N=31,out="./plots/", formats="png",
        ensoperator="ensmean", timing=timing)
        for elem in [["plots/tas_"+scenario+"_"+time_slice+"_"+res+"_ensmean.png",
        "plots/tas_"+scenario+"_"+time_slice+"_"+res+"_ensmean_colorbar.png"]]:
            pdf.print_page(elem)


        plot_tas(time_slice=time_slice,scenario=scenario,data=data,
        prefix="tas_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=2.5, vmax=5.5,N=31,out="./plots/", formats="png",
        ensoperator="ensstd", timing=timing)
        for elem in [["plots/tas_"+scenario+"_"+time_slice+"_"+res+"_ensstd.png",
        "plots/tas_"+scenario+"_"+time_slice+"_"+res+"_ensstd_colorbar.png"]]:
            pdf.print_page(elem)

        # tasmin -------------------------------------------

        plot_tasmin(time_slice=time_slice,scenario=scenario,data=data,
        prefix="tasmin_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=270, vmax=300,N=31,out="./plots/", formats="png",
        ensoperator="ensmean", timing=timing)
        for elem in [["plots/tasmin_"+scenario+"_"+time_slice+"_"+res+"_ensmean.png",
        "plots/tasmin_"+scenario+"_"+time_slice+"_"+res+"_ensmean_colorbar.png"]]:
            pdf.print_page(elem)


        plot_tasmin(time_slice=time_slice,scenario=scenario,data=data,
        prefix="tasmin_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=2.5, vmax=3.5,N=21,out="./plots/", formats="png",
        ensoperator="ensstd", timing=timing)
        for elem in [["plots/tasmin_"+scenario+"_"+time_slice+"_"+res+"_ensstd.png",
        "plots/tasmin_"+scenario+"_"+time_slice+"_"+res+"_ensstd_colorbar.png"]]:
            pdf.print_page(elem)

        # tasmax -------------------------------------------

        plot_tasmax(time_slice=time_slice,scenario=scenario,data=data,
        prefix="tasmax_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=270, vmax=300,N=31,out="./plots/", formats="png",
        ensoperator="ensmean", timing=timing)
        for elem in [["plots/tasmax_"+scenario+"_"+time_slice+"_"+res+"_ensmean.png",
        "plots/tasmax_"+scenario+"_"+time_slice+"_"+res+"_ensmean_colorbar.png"]]:
            pdf.print_page(elem)


        plot_tasmax(time_slice=time_slice,scenario=scenario,data=data,
        prefix="tasmax_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=2.5, vmax=3.5,N=21,out="./plots/", formats="png",
        ensoperator="ensstd", timing=timing)
        for elem in [["plots/tasmax_"+scenario+"_"+time_slice+"_"+res+"_ensstd.png",
        "plots/tasmax_"+scenario+"_"+time_slice+"_"+res+"_ensstd_colorbar.png"]]:
            pdf.print_page(elem)


        # pr ---------------------------------------------
        plot_pr(time_slice=time_slice,scenario=scenario,data=data,
        prefix="pr_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=0, vmax=10,N=21,out="./plots/", formats="png",
        ensoperator="ensmean", timing=timing)
        for elem in [["plots/pr_"+scenario+"_"+time_slice+"_"+res+"_ensmean.png",
        "plots/pr_"+scenario+"_"+time_slice+"_"+res+"_ensmean_colorbar.png"]]:
            pdf.print_page(elem)

        plot_pr(time_slice=time_slice,scenario=scenario,data=data,
        prefix="pr_global_daily_cut_mergetime_member4_",
        res=res, member="4",vmin=3, vmax=6,N=31,out="./plots/", formats="png",
        ensoperator="ensstd", timing=timing)
        for elem in [["plots/pr_"+scenario+"_"+time_slice+"_"+res+"_ensstd.png",
        "plots/pr_"+scenario+"_"+time_slice+"_"+res+"_ensstd_colorbar.png"]]:
            pdf.print_page(elem)
        


 
pdf.output('Repot_res_'+res[0:5]+'.pdf', 'F')
