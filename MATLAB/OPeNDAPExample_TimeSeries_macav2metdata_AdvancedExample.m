%Filename: 	OPeNDAPExample_TimeSeries_macav2metdata_AdvancedExample.m
%Author:	K. Hegewisch (khegewisch@uidaho.edu)
%Updated: 	03/13/2017
%Description: 	This script uses OPeNDAP to download the specified subset of the MACAv2-METDATA data
%Requirements: 	MATLAB R2012a or later (which has native OPeNDAP support)
%	       	Older matlab versions need to get OpenEarthTools
%	       	For more information on using OPeNDAP in Matlab, 
%	       	see http://www.mathworks.com/help/matlab/ref/ncread.html
%=============================================
%      SET TARGET DATA -modify only the parameters in this section
%=============================================
%geographical region
lat_target=[45.0 45.2];  %min/max of latitude range
lon_target=[-103.0 -103.5]+360; %min/max of longitude range

%variables,models
var_target=[1 2 5 9]; %specifies index of VAR_NAME below to extract
model_target=[1:20]; %specifices indices of MODEL_NAME below to extract
exp_target=[1:2]; %specifices indidces of EXP_NAME below to extract

outputFileName='maca_subset.mat'
%=============================================
%      SET OPENDAP PATH DIRECTORY
%=============================================
pathDir='http://thredds.northwestknowledge.net:8080/thredds/dodsC/'; %(for macav2-metdata only)
%agg_macav2metdata_huss_BNU-ESM_r1i1p1_historical_1950_2005_CONUS_daily.nc
%=============================================
%      GET LAT/LON INDICES FOR GEOGRAPHICAL SUBSET
%=============================================
%look at sample file
pathname=[pathDir,'agg_macav2metdata_huss_BNU-ESM_r1i1p1_historical_1950_2005_CONUS_daily.nc']
loninfo = ncinfo(pathname,'lon');
lonSize =loninfo.Size;
latinfo = ncinfo(pathname,'lat');
latSize =latinfo.Size;

lat =ncread(pathname,'lat');
lon =ncread(pathname,'lon');

%indices of lat/lon subset
lat_index = find(lat<=max(lat_target)&lat>=min(lat_target));lat_index=[min(lat_index):max(lat_index)];
lon_index = find(lon<=max(lon_target)&lon>=min(lon_target));lon_index=[min(lon_index):max(lon_index)];

%subsetted lat/lon
lat=lat(lat_index);
lon=lon(lon_index);

time =ncread(pathname,'time');
index_days_historical=1:length(time);

pathname=[pathDir,'agg_macav2metdata_huss_BNU-ESM_r1i1p1_rcp45_2006_2099_CONUS_daily.nc']
time =ncread(pathname,'time');
index_days_future=index_days_historical+1:index_days_historical+length(time);

%=============================================
%     PARAMETERS 
%=============================================
EXP_NAME={'rcp45'; 'rcp85';};
VAR_NAME = {'tasmax';'tasmin';'rhsmax';'rhsmin';'pr';'rsds'; 'uas';'vas';'huss';};
VAR_LONGNAME = {'air_temperature';'air_temperature';'relative_humidity';'relative_humidity';...
		'precipitation_flux';'downward_shortwave_radiation'; 'northward_wind';'eastward_wind';...
		'specific_humidity';};
UNITS={'K';'K';'%';'%';'mm';'W m-2';'m s-1';'m s-1';'kg kg-1'};
MODEL_NAME={'CSIRO-Mk3-6-0';'inmcm4'; 'CanESM2';'MIROC-ESM';...
	 'MIROC-ESM-CHEM';'MRI-CGCM3';'CNRM-CM5';'IPSL-CM5A-MR';...
	'IPSL-CM5A-LR';'GFDL-ESM2G';'GFDL-ESM2M';'MIROC5';...
	 'bcc-csm1-1';'BNU-ESM';'NorESM1-M';'CCSM4';...
	'IPSL-CM5B-LR';'bcc-csm1-1-m';'HadGEM2-ES365';'HadGEM2-CC365'};
RUN_NUM = ones(20,1);f=find(strcmp(MODEL_NAME,'CCSM4'));RUN_NUM(f) = 6;
%=============================================
%     GET INDICES OF LAT/LON REGION
%=============================================
years_hist=[1950:2005];index_years_hist=years_hist-1950+1;
years_fut=[2006:2099];
m=matfile(outputFileName,'Writable',true);
m.data = NaN(length(lat),length(lon),length(index_days_historical)+length(index_days_future),length(exp_target),...
	length(model_target),length(var_target));
%add metadata to the file along with the data
m.years = [1950:2099];
m.models=MODEL_NAME(model_target);
m.variables=VAR_NAME(var_target);
m.units =UNITS(var_target);
m.scenarios=EXP_NAME(exp_target);
m.days='1-366 where the leap day will be on day 60 if present';

for var=1:length(var_target);
	for model = 1:length(model_target);
		modelname=char(MODEL_NAME(model_target(model)));
		%====================	
		%get historical part
		%====================	
		time_string='1950_2005';
		myURL=[pathDir,'agg_macav2metdata_',char(VAR_NAME(var_target(var))),'_',...
			char(MODEL_NAME(model_target(model))),'_',...
			'r',num2str(RUN_NUM(model)),'i1p1_',...
			'historical_',char(time_string),'_CONUS_daily.nc'];
		timeinfo = ncinfo(myURL,'time');
		timeSize =timeinfo.Size;
		vinfo = ncinfo(myURL,char(VAR_LONGNAME(var_target(var))));
		vSize =vinfo.Size; %the dimensions are:lon,lat,time

		%need to access just a small time slice first.. before getting the data-like a warmup
		%(solution credit:Ian Pfingsten)
		tempdata=ncread(myURL,char(VAR_LONGNAME(var_target(var))),[1 1 1],[1 1 1],[1 1 1]);

		start=[min(lon_index) min(lat_index) 1];
		count=[length(lon_index) length(lat_index) timeSize];
		stride=[1 1 1];  %every year of data, all lat/lon in range
		tempdata=ncread(myURL,char(VAR_LONGNAME(var_target(var))),start,count,stride);

		%restructure so has dimensions lon,lat,days
		time =ncread(pathname,'time');
		[Y M D] =datevec(double(time)+datenum(1900,1,1));
		tempdata=permute(tempdata,[2 1 3]); %switch dimension to lon,lat,days

		%save a copy of the historical part for all future scenarios in array
		for exp=1:length(exp_target);
			m.data(:,:,index_days_historical,exp,model,var) = tempdata;
		end;

		%====================	
		%get future part
		%====================	
		for exp=1:length(exp_target);
			index_years_fut=[2006:2099]-2006+1;
			time_string='2006_2099';
			myURL=[pathDir,'agg_macav2metdata_',char(VAR_NAME(var_target(var))),'_',...
				char(MODEL_NAME(model_target(model))),'_',...
				 'r',num2str(RUN_NUM(model)),'i1p1_',...
				char(EXP_NAME(exp_target(exp))),'_',char(time_string),'_CONUS_daily.nc'];
			timeinfo = ncinfo(myURL,'time');
			timeSize =timeinfo.Size;
			vinfo = ncinfo(myURL,char(VAR_LONGNAME(var_target(var))));
			vSize =vinfo.Size; %the dimensions are:lon,lat,time

			%need to access just a small time slice first.. before getting the data (credit:Ian Pfingsten)...warmup
			tempdata=ncread(myURL,char(VAR_LONGNAME(var_target(var))),[1 1 1],[1 1 1],[1 1 1]);

			start=[min(lon_index) min(lat_index) 1];
			count=[length(lon_index) length(lat_index) timeSize];
			stride=[1 1 1];  %every year of data, all lat/lon in range
			tempdata=ncread(myURL,char(VAR_LONGNAME(var_target(var))),start,count,stride);

			%restructure so has dimensions lon,lat,days
			time =ncread(pathname,'time');
			[Y M D] =datevec(double(time)+datenum(1900,1,1));
			tempdata=permute(tempdata,[2 1 3]); %switch dimension to lon,lat,days

                	%save a copy of the historical part for all future scenarios in array
                        m.data(:,:,index_days_future,exp,model,var) = tempdata;

		end;%exp
	end;%model
end;%var

