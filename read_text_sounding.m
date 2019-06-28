%% This is a MATLAB script which downloads IGRA data and writes some specific variables to outputfile (csv).
% You need to know the stationID and the country code which are specified
% here: https://www1.ncdc.noaa.gov/pub/data/igra/igra2-country-list.txt
% 
tic

close all
clear all

% write the stationID + country code

stationID='03808';
countryCode='UK';

% define the data folder. This the place where the raw data will be
% downloaded and where the outputfile will be written
outputFolderPath='/home/local/mikarant/Documents/miscellaneous/data/';



% concatenate paths
url=char(strcat('https://www1.ncdc.noaa.gov/pub/data/igra/data/data-por/',countryCode,'M000',stationID,'-data.txt.zip'));
inputData=char(strcat(outputFolderPath,countryCode,'M000',stationID,'-data.txt.zip'));
outputData=char(strcat(outputFolderPath,countryCode,stationID,'.csv'));

% Download the IGRA data
data = websave(inputData,url);

% unzip the file
unzip(inputData,outputFolderPath);
% remove .zip from the end
inputDataFile=inputData(1:end-4);

% delete the previous output file
delete(outputData);

% open the unzipped input text file
fileID=fopen(inputDataFile);

% save array to test.csv file
% dlmwrite(outfilename,string(['Year','Month','Day','Hour','Value']),'-append','roffset',0,'coffset',0);

% loop over all the lines of the file
for i=1:1000000
    % read header
    header = fgetl(fileID);
    % year 
    ye = str2double(header(14:17));
    % month
    mo = str2double(header(19:20));
    % day
    da = str2double(header(22:23));
    % hour
    ho = str2double(header(25:26));
    % if hour=99, use the release hour
    if ho==99
        % release hour
        releaseHour = str2double(header(28:29));
        ho=releaseHour;
    end
    % mark hour as 12 if the sounding is launched +-2 hours around 12
    if ho==10 || ho==11 || ho==13 || ho==14
        ho=12;
    % and same for 00 hours
    elseif ho==22 || ho==23 
        ho=0;
        da=da+1;
    elseif ho==1 || ho==2
        ho=0;
    end
    
    % number of levels
    numLevels = str2double(header(34:36));
    
    % allocate variables
    pres=zeros(numLevels,1);
    z=zeros(numLevels,1);
    T=zeros(numLevels,1);
    
    % loop over all levels
    for l=1:numLevels
        str = fgetl(fileID);
        % read pressure
        pres(l,1) = str2double(str(10:13));
        % read geopotential height
        z(l,1) = str2double(str(18:21));
        % read temperature
        T(l,1) = str2double(str(24:27));
    end
    % find the index of 850 hPa level
    ind850=find(pres==850);
    % find the index of 500 hPa level
    ind500=find(pres==500);
    
    % find the geopotential height at 500 hPa level
    if ind500>0
        z500=z(ind500);
        % some quality checking
        if z500<=0
            z500=NaN;
        elseif z500>=6500
            z500=NaN;
        end
    % if 500 hPa level is not found, set it as NaN    
    else
        z500=NaN;
    end
    
    % same for temperature at 850 hPa
    if ind850>0
        t850=T(ind850);
        if t850<=-999
            t850=NaN;
        elseif t850>=999
            t850=NaN;
        end
    else
        t850=NaN;
    end
    
    % put the values to array: [year month day hour z500 T850]
    soundingArray(1,1)=ye;
    soundingArray(1,2)=mo;
    soundingArray(1,3)=da;
    soundingArray(1,4)=ho;
    soundingArray(1,5)=z500;
    soundingArray(1,6)=t850/10; 
    
    % save array to the outputfile
    dlmwrite(outputData,soundingArray,'-append','roffset',0,'coffset',0);
    
    % remove variables
    clear pres z T

    % display where the loop is going
    tit1=char(strcat('time:',{' '},num2str(ye),{' '},num2str(mo),{' '},num2str(da),{' '},num2str(ho),{' '},'read'));
    disp(tit1)
end
toc