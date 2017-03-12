%Filename: 	OPeNDAPExample_TimeSeries_macav2metdata_SimpleExample.m
%Author:	Katherine Hegewisch (khegewisch@uidaho.edu)
%Updated: 	03/12/2017
%Description: 	This script uses OPeNDAP to download the specified subset of the MACAv2-METDATA data
%Requirements: 	This MATLAB script is run using MATLAB R2012a (which has native OPeNDAP support)
%		Older matlab versions need to get OpenEarthTools
%		For more information on using OPeNDAP in Matlab, 
%		see http://www.mathworks.com/help/matlab/ref/ncread.html
%=============================================
%      SET TARGET DATA
%=============================================
%day =1;
lat_target=45.0;
lon_target=-103.0+360;
%=============================================
%      SET OPENDAP PATH
%=============================================
pathname = 'http://thredds.northwestknowledge.net:8080/thredds/dodsC/agg_macav2metdata_tasmax_BNU-ESM_r1i1p1_historical_1950_2005_CONUS_daily.nc';
%Look at the contents of the file

ncdisp(pathname)
%=============================================
%      GET DATA SIZES
%=============================================
timeinfo = ncinfo(pathname,'time');
timeSize =timeinfo.Size;
loninfo = ncinfo(pathname,'lon');
lonSize =loninfo.Size;
latinfo = ncinfo(pathname,'lat');
latSize =latinfo.Size;
vinfo = ncinfo(pathname,'air_temperature'); %in tasmax file, the variable is called 'air_temperature'
vSize =vinfo.Size;
% the dimensions are:lon,lat,time
%=============================================
%      GET DATA
%=============================================
lat =ncread(pathname,'lat');
lon =ncread(pathname,'lon');
%=============================================
%find indices of target lat/lon/day
[m,lat_index] = min(abs(lat-lat_target));
[m,lon_index] = min(abs(lon-lon_target));
lat=lat(lat_index);
lon=lon(lon_index);
%=============================================
%extract time data
time =ncread(pathname,'time');
time_index = 1: length(time);
%see what these dates correspond to... 
time = double(time); %necessary for next command
[Y M D] =datevec(time+datenum(1900,1,1)); %the time variable says the units are 'days since 1900-01-01 00:00:00'
%=============================================
%data has 3 dimensions: time, lat,lon
start=[lon_index(1) lat_index(1) time_index(1)];
count=[length(lon) length(lat) length(time)];
stride=[1 1 1];  %every day of data
data=squeeze(ncread(pathname,'air_temperature',start,count,stride));
%=============================================
%      MAKE A PLOT
%=============================================
yearref=1950;

%plot only days in 1950
f=find(Y==1950);
time=time(f);
days = 1:length(time);
data=data(f);
figure(1);
plot(days,data,'b-');
xlabel('Time');
ylabel('Max Temperature (K)');
title(['Max Temperature (',num2str(lat),'N, ',num2str(360-lon),'W)']);
filename = 'myMatlabGraph.png';
print(filename,'-dpng');
