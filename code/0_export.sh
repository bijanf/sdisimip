#!/bin/bash



###
### parameters
###
# chnaged the chunk size !!!!!!!


export versionW5E5=2.0
export versionISIMIP3BASD=3.0.1
export referenceperiod=1979-2014
export ysdecadeoffset=1  # decade start year offset from 0
export missval=1e20
export wetdaythreshold=.0000011574  # kg m-2 s-1 (equivalent to 0.1 mm/day)
export cdo="cdo -f nc4c -z zip"



###
### paths which can be changed arbitrarily
###

export idirCHELSA=/p/projects/proclias/1km/data/chelsa_w5e5/nc
export idirISIMIP=/p/projects/isimip/isimip/ISIMIP3b/InputData/climate/atmosphere/bias-adjusted/global/daily
export idirCMIP6=/p/projects/climate_data_central/CMIP/CMIP6  # directory containing raw CMIP6 data
export idirW5E5=/p/projects/climate_data_central/observation/W5E5/v$versionW5E5  # directory containing raw W5E5 data
export idirBASD=/home/slange/postdoc/isimip3basd/v$versionISIMIP3BASD  # directory containing BASD source code
export wdir=/p/projects/gvca/bijan/isimip3b_basd_central_asia  # work directory
export idirGCMdata=$wdir/GCMinput  # directory for preprocessed GCM data
export idirOBSdata=$wdir/OBSinput  # directory for observational data
export odirGCMdata=$wdir/GCMoutput  # directory for BASDed GCM data
export odirGCMdataPP=$wdir/GCMoutputPP  # directory for postprocessed BASDed GCM data



###
### output nc file global attributes
###



export output_data_title="ISIMIP3b bias-adjusted climate input data"
export output_data_institution="Potsdam Institute for Climate Impact Research (PIK)"
export output_data_project="Inter-Sectoral Impact Model Intercomparison Project phase 3b (ISIMIP3b)"
export output_data_contact="ISIMIP cross-sectoral science team <info@isimip.org> <https://www.isimip.org>"
#export output_data_summary="CMIP6 daily output data bias-adjusted and statistically downscaled to 0.5 degree horizontal resolution using ISIMIP3BASD v$versionISIMIP3BASD and W5E5 v$versionW5E5"
export output_data_summary="ISIMIP3b daily output data bias-adjusted and statistically downscaled to 0.25 degree horizontal resolution using ISIMIP3BASD v$versionISIMIP3BASD and CHELSA"
export output_data_references="Lange (2019) <https://doi.org/10.5194/gmd-12-3055-2019> and Lange (2021) <https://doi.org/10.5281/zenodo.5776126> for ISIMIP3BASD; Cucchi et al. (2020) <https://doi.org/10.5194/essd-2020-28> and Lange et al. (2021) <https://doi.org/10.48364/ISIMIP.342217> for W5E5"



###
### functions
###



function get_gcm_ISIMIP3b_dir {
  # $1 GCM name
  # returns the final directory for postprocessed BASDed GCM data

  case $1 in
  GFDL-ESM4|IPSL-CM6A-LR|MPI-ESM1-2-HR|MRI-ESM2-0|UKESM1-0-LL)
    echo /p/projects/isimip/isimip/ISIMIP3b/InputData/climate/atmosphere/bias-adjusted
    return 0;;
  CanESM5|CNRM-CM6-1|CNRM-ESM2-1|EC-Earth3|MIROC6)
    echo /p/projects/isimip/isimip/ISIMIP3b/SecondaryInputData/climate/atmosphere/bias-adjusted
    return 0;;
  *)
    echo /X/X/X/X/X/X/X/X
    return 1;;
  esac  # gcm
}
export -f get_gcm_ISIMIP3b_dir



function get_gcm_exp_var_ISIMIP3b_dir {
  # $1 GCM name
  # $2 CMIP6 experiment name
  # $3 variable name
  # returns the final directory for postprocessed BASDed GCM data

  local primary=1
  local ifix=

  case $1 in
  GFDL-ESM4|IPSL-CM6A-LR|MPI-ESM1-2-HR|MRI-ESM2-0|UKESM1-0-LL)
    :;;
  *)
    primary=0;;
  esac  # gcm

  case $2 in
  piControl|historical|ssp126|ssp370|ssp585)
    :;;
  *)
    primary=0;;
  esac  # exp

  case $3 in
  hurs|huss|pr|prsn|ps|rlds|rsds|sfcWind|tas|tasmax|tasmin)
    :;;
  *)
    primary=0;;
  esac  # var

  [ $primary -eq 0 ] && ifix=Secondary
  echo /p/projects/isimip/isimip/ISIMIP3b/${ifix}InputData/climate/atmosphere/bias-adjusted
  return 0
}
export -f get_gcm_exp_var_ISIMIP3b_dir



function get_gcm_resolution {
  # $1 GCM name
  # returns GCM resolution

  case $1 in
  EC-Earth3)
    echo 0p5deg
    return 0;;
  CNRM-CM6-1|CNRM-ESM2-1|GFDL-ESM4|MIROC6|MPI-ESM1-2-HR|MRI-ESM2-0)
    echo 1p0deg
    return 0;;
  CanESM5|IPSL-CM6A-LR|UKESM1-0-LL)
    echo 2p0deg
    return 0;;
  *)
    echo XpXdeg
    return 1;;
  esac  # gcm
}
export -f get_gcm_resolution



function get_gcm_member {
  # $1 GCM name
  # returns GCM member

  case $1 in
  CanESM5|EC-Earth3|GFDL-ESM4|IPSL-CM6A-LR|MIROC6|MPI-ESM1-2-HR|MRI-ESM2-0)
    echo r1i1p1f1
    return 0;;
  CNRM-CM6-1|CNRM-ESM2-1|UKESM1-0-LL)
    echo r1i1p1f2
    return 0;;
  *)
    echo rXiXpXfX
    return 1;;
  esac  # gcm
}
export -f get_gcm_member



function get_gcm_ys_piControl {
  # $1 GCM name
  # returns start year of piControl

  case $1 in
  CNRM-CM6-1|CNRM-ESM2-1|MPI-ESM1-2-HR|MRI-ESM2-0)
    echo 1850
    return 0;;
  CanESM5)
    echo 5201
    return 0;;
  EC-Earth3)
    echo 2259
    return 0;;
  GFDL-ESM4)
    echo 0001
    return 0;;
  IPSL-CM6A-LR)
    echo 1870
    return 0;;
  MIROC6)
    echo 3200
    return 0;;
  UKESM1-0-LL)
    echo 1960
    return 0;;
  *)
    echo YYYY
    return 1;;
  esac  # gcm
}
export -f get_gcm_ys_piControl



function get_var_limits {
  # $1 variable
  # returns "lower-upper" limit for that variable

  case $1 in
  hurs)  # %
    local lower=1.; local upper=100.;;
  huss)  # kg kg-1
    local lower=.0000001; local upper=.1;;
  pr)  # kg m-2 s-1 (equivalent to 0 to 600 mm/day)
    local lower=0.; local upper=.0069444444;;
  prsn)  # kg m-2 s-1 (equivalent to 0 to 300 mm/day)
    local lower=0.; local upper=.0034722222;;
  ps)  # Pa
    local lower=480.; local upper=110000.;;
  rlds)  # W m-2
    local lower=40.; local upper=600.;;
  rsds)  # W m-2
    local lower=0.; local upper=500.;;
  sfcWind)  # m s-1
    local lower=.1; local upper=50.;;
  tas|tasmax|tasmin)  # K (equivalent to -90 to +70 degC)
    local lower=183.15; local upper=343.15;;
  *)
    echo L-U
    return 1;;
  esac  # 1
  echo $lower-$upper
  return 0
}
export -f get_var_limits



function get_experiment_period {
  # $1 CMIP6 experiment name
  # returns "yearstart-yearend" of that experiment as used for bias correction

  case $1 in
  hist-nat)
    local ys=1850; local ye=2020;;
  piControl)
    local ys=1601; local ye=2100;;
  historical)
    local ys=1850; local ye=2014;;
  ssp534-over)
    local ys=2040; local ye=2100;;
  ssp???)
    local ys=2015; local ye=2100;;
  *)
    echo YYYY-YYYY
    return 1;;
  esac  # 1
  echo $ys-$ye
  return 0
}
export -f get_experiment_period



function get_BASD_application_periods {
  # $1 CMIP6 experiment name
  # returns "yearstart-yearend" of that experiment as used for bias correction

  case $1 in
  hist-nat)
    local pers="1850-1885 1886-1922 1923-1959 1960-1990 1991-2020";;
  piControl)
    local per=$(get_experiment_period $1)
    local ys_exp=$(cut -d '-' -f 1 <<<$per)
    local ye_exp=$(cut -d '-' -f 2 <<<$per)
    local inc=36
    local pers=
    for ys in $(seq $ys_exp $inc $ye_exp)
    do
      ye=$(($ys + $inc -1))
      if [ $ye -gt $ye_exp ]
      then
        yd=$(($ye - $ye_exp))
        ys=$(($ys - $yd))
        ye=$(($ye - $yd))
      fi
      [ -z "$pers" ] && pers=$ys-$ye || pers="$pers $ys-$ye"
    done;;
  historical)
    local pers="1850-1885 1886-1921 1922-1957 1958-1993";;
  historical-ssp???)
    local pers="1994-2029";;
  ssp534-over)
    local pers="2040-2075 2065-2100";;
  ssp???)
    local pers="2015-2050 2040-2075 2065-2100";;
  *)
    echo YYYY-YYYY
    return 1;;
  esac  # 1
  echo "$pers"
  return 0
}
export -f get_BASD_application_periods



function get_first_year_of_decade_containing {
  # $1 year to contain
  # $2 decade start year offset from 0
  # returns the first year of the decade with offset $2 containing $1

  if [[ $2 = [0-9] ]]
  then
    local ysd=$(expr $1 - $1 % 10 + $2)
    [ $ysd -gt $1 ] && ysd=$(expr $ysd - 10)
    echo $ysd
    return 0
  else
    echo ERROR !!! second argument has to be a one-digit number
    return 1
  fi
}
export -f get_first_year_of_decade_containing



function get_experiment_decades {
  # $1 CMIP6 experiment name
  # returns list of decades in the form
  # "yearstartfirstdecade-yearendfirstdecade yearstartseconddecade-yearendseconddecade ..."
  # for the given CMIP6 experiment
 
  local period=$(get_experiment_period $1)
  echo $(get_period_decades $period)
  return 0
}
export -f get_experiment_decades



function get_period_decades {
  # $1 time period in format YYYY-YYYY
  # returns list of decades in the form
  # "yearstartfirstdecade-yearendfirstdecade yearstartseconddecade-yearendseconddecade ..."
  # for the given time period
 
  local ys=$(cut -d '-' -f 1 <<<$1)
  local ye=$(cut -d '-' -f 2 <<<$1)
  local ysds=$(get_first_year_of_decade_containing $ys $ysdecadeoffset)
  local ysde=$(get_first_year_of_decade_containing $ye $ysdecadeoffset)

  local decades=
  local ysd
  for ysd in $(seq $ysds 10 $ysde)
  do
    local yed=$(( $ysd + 9 ))
    [ $ysd -lt $ys ] && ysd=$ys
    [ $yed -gt $ye ] && yed=$ye
    decades="$decades $ysd-$yed"
  done  # ysd

  echo $decades
  return 0
}
export -f get_period_decades



function is_leap_proleptic_gregorian {
  # $1 year
  # returns 1 if $1 is a leap year and 0 otherwise

  local il=0
  if (( ( $1 / 4 * 4 ) == $1 ))
  then
    if (( ( $1 / 100 * 100 ) == $1 ))
    then
      if (( ( $1 / 400 * 400 ) == $1 ))
      then
        il=1
      fi
    else
      il=1
    fi
  fi
  echo $il
  return 0
}
export -f is_leap_proleptic_gregorian



function chunk_time_series {
  # $1 path to nc file
  # $2 suffix appended to path for temporary output
  # $3 what else to do with ncks

  # get time dimension size, see <http://nco.sourceforge.net/nco.html#ncdmnsz>
  local n_times=$(ncks --trd -m -M $1 | grep -E -i ": time, size =" | cut -f 7 -d ' ' | uniq)
  # adjust chunking of nc files to improve lazy loadability by iris, see
  # <http://nco.sourceforge.net/nco.html#Chunking>
  ncks -O $3 --cnk_csh=15000000000 --cnk_plc=g3d --cnk_dmn=time,$n_times --cnk_dmn=lat,10 --cnk_dmn=lon,10 $1 $1$2
  local chunking_error=$?
  [ $chunking_error -eq 0 ] && mv $1$2 $1
  return $chunking_error
}
export -f chunk_time_series



function get_cdoexpr_huss_Weedon2010style {
  # returns the cdo expression that calculates specific humidity from
  # relative humidity, air pressure and temperature using the equations of
  # Buck (1981) Journal of Applied Meteorology 20, 1527-1532,
  # doi:10.1175/1520-0450(1981)020<1527:NEFCVP>2.0.CO;2 as described in
  # Weedon et al. (2010) WATCH Technical Report 22,
  # url:www.eu-watch.org/publications/technical-reports

  local shum=$1  # name of specific humidity [kg/kg]
  local rhum=$2  # name of relative humidity [1]
  local pres=$3  # name of air pressure [mb]
  local temp=$4  # name of temperature [degC]
  
  # ratio of the specific gas constants of dry air and water vapor after Weedon2010
  local RdoRv=0.62198
  
  # constants for calculation of saturation water vapor pressure over water and ice after Weedon2010, i.e.,
  # using Buck1981 curves e_w4, e_i3 and f_w4, f_i4
  local aw=6.1121   # [mb]
  local ai=6.1115   # [mb]
  local bw=18.729
  local bi=23.036
  local cw=257.87   # [degC]
  local ci=279.82   # [degC]
  local dw=227.3    # [degC]
  local di=333.7    # [degC]
  local xw=7.2e-4
  local xi=2.2e-4
  local yw=3.20e-6
  local yi=3.83e-6
  local zw=5.9e-10
  local zi=6.4e-10
  
  # prepare usage of different parameter values above and below 0 degC
  local a="(($temp>0)?$aw:$ai)"
  local b="(($temp>0)?$bw:$bi)"
  local c="(($temp>0)?$cw:$ci)"
  local d="(($temp>0)?$dw:$di)"
  local x="(($temp>0)?$xw:$xi)"
  local y="(($temp>0)?$yw:$yi)"
  local z="(($temp>0)?$zw:$zi)"
  
  # saturation water vapor pressure part of the equation
  local saturationpurewatervaporpressure="$a*exp(($b-$temp/$d)*$temp/($temp+$c))"
  local enhancementfactor="1.0+$x+$pres*($y+$z*$temp^2)"
  local saturationwatervaporpressure="($saturationpurewatervaporpressure)*($enhancementfactor)"
  
  # saturation water vapor pressure -> saturation specific humidity -> specific humidity
  echo "$shum=$rhum*$RdoRv/($pres/($saturationwatervaporpressure)+$RdoRv-1.0);"
  return 0
}
export -f get_cdoexpr_huss_Weedon2010style



function analyse_data_availability {
  # $@ paths to nc files
  # returns n_months_available n_months_gap n_months_overlap year_start year_end month_start month_end day_start day_end

  local paths=$(ls $@)
  if [ -z "$paths" ]
  then
    echo 0 0 0 0 0 0 0 0 0
  else
    # get first and last and lists of years and months of all files
    local nfiles=0
    local path
    for path in $paths
    do
      local ds=$(echo $path | rev | cut -d '_' -f 1 | rev | cut -d '-' -f 1)
      local de=$(echo $path | rev | cut -d '_' -f 1 | rev | cut -d '-' -f 2 | cut -d '.' -f 1)
      local ys=$(echo $ds | cut -c1-4)
      local ye=$(echo $de | cut -c1-4)
      local ms=$(echo $ds | cut -c5-6)
      local me=$(echo $de | cut -c5-6)
      local ds=$(echo $ds | cut -c7-8)
      local de=$(echo $de | cut -c7-8)
      if [ $nfiles -eq 0 ]
      then
        local ys0=$ys; local ye0=$ye; local ms0=$ms; local me0=$me; local ds0=$ds; local de0=$de
        local yss=$ys; local yes=$ye; local mss=$ms; local mes=$me
      else
        # update ys0, ms0 and ds0
        if [ $ys -le $ys0 ]
        then
          if [ $ys -lt $ys0 ]
          then
            ys0=$ys
            ms0=$ms
            ds0=$ds
          elif [ $ms -le $ms0 ]
          then
            if [ $ms -lt $ms0 ]
            then
              ms0=$ms
              ds0=$ds
            elif [ $ds -lt $ds0 ]
            then
              ds0=$ds
            fi
          fi
        fi
        # update ye0, me0 and de0
        if [ $ye -ge $ye0 ]
        then
          if [ $ye -gt $ye0 ]
          then
            ye0=$ye
            me0=$me
            de0=$de
          elif [ $me -ge $me0 ]
          then
            if [ $me -gt $me0 ]
            then
              me0=$me
              de0=$de
            elif [ $de -gt $de0 ]
            then
              de0=$de
            fi
          fi
        fi
        # extend list of start and end years and months
        yss=$yss,$ys; yes=$yes,$ye; mss=$mss,$ms; mes=$mes,$me
      fi
      nfiles=$(( $nfiles + 1 ))
    done  # path
  
    # get number of available, gap and overlap years
    local nmonths=$(python $wdir/get.nmonths.available.gap.overlap.py $ys0 $ye0 $ms0 $me0 $yss $yes $mss $mes)
    echo $nmonths $ys0 $ye0 $ms0 $me0 $ds0 $de0
  fi
  return 0
}
export -f analyse_data_availability



function uppercase {
  # $1 string
  # returns upper-case version of string

  echo "$1" | tr '[:lower:]' '[:upper:]'
  return 0
}
export -f uppercase



function lowercase {
  # $1 string
  # returns lower-case version of string

  echo "$1" | tr '[:upper:]' '[:lower:]'
  return 0
}
export -f lowercase



function time_diff {
  # $1 start time in seconds
  # $2 end time in seconds
  # returns formatted time difference

  dt=$(echo "$2 - $1" | bc)
  dd=$(echo "$dt/86400" | bc)
  dt2=$(echo "$dt-86400*$dd" | bc)
  dh=$(echo "$dt2/3600" | bc)
  dt3=$(echo "$dt2-3600*$dh" | bc)
  dm=$(echo "$dt3/60" | bc)
  ds=$(echo "$dt3-60*$dm" | bc)
  
#  LC_NUMERIC="en_US.UTF-8" printf "%d-%02d:%02d:%02.4f\n" $dd $dh $dm $ds
  printf "%d-%02d:%02d:%02.4f\n" $dd $dh $dm $ds
  return 0
}
export -f time_diff
