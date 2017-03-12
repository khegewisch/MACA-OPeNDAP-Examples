%Filename: 	OPeNDAPExample_TimeSeries_GeneralExample.m
%Author:	K. Hegewisch (khegewisch@uidaho.edu, Mar 2015)
%Updated: 	03/12/2017
%Description: 	This script uses OPeNDAP to download the specified subset of a MACAv2METDATA dataset
%Requirements: 	MATLAB R2012a or later (which has native OPeNDAP support)
%	       	Older matlab versions need to get OpenEarthTools
%	       	For more information on using OPeNDAP in Matlab, 
%	       	see http://www.mathworks.com/help/matlab/ref/ncread.html
%=============================================
%      SET TARGET DATA -modify only the parameters in this section
%=============================================
%maca product
product_target=3;     %specifies index of PRODUCT below to extract

%geographical region
lat_target=[45.0 45.2];  %min/max of latitude range
lon_target=[-103.0 -103.5]+360; %min/max of longitude range
myregion='MYREGION';

%variables,models
%var_target=[1 2 5 9]; %specifies index of VAR_NAME below to extract
var_target=[ 2]; %specifies index of VAR_NAME below to extract
%model_target=[1:20]; %specifices indices of MODEL_NAME below to extract
model_target=[2]; %specifices indices of MODEL_NAME below to extract
%exp_target=[1:2]; %specifices indidces of EXP_NAME below to extract
exp_target=[1]; %specifices indidces of EXP_NAME below to extract

%=============================================
%      SET OPENDAP PATH DIRECTORY
%=============================================
NKNTHREDDS='http://thredds.northwestknowledge.net:8080/thredds';
REACCHTHREDDS='http://thredds.northwestknowledge.net:8080/thredds';
THREDDSDIR={[REACCHTHREDDS,'/dodsC/'];[NKNTHREDDS,'/dodsC/'];[REACCHTHREDDS,'/dodsC/'];};
REGION_NAME={'WUSA';'CONUS';'CONUS';};
%=============================================
%     PARAMETERS
%=============================================
PRODUCT={'macav1metdata';'macav2livneh';'macav2metdata'};
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
%    OUTPUT FILENAME
%=============================================
outputFileName=[char(PRODUCT(product_target)),'_subset_',myregion,'.mat'];

%=============================================
%      GET LAT/LON INDICES FOR GEOGRAPHICAL SUBSET
%=============================================
%look at sample file
productname=char(PRODUCT(product_target));
threddsDir = char(THREDDSDIR(product_target));
regionname = char(REGION_NAME(product_target));
if(strcmp(productname,'macav2livneh'));
	pathname=[threddsDir,productname,'_huss_BNU-ESM_r1i1p1_historical_1950-2005_CONUS_daily_aggregated.nc'];
	%pathname will change from 1950-2005 to 1950_2005 soon
elseif(strcmp(productname,'macav2metdata'));
	pathname=[threddsDir,'agg_',productname,'_huss_BNU-ESM_r1i1p1_historical_1950_2005_CONUS_daily.nc'];
elseif(strcmp(productname,'macav1metdata'));
	pathname=[threddsDir,'agg_',productname,'_huss_BNU-ESM_r1i1p1_historical_1950_2005_WUSA.nc'];
end;

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

%=============================================
%     GET INDICES OF LAT/LON REGION
%=============================================
years_hist=[1950:2005];index_years_hist=years_hist-1950+1;
years_fut=[2006:2099];
m=matfile(outputFileName,'Writable',true);
if(strcmp(productname,'macav1metdata')); %365-day years
	m.data = NaN(length(lat),length(lon),365,length(years_hist)+length(years_fut),length(exp_target),...
		length(model_target),length(var_target));
else; %leap years
	m.data = NaN(length(lat),length(lon),366*(length(years_hist)+length(years_fut)),length(exp_target),...
		length(model_target),length(var_target));
end;
%add metadata to the file along with the data
m.years = [1950:2099];
m.models=MODEL_NAME(model_target);
m.variables=VAR_NAME(var_target);
m.units =UNITS(var_target);
m.scenarios=EXP_NAME(exp_target);
m.days='1-365 noleap day starting from Jan 1 - Dec 31';

for var=1:length(var_target);
        varname=char(VAR_NAME(var_target(var)));
	for model = 1:length(model_target);
		modelname=char(MODEL_NAME(model_target(model)));
		runname=num2str(RUN_NUM(model));
		%====================	
		%get historical part
		%====================	
		pathname=[threddsDir];

		time_string='1950_2005';
		middlePath=[productname,'_',varname,'_',modelname,'_',...
			'r',runname,'i1p1_',...
			'historical_',time_string,'_',...
			regionname];

		if(strcmp(productname,'macav2livneh'));
			time_string='1950-2005'; %this will change soon
			pathname=[pathname,'/',middlePath,'aggregated.nc'];
		elseif(strcmp(productname,'macav2metdata'));
			pathname=[pathname,'/agg_',middlePath,'_daily.nc'];
		elseif(strcmp(productname,'macav1metdata'));
			pathname=[pathname,'/agg_',middlePath,'.nc'];
		end;
		myURL = pathname;

		timeinfo = ncinfo(myURL,'time');
		timeSize =timeinfo.Size;
		vinfo = ncinfo(myURL,char(VAR_LONGNAME(var_target(var))));
		vSize =vinfo.Size; %the dimensions are:lon,lat,time

		%need to access just a small time slice first.. before getting the data 
		%(solution credit:Ian Pfingsten)
		%tempdata=ncread(myURL,char(VAR_LONGNAME(var_target(var))),[1 1 1],[1 1 1],[1 1 1]);

		start=[min(lon_index) min(lat_index) 1];
		count=[length(lon_index) length(lat_index) timeSize];
		stride=[1 1 1];  %every year of data, all lat/lon in range
		tempdata=ncread(myURL,char(VAR_LONGNAME(var_target(var))),start,count,stride);

		%change daily precipitation_flux to daily precipitation in mm (MACAv1-METDATA only)
		if(var==5 && strcmp(productname,'macav1metdata')); 
			tempdata =tempdata*3600*24;
		end;

		%restructure so has dimensions lon,lat,days,years
		if(strcmp(productname,'macav1metdata')); %365-day years
			tempdata = reshape(tempdata,length(lon),length(lat),365,timeSize/365);
			%restructure so has dimensions lat,lon,days,years
			tempdata=permute(tempdata,[2 1 3 4]);
			%save a copy of the historical part for all future scenarios in array
			for exp=1:length(exp_target);
				m.data(:,:,:,index_years_hist,exp,model,var) = tempdata;
			end;
		else;
			%save a copy of the historical part for all future scenarios in array
			for exp=1:length(exp_target);
				m.data(:,:,1:timeSize,exp,model,var) = tempdata;
			end;
		end;


		%====================	
		%get future part
		%====================	
		for exp=1:length(exp_target);
			if(strcmp(modelname(1:3),'Had'));
				time_string='2006_2099';
				index_years_fut=[2006:2099]-2006+1;
			else;
				time_string='2006_2100';
				index_years_fut=[2006:2100]-2006+1;
			end;
			myURL=[pathDir,'agg_macav1metdata_',char(VAR_NAME(var_target(var))),'_',...
				char(MODEL_NAME(model_target(model))),'_',...
				 'r',num2str(RUN_NUM(model)),'i1p1_',...
				char(EXP_NAME(exp_target(exp))),'_',char(time_string),'_WUSA.nc'];
			timeinfo = ncinfo(myURL,'time');
			timeSize =timeinfo.Size;
			vinfo = ncinfo(myURL,char(VAR_LONGNAME(var_target(var))));
			vSize =vinfo.Size; %the dimensions are:lon,lat,time

			%need to access just a small time slice first.. before getting the data (credit:Ian Pfingsten)
			tempdata=ncread(myURL,char(VAR_LONGNAME(var_target(var))),[1 1 1],[1 1 1],[1 1 1]);

			start=[min(lon_index) min(lat_index) 1];
			count=[length(lon_index) length(lat_index) timeSize];
			stride=[1 1 1];  %every year of data, all lat/lon in range
			tempdata=ncread(myURL,char(VAR_LONGNAME(var_target(var))),start,count,stride);

			if(var==5); %change daily precipitation_flux to daily precipitation in mm (MACAv1-METDATA only)
				tempdata =tempdata*3600*24;
			end;

			%restructure so has dimensions lon,lat,days,years
			tempdata = reshape(tempdata,length(lon),length(lat),365,timeSize/365);
			%restructure so has dimensions lat,lon,days,years
			tempdata=permute(tempdata,[2 1 3 4]);

			m.data(:,:,:,index_years_fut,exp,model,var) = tempdata;

		end;%exp
	end;%model
end;%var

