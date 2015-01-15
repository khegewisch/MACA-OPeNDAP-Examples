%Filename: 	OPeNDAPExample_TimeSeries_macav1metdata_SimpleExample.m
%Author:	Katherine Hegewisch (khegewisch@uidaho.edu)
%Updated: 	01/01/2015
%Description: This script uses OPeNDAP to download the specified subset of the MACAv1-METDATA data
%Requirements: 	This MATLAB script is run using MATLAB R2012a (which has native OPeNDAP support)
%		Older matlab versions need to get OpenEarthTools
%		For more information on using OPeNDAP in Matlab, 
%		see http://www.mathworks.com/help/matlab/ref/ncread.html
%=============================================
%      SET TARGET DATA
%=============================================
day =1;
lat_target=45.0;
lon_target=-103.0+360;
%=============================================
%      SET OPENDAP PATH
%=============================================
pathname = 'http://inside-dev1.nkn.uidaho.edu:8080/thredds/dodsC/agg_macav1metdata_huss_BNU-ESM_r1i1p1_historical_1950_2005_WUSA.nc'; %this is for macav1-metdata only
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
vinfo = ncinfo(pathname,'specific_humidity');
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
time_index = [day:365:timeSize];
time =ncread(pathname,'time',1,Inf,365);
%=============================================
%data has 3 dimensions: time, lat,lon
start=[lon_index lat_index time_index(1)];
count=[length(lon) length(lat) length(time)];
stride=[1 1 365];  %every year of data
data=squeeze(ncread(pathname,'specific_humidity',start,count,stride));
%=============================================
%      MAKE A PLOT
%=============================================
yearref=1950;
years = [1950:1950+length(time)-1];
figure(1);
plot(years,data,'b-');
xlabel('Years');
ylabel('Specific Humidity');
title(['Specific Humidity on Day ',num2str(day),' (',num2str(lat),'N, ',num2str(360-lon),'W)']);
filename = 'myMatlabGraph.png';
print(filename,'-dpng');
