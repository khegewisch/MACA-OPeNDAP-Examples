################### OPeNDAP EXAMPLE SCRIPT: SIMPLE ########################################
##### FILENAME: OPeNDAPExample_TimeSeries_macav2livneh_SimpleExample.r   ##################
##### PURPOSE: THIS SCRIPT PULLS ONE POINT AND ALL TIME STEPS FROM A MACA DATA FILE #######
##### AUTHOR: HEATHER DINON ALDRIDGE (hadinon@ncsu.edu) ###################################
##### UPDATED: FEBRUARY 5, 2015                      ######################################
##### THIS SCRIPT IS RUN USING R version 3.0.1 (2013-05-16) ###############################
##### FOR MORE INFORMATION ON THE ncdf4 R PACKAGE, SEE: ###################################
##### http://cran.r-project.org/web/packages/ncdf4/ncdf4.pdf ##############################
##### ANOTHER WAY TO ACCESS DATA USING OPeNDAP CAN BE FOUND HERE: #########################
##### http://lukemiller.org/index.php/2011/02/accessing-noaa-tide-data-with-r/ ############
###########################################################################################

  ## LOAD THE REQUIRED LIBRARY
  library(ncdf4)

  ### DEFINE THE URL
  urltotal<-"http://thredds.northwestknowledge.net:8080/thredds/dodsC/macav2livneh_huss_BNU-ESM_r1i1p1_historical_1950-2005_CONUS_daily_aggregated.nc"

  ## OPEN THE FILE
  nc <- nc_open(urltotal)

  ## SHOW SOME METADATA 
  nc
  
  ## DISPLAY INFORMATION ABOUT AN ATTRIBUTE
  ncatt_get(nc,"precipitation")
 
  ## GET DATA SIZES: http://www.inside-r.org/packages/cran/ncdf4/docs/ncvar_get
  ## NOTE: FILE DIMENSIONS ARE lon,lat,time
  v3 <- nc$var[[1]]
  lonsize <- v3$varsize[1]
  latsize <- v3$varsize[2] 
  endcount <- v3$varsize[3] 

  ### DEFINE OUR POINT OF INTEREST 
  ## NOTE: MAKE SURE TO CHECK WHETHER YOUR SOURCE STARTS COUNTING AT 0 OR 1
  ## e.g. ncdf4 PACKAGE STARTS COUNTING AT 1 BUT OPeNDAP DATASET ACCESS FORM STARTS AT 0:
  lon=478
  lat=176

  ## DEFINE OUR VARIABLE NAME 
  var="precipitation"
  
  ## READ THE DATA VARIABLE (e.g. precipitation IN THIS CASE): http://www.inside-r.org/packages/cran/ncdf4/docs/ncvar_get 
  ## AND http://stackoverflow.com/questions/19936432/faster-reading-of-time-series-from-netcdf
  ## ORDER OF start= AND count= IS BASED ON ORDER IN BRACKETS AFTER VARIABLE NAME (SHOWN WHEN DISPLAYING YOUR METADATA)
  ## FROM THE DOCUMENTATION... "If [start] not specified, reading starts at the beginning of the file (1,1,1,...)."
  ## AND "If [count] not specified and the variable does NOT have an unlimited dimension, the entire variable is read. 
  ## As a special case, the value "-1" indicates that all entries along that dimension should be read."
  data <- ncvar_get(nc, var, start=c(lon,lat,1),count=c(1,1,endcount))
  ## READ THE TIME VARIABLE
  time <- ncvar_get(nc, "time", start=c(1),count=c(endcount))
  ## CONVERT TIME FROM "days since 1900-01-01" TO YYYY-MM-DD
  time=as.Date(time, origin="1900-01-01") ##note: assumes leap years! http://stat.ethz.ch/R-manual/R-patched/library/base/html/as.Date.html
  # PUT EVERYTHING INTO A DATA FRAME
  c <- data.frame(time,data)

  ## CLOSE THE FILE
  nc_close(nc)

  ## PLOT THE DATA 
  plot(c$time,c$data,main=paste("Daily ",var," for ",c$time[1]," through ",c$time[nrow(c)], " at ",lat,",",lon,sep=""),xlab="Date",ylab="Precipitation (mm)")
  
