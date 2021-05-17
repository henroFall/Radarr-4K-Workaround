#!/bin/bash

#####################################
#
#   Created by: zacharyd3
#
#####################################
#
#   Declare Variables
#
#####################################


#Start Debugging (set as 1 to enable basic info, 2 shows all steps and comparison info)
debug=1
#Enable testing mode to simulate the move without actually moving any files (0 = moves files, 1 = Test)
testing=0
#Start counting the renaming passes made
passNumber=1
##Set the recycle bin locations
binLocation=/home/nuc/downloads/recycle
binMovie=/home/nuc/downloads/recycle/radarr
binTV=/home/nuc/downloads/recycle/sonarr
#Set the library locations
movieFolderRoot=/mnt/MediaG/Movies/
tvFolderRoot=/mnt/MediaF/TV/
#Set Date and Time variables
currentDate=$(date +'%m/%d/%Y')
currentTime=$(date +'%H:%M')

#If testing is enabled, automatically switch to debug mode 2
if [[ $testing -eq 1 && $debug -le 2 ]]; then
    debug=2
    echo -e "\e[34m\e[1mTesting is enabled, enabling advanced debugging.\e[0m"
fi

#####################################
#
#   Recycle Bin Upkeep
#
#####################################

echo -e ""
echo -e "\e[34m\e[1mRecycle Bin scan started!\e[0m"
echo -e ""
echo -e ""

#Checks if the movies recycle bin exists
if [[ ! -d "${binMovie}" ]]; then
    echo -e "\e[95m\e[1mMovie bin not found!\e[0m"
#Creates directory if it's missing
    mkdir "${binMovie}"
    echo -e "\e[32m\e[1mDirectory created.\e[0m"
    else
    echo -e "\e[32m\e[1mMovie bin already exists.\e[0m"
fi

#Checks if the tv show recycle bin exists
if [[ ! -d "${binTV}" ]]; then
    echo -e "\e[95m\e[1mTV Show bin not found!\e[0m"
#Creates directory if it's missing
    mkdir "${binTV}"
    echo -e "\e[32m\e[1mDirectory created.\e[0m"
else
    echo -e "\e[32m\e[1mTV Show bin already exists.\e[0m"
fi
echo -e ""

#####################################
#
#   Unneeded File Remover
#
#####################################

#Checks that the Recycle Bin is setup
if [[ -d "${binLocation}" && "$testing" -eq 0 ]]; then
    cd "${binLocation}"
#Finds all "extra" files and deletes them before moving any videos.
    find . -name "*.nfo" -type f -delete
    find . -name "*.srt" -type f -delete
    find . -name "*.ass" -type f -delete
    find . -name "*.jpg" -type f -delete
    if [ $debug -ge "2" ]; then
        echo -e "\e[32m\e[1mRemoved extra files (subtitles, images, info). \e[0m"
    fi
fi

#####################################
#
#   Low-res Movie Sorter
#
#####################################

#Declare variables
passNumber=1
inUse=0
rCheck=0
vCheck=0

echo -e ""
echo -e "\e[34m\e[1mCopying Low-res movies back.\e[0m"
echo -e ""
echo -e ""

#Check the files in the recycle bin
for file in "$binMovie"*
do
#Check if the file is a directory, if so, check it for movies
    if [ -d "${file}" ]; then
        directory=$file/
        for movieFile in "${directory}"*
        do
            if [ -f "${movieFile}" ]; then
#Parse the movie data from the filenames that were found
                if [ $debug -ge "2" ]; then
                    echo -e "\e[32m\e[1mOriginal File name: \e[0m""$movieFile"
                fi
                parseNameOld0=$(echo -e "$movieFile" | cut -d'/' -f5) #<<Change this number
                parseNameOld0=$(echo -e "$parseNameOld0" | cut -d'[' -f1)
                parseNameOld1=$(echo -e "$parseNameOld0" | cut -d'(' -f1) #Saves the original Movie name too (if the folder has a year it breaks things so this is needed)
                parseNameOld0=$(echo -e "$parseNameOld0" | xargs) #xargs removes leading and trailing whitespace.
                parseNameOld1=$(echo -e "$parseNameOld1" | xargs) #xargs removes leading and trailing whitespace.
                parseExt=$(echo -e "$movieFile" | cut -d'.' -f5)
                if [ $debug -ge "1" ]; then
                    echo -e "\e[32m\e[1mOriginal Movie name: \e[0m""$parseNameOld1"
                fi
#Check if the recycled file is in use.
                if lsof "$movieFile" > /dev/null; then
                    echo -e "\e[95m\e[1mThe file is in use, skipping.\e[0m"
                    echo -e ""
                    ((inUse=1))
                else
                    ((inUse=0))
                fi
#Check if the recycled file is a video
                if [[ $movieFile == *"mkv" || *"m2ts" || *"mp4" ]]; then
                    ((vCheck=0)) #Resets the Video Check for a new file
                else
                    if [[ $debug -ge "1" && "$inUse" -eq 0 ]]; then
                        echo -e "\e[95m\e[1mFile isn't a video, skipping\e[0m"
                        echo -e ""
                    fi
                    ((vCheck=1))
                fi
#Check if the recycled file is 1080p.
                if [[ $movieFile != *"1080p"* && "$vCheck" -eq "0" && "$inUse" -eq 0 ]]; then
                    if [ $debug -ge "1" ]; then
                        echo -e "\e[95m\e[1mThe file is not 1080p, skipping.\e[0m"
                        echo -e ""
                    fi
                    ((rCheck=1))
                else
                    ((rCheck=0))
                fi
#Turn the parsed movie name into a folder
                movieFolder0=$movieFolderRoot$parseNameOld0
                movieFolder1="${movieFolder0}/"
                if [[ $debug -ge "1" && "$vCheck" -eq "0" && "$rCheck" -eq "0" ]]; then
                    echo -e "\e[32m\e[1mSearching for 4K Movie folder: \e[0m""$movieFolder1"
                fi
#Test if the movie folder exists
                if [[ -d "${movieFolder1}" && "$vCheck" -eq "0" && "$rCheck" -eq "0" && "$inUse" -eq "0" ]]; then
                    if [ $debug -ge "1" ]; then
                        echo -e "\e[32m\e[1mFound matching 4K Movie Folder.\e[0m"
                    fi
                    cd "${movieFolder1}" || exit
#Search the movie folder for a 4K copy
                    foundNew=$(find ./ -type f \( -iname \*2160p*.mkv -o -iname \*2160p*.m2ts -o -iname \*2160p*.mp4 \) -maxdepth 1 -print -quit)
                    if [[ "$foundNew" != "" && "$vCheck" -eq "0" && "$rCheck" -eq "0" && "$inUse" -eq "0" ]]; then
                        if [ $debug -ge "1" ]; then
                            echo -e "\e[32m\e[1mFound matching 4K Movie: \e[0m""$foundNew"
                        fi
                    fi
                    if [[ "$foundNew" = "" && "$vCheck" -eq "0" && "$rCheck" -eq "0" && "$inUse" -eq "0" ]]; then
                        echo -e "\e[95m\e[1mNo matching 4K file found, skipping.\e[0m"
                        echo -e ""
                    fi
#Parse the found 4K copy name
                if [[ "$foundNew" == *"2160p"* && "$vCheck" -eq "0" ]]; then
                    parseNameNew0=$(echo -e "$foundNew" | cut -d'[' -f1)
                    parseNameNew0=$(echo -e "$parseNameNew0" | cut -d'/' -f2)
                    parseNameNew0=$(echo -e "$parseNameNew0" | xargs) #xargs removes leading and trailing whitespace
                    if [ $debug -ge "2" ]; then
                        echo -e "\e[91m\e[1mName Comparison:\e[0m |" "$parseNameOld1" "|" "$parseNameNew0" "|"
                    fi
                        if [[ "${parseNameOld1}" != "${parseNameNew0}" && $debug -ge "2" && $inUse -eq "0" ]]; then
                            echo -e "\e[91m\e[1mNo match found. \e[0m"
                            echo -e ""
                        fi
                        if [ "${parseNameOld1}" == "${parseNameNew0}" ]; then
                            if [ "${parseExt}" != "nfo" ]; then
                                if [ $debug -ge "2" ] && [ $inUse -eq "0" ]; then
                                    echo -e "\e[91m\e[1mFiles Checked: \e[0m"$passNumber
                                fi
                                ((passNumber++))
                                if [ $testing -eq "0" ]; then
                                    mv "${movieFile}" "${movieFolder1}"
                                    /usr/local/emhttp/webGui/scripts/notify -e "Radarr Copy" -s "Copy Notifcation" -d "$parseNameNew0 $parseExt has been copied back." -i "normal"
                                    echo -e "$currentDate,$currentTime,Movies,1080p,$parseNameNew0," >> "/mnt/user/Storage/Google Drive/Server Files/4K_Copier_History.csv"
                                fi
                                echo -e "\e[34m\e[1m""$parseNameNew0"" ""$parseExt"" moved.\e[0m"
                                echo -e ""
                            fi
                        fi
                    fi
                fi
            fi
        done
    fi
done

if [[ $passNumber -eq "1" ]]; then
    echo -e "No files to process"
    echo -e ""
fi

#####################################
#
#   4K Movie Sorter
#
#####################################

#Declare variables
passNumber=1
inUse=0
rCheck=0
vCheck=0

echo -e ""
echo -e "\e[34m\e[1mCopying 4K Movies back.\e[0m"
echo -e ""
echo -e ""

#Check the files in the recycle bin
for file in "$binMovie"*
do
#Check if the file is a directory, if so, check it for movies
    if [ -d "${file}" ]; then
        directory=$file/
        for movieFile in "${directory}"*
        do
            if [ -f "${movieFile}" ]; then
#Parse the movie data from the filenames that were found
                if [ $debug -ge "2" ]; then
                    echo -e "\e[32m\e[1mOriginal File name: \e[0m""$movieFile"
                fi
                parseNameOld0=$(echo -e "$movieFile" | cut -d'/' -f7) #<<Change this number
                parseNameOld0=$(echo -e "$parseNameOld0" | cut -d'[' -f1)echo -e "$parseNameOld0"
                parseNameOld1=$(echo -e "$parseNameOld0" | cut -d'(' -f1) #Saves the original Movie name too (if the folder has a year it breaks things so this is needed)
                parseNameOld0=$(echo -e "$parseNameOld0" | xargs) #xargs removes leading and trailing whitespace.
                parseNameOld1=$(echo -e "$parseNameOld1" | xargs) #xargs removes leading and trailing whitespace.
                parseExt=$(echo -e "$movieFile" | cut -d'.' -f5)
                if [ $debug -ge "1" ]; then
                    echo -e "\e[32m\e[1mOriginal Movie name: \e[0m""$parseNameOld1"
                fi
#Check if the recycled file is in use.
                if lsof "$movieFile" > /dev/null; then
                    echo -e "\e[95m\e[1mThe file is in use, skipping.\e[0m"
                    echo -e ""
                    ((inUse=1))
                else
                    ((inUse=0))
                fi
#Check if the recycled file is a video
                if [[ $movieFile == *"mkv" || *"m2ts" || *"mp4" ]]; then
                    ((vCheck=0)) #Resets the Video Check for a new file
                else
                    if [[ $debug -ge "1" && "$inUse" -eq 0 ]]; then
                        echo -e "\e[95m\e[1mFile isn't a video, skipping\e[0m"
                        echo -e ""
                    fi
                    ((vCheck=1))
                fi
#Check if the recycled file is 4K.
                if [[ $movieFile != *"2160p"* && "$vCheck" -eq "0" && "$inUse" -eq 0 ]]; then
                    if [ $debug -ge "1" ]; then
                        echo -e "\e[95m\e[1mThe file is not 4K, skipping.\e[0m"
                        echo -e ""
                    fi
                    ((rCheck=1))
                else
                    ((rCheck=0))
                fi
#Turn the parsed movie name into a folder
                movieFolder0=$movieFolderRoot$parseNameOld0
                movieFolder1="${movieFolder0}/"
                if [[ $debug -ge "1" && "$vCheck" -eq "0" && "$rCheck" -eq "0" ]]; then
                    echo -e "\e[32m\e[1mSearching for Low-res Movie folder: \e[0m""$movieFolder1"
                fi
#Test if the movie folder exists
                if [[ -d "${movieFolder1}" && "$vCheck" -eq "0" && "$rCheck" -eq "0" && "$inUse" -eq "0" ]]; then
                    if [ $debug -ge "1" ]; then
                        echo -e "\e[32m\e[1mFound matching Low-res Movie Folder.\e[0m"
                    fi
                    cd "${movieFolder1}"
#Search the movie folder for a 1080p copy
                    foundNew=$(find ./ -type f \( -iname \*1080p*.mkv -o -iname \*1080p*.m2ts -o -iname \*1080p*.mp4 \) -maxdepth 1 -print -quit)
                    if [[ "$foundNew" != "" && "$vCheck" -eq "0" && "$rCheck" -eq "0" && "$inUse" -eq "0" ]]; then
                        if [ $debug -ge "1" ]; then
                            echo -e "\e[32m\e[1mFound matching Low-res Movie: \e[0m""$foundNew"
                        fi
                    fi
                    if [[ "$foundNew" = "" && "$vCheck" -eq "0" && "$rCheck" -eq "0" && "$inUse" -eq "0" ]]; then
                        echo -e "\e[95m\e[1mNo matching Low-res file found, skipping.\e[0m"
                        echo -e ""
                    fi
#Parse the found 1080p copy name
                if [[ "$foundNew" == *"1080p"* && "$vCheck" -eq "0" ]]; then
                    parseNameNew0=$(echo -e "$foundNew" | cut -d'[' -f1)
                    parseNameNew0=$(echo -e "$parseNameNew0" | cut -d'/' -f2)
                    parseNameNew0=$(echo -e "$parseNameNew0" | xargs) #xargs removes leading and trailing whitespace
                    if [ $debug -ge "2" ]; then
                        echo -e "\e[91m\e[1mName Comparison:\e[0m |" "$parseNameOld1" "|" "$parseNameNew0" "|"
                    fi
                        if [[ "${parseNameOld1}" != "${parseNameNew0}" && $debug -ge "2" && $inUse -eq "0" ]]; then
                            echo -e "\e[91m\e[1mNo match found. \e[0m"
                            echo -e ""
                        fi

                        if [ "${parseNameOld1}" == "${parseNameNew0}" ]; then
                            if [ "${parseExt}" != "nfo" ]; then
                                if [ $debug -ge "2" ] && [ $inUse -eq "0" ]; then
                                    echo -e "\e[91m\e[1mFiles Checked: \e[0m"$passNumber
                                fi
                                ((passNumber++))
                                if [ $testing -eq "0" ]; then
                                    mv "${movieFile}" "${movieFolder1}"
                                    /usr/local/emhttp/webGui/scripts/notify -e "Radarr Copy" -s "Copy Notifcation" -d "$parseNameNew0 $parseExt has been copied back." -i "normal"
                                    echo -e "$currentDate,$currentTime,Movies,4K,$parseNameNew0," >> "/mnt/user/Storage/Google Drive/Server Files/4K_Copier_History.csv"
                                fi
                                echo -e "\e[34m\e[1m""$parseNameNew0"" ""$parseExt"" moved.\e[0m"
                                echo -e ""
                            fi
                        fi
                    fi
                fi
            fi
        done
    fi
done

if [[ $passNumber -eq "1" ]]; then
    echo -e "No files to process"
    echo -e ""
fi

#####################################
#
#   TV Show Sorter
#
#####################################

passNumber=1 #Counts how many files have been checked
inUse=0 #Saves if the file is in use and cancels
rCheck=0 #Set to 0 if it's ok to continue, 1 if it should end. (stands for Resolution Check)
vCheck=0 #Set to 0 if it's ok to continue, 1 if it skip the current file. (stands for Video Check)

echo -e ""
echo -e "\e[34m\e[1mCopying Low-res TV Show's back.\e[0m"
echo -e ""
echo -e ""

for file in "$binTV"*
do
#Start checking TV shows.
    #if [ "$(ls -A "$file")" ]; then
        directory=$file/
        for tvSeason in "${directory}"*/*
        do
            if [ -f "${tvSeason}" ]; then
                if [ $debug -ge "2" ]; then
                    echo -e "\e[32m\e[1mFull name: \e[0m""$tvSeason"
                fi
#Parse the show name, episode and season
                parseNameOld0=$(echo -e "$tvSeason" | cut -d'/' -f9)
                parseNameOld0=$(echo -e "$parseNameOld0" | cut -d'[' -f1)
                tvShowName=$(echo -e "$tvSeason" | cut -d'/' -f7)
                tvShowSeason=$(echo -e "$tvSeason" | cut -d'/' -f8)
                tvShowEpisode0=$(echo -e "$tvSeason" | cut -d'/' -f9)
                tvShowEpisode1=$(echo -e "$tvShowEpisode0" | cut -d'-' -f1)
                if [ $debug -ge "1" ]; then
                    echo -e "\e[32m\e[1mShow name: \e[0m""$tvShowName"
                    echo -e "\e[32m\e[1mShow episode: \e[0m""$tvShowEpisode1"
                fi
#Check if the file is in use.
                if lsof "$tvSeason" > /dev/null; then
                    echo -e "\e[95m\e[1mFile is in use, skipping.\e[0m"
                    echo -e ""
                    inUse=1
                else
                    inUse=0
                fi
#Check if the file is a video
                if [[ $tvSeason == *"mkv" || *"m2ts" ]]; then
                    ((vCheck=0)) #Resets the Video Check for a new file
                    ((rCheck=0)) #Resets the Continue Check for a new file
                else
                    if [[ $debug -ge "1" && "$inUse" -eq 0 ]]; then
                        echo -e "\e[95m\e[1mFile isn't a video, skipping\e[0m"
                        echo -e ""
                    fi
                    ((vCheck=1))
                fi
#Ensure the recycled file is 1080p
                if [[ $tvSeason == *"1080p"* && $vCheck -eq 0 && "$inUse" -eq 0 ]]; then
                        ((rCheck=0))
                else
                    if [[ $debug -ge "1" && $vCheck -eq "0" ]]; then
                        echo -e "\e[95m\e[1mThe file is not 1080p, skipping.\e[0m"
                        echo -e ""
                    fi
                ((rCheck=1))
                fi
#Parse the folder and Extension
                tvShowOriginal=$tvFolderRoot$tvShowName/$tvShowSeason/
                tvShowExtension=$(echo -e "$tvSeason" | cut -d'.' -f5)
#Check to see if the file matches a show
                if [ -d "${tvShowOriginal}" ]; then
                    cd "${tvShowOriginal}" || exit
#Search the folder for 4K shows
                    if [[ $debug -ge "2" && $rCheck -eq "0" && $vCheck -eq "0" ]]; then
                        echo -e "\e[32m\e[1mSearching for: \e[0m${tvShowEpisode1}*2160p*"
                    fi
                    foundNew=$(find ./ -type f \( -iname \${tvShowEpisode1}*2160p*.mkv -o -iname \${tvShowEpisode1}*2160p*.m2ts -o -iname \${tvShowEpisode1}*2160p*.mp4 \) -maxdepth 1 -print -quit)
                    if [[ "$foundNew" != "" &&  $rCheck -eq "0" && $vCheck -eq "0" ]]; then
                        if [ $debug -ge "1" ]; then
                            echo -e "\e[32m\e[1mFound matching 4K Show: \e[0m""$foundNew"
                        fi
                    fi
                    if [[ $debug -ge "1" && "$foundNew" = "" &&  $rCheck -eq "0" && $vCheck -eq "0" ]]; then
                        echo -e "\e[95m\e[1mNo matching 4K file found, skipping.\e[0m"
                        echo -e ""
                    fi
#Parse show name only if 4K filename found
                    if [[ "$foundNew" == *"2160p"* &&  $rCheck -eq "0" && $vCheck -eq "0" ]]; then
                        parseNameNew0=$(echo -e "$foundNew" | cut -d'[' -f1)
                        parseNameNew0=$(echo -e "$parseNameNew0" | cut -d'/' -f2)
                        if [ $debug -ge "2" ]; then
                            echo -e "\e[91m\e[1mName Comparison:\e[0m |" "$parseNameOld0" "|" "$parseNameNew0" "|"
                        fi
                        if [ "${parseNameOld0}" == "${parseNameNew0}" ]; then
                            if [ $debug -ge "2" ] && [ $inUse -eq "0" ]; then
                                echo -e "\e[91m\e[1mFiles Checked: \e[0m"$passNumber
                            fi
                            ((passNumber++))
                            if [ $testing -eq "0" ]; then
                                mv "${tvSeason}" "${tvShowOriginal}"
                                /usr/local/emhttp/webGui/scripts/notify -e "Radarr Copy" -s "Copy Notifcation" -d "$parseNameNew0 $parseExt has been copied back." -i "normal"
                                echo -e "$currentDate,$currentTime,TV Shows,1080p,$tvShowName: $tvShowEpisode1" >> "/mnt/user/Storage/Google Drive/Server Files/4K_Copier_History.csv"
                            fi
                            echo -e "\e[34m\e[1m""$tvShowName"" ""$tvShowEpisode1"" ""$tvShowExtension"" moved.\e[0m"
                            echo -e ""
                        fi
                    fi
                fi
            fi
        done
    #fi
done

if [[ $passNumber -eq "1" ]]; then
    echo -e "No files to process"
    echo -e ""
fi


#####################################
#
#   4K TV Show Sorter
#
#####################################

passNumber=1 #Counts how many files have been checked
inUse=0 #Saves if the file is in use and cancels
rCheck=0 #Set to 0 if it's ok to continue, 1 if it should end. (stands for Resolution Check)
vCheck=0 #Set to 0 if it's ok to continue, 1 if it skip the current file. (stands for Video Check)

echo -e ""
echo -e "\e[34m\e[1mCopying 4K TV Show's back.\e[0m"
echo -e ""
echo -e ""

for file in "$binTV"*
do
#Start checking TV shows.
    #if [ "$(ls -A "$file")" ]; then
        directory=$file/
        for tvSeason in "${directory}"*/*
        do
            if [ -f "${tvSeason}" ]; then
                if [ $debug -ge "2" ]; then
                    echo -e "\e[32m\e[1mFull name: \e[0m""$tvSeason"
                fi
#Parse the show name, episode and season
                parseNameOld0=$(echo -e "$tvSeason" | cut -d'/' -f9)
                parseNameOld0=$(echo -e "$parseNameOld0" | cut -d'[' -f1)
                tvShowName=$(echo -e "$tvSeason" | cut -d'/' -f7)
                tvShowSeason=$(echo -e "$tvSeason" | cut -d'/' -f8)
                tvShowEpisode0=$(echo -e "$tvSeason" | cut -d'/' -f9)
                tvShowEpisode1=$(echo -e "$tvShowEpisode0" | cut -d'-' -f1)
                if [ $debug -ge "1" ]; then
                    echo -e "\e[32m\e[1mShow name: \e[0m""$tvShowName"
                    echo -e "\e[32m\e[1mShow episode: \e[0m""$tvShowEpisode1"
                fi
#Check if the file is in use.
                if lsof "$tvSeason" > /dev/null; then
                    echo -e "\e[95m\e[1mFile is in use, skipping.\e[0m"
                    echo -e ""
                    inUse=1
                else
                    inUse=0
                fi
#Check if the file is a video
                if [[ $tvSeason == *"mkv" || *"m2ts" ]]; then
                    ((vCheck=0)) #Resets the Video Check for a new file
                    ((rCheck=0)) #Resets the Continue Check for a new file
                else
                    if [[ $debug -ge "1" && "$inUse" -eq 0 ]]; then
                        echo -e "\e[95m\e[1mFile isn't a video, skipping\e[0m"
                        echo -e ""
                    fi
                    ((vCheck=1))
                fi
#Ensure the recycled file is 4K
                if [[ $tvSeason == *"2160p"* && $vCheck -eq 0 && "$inUse" -eq 0 ]]; then
                    ((rCheck=0))
                else
                    if [[ $debug -ge "1" && $vCheck -eq "0" ]]; then
                        echo -e "\e[95m\e[1mThe file is not 4K, skipping.\e[0m"
                        echo -e ""
                    fi
                    ((rCheck=1))
                fi
#Parse the folder and Extension
                tvShowOriginal=$tvFolderRoot$tvShowName/$tvShowSeason/
                tvShowExtension=$(echo -e "$tvSeason" | cut -d'.' -f5)
#Check to see if the file matches a show
                if [ -d "${tvShowOriginal}" ]; then
                    cd "${tvShowOriginal}" || exit
#Search the new folder for Low-res shows
                    if [[ $debug -ge "2" && $rCheck -eq "0" && $vCheck -eq "0" ]]; then
                        echo -e "\e[32m\e[1mSearching for: \e[0m${tvShowEpisode1}*1080p*"
                    fi
                    foundNew=$(find ./ -type f \( -iname \${tvShowEpisode1}*1080p*.mkv -o -iname \${tvShowEpisode1}*1080p*.m2ts -o -iname \${tvShowEpisode1}*1080p*.mp4 \) -maxdepth 1 -print -quit)
                    if [[ "$foundNew" != "" &&  $rCheck -eq "0" && $vCheck -eq "0" ]]; then
                        if [ $debug -ge "1" ]; then
                            echo -e "\e[32m\e[1mFound matching Low-res Show: \e[0m""$foundNew"
                        fi
                    fi
                    if [[ $debug -ge "1" && "$foundNew" = "" &&  $rCheck -eq "0" && $vCheck -eq "0" ]]; then
                        echo -e "\e[95m\e[1mNo matching Low-res file found, skipping.\e[0m"
                        echo -e ""
                    fi
#Parse name only if 1080p filename found
                    if [[ "$foundNew" == *"1080p"* &&  $rCheck -eq "0" && $vCheck -eq "0" ]]; then
                        parseNameNew0=$(echo -e "$foundNew" | cut -d'[' -f1)
                        parseNameNew0=$(echo -e "$parseNameNew0" | cut -d'/' -f2)
                        if [ $debug -ge "2" ]; then
                            echo -e "\e[91m\e[1mName Comparison:\e[0m |" "$parseNameOld0" "|" "$parseNameNew0" "|"
                        fi
                        if [ "${parseNameOld0}" == "${parseNameNew0}" ]; then
                            if [ $debug -ge "2" ] && [ $inUse -eq "0" ]; then
                                echo -e "\e[91m\e[1mFiles Checked: \e[0m"$passNumber
                            fi
                            ((passNumber++))
                            if [ $testing -eq "0" ]; then
                                mv "${tvSeason}" "${tvShowOriginal}"
                                /usr/local/emhttp/webGui/scripts/notify -e "Radarr Copy" -s "Copy Notifcation" -d "$parseNameNew0 $parseExt has been copied back." -i "normal"
                                echo -e "$currentDate,$currentTime,TV Shows,4K,$tvShowName: $tvShowEpisode1" >> "/mnt/user/Storage/Google Drive/Server Files/4K_Copier_History.csv"
                            fi
                            echo -e "\e[34m\e[1m""$tvShowName"" ""$tvShowEpisode1"" ""$tvShowExtension"" moved.\e[0m"
                            echo -e ""
                        fi
                    fi
                fi
            fi
        done
    #fi
done

if [[ $passNumber -eq "1" ]]; then
    echo -e "No files to process"
    echo -e ""
fi


#####################################
#
#   Remove Empty Directories
#
#####################################

deletedDirCount=0

echo -e ""
echo -e "\e[34m\e[1mRemoving empty directories.\e[0m"
echo -e ""
echo -e ""

#Clear empty movie bins
for emptyDir in "$binMovie"*
do
#Check that the scanned item is a directory
    if [ -d "${emptyDir}" ]
    then
#Check for empty directories only
        if [[ -z $(ls -A "$emptyDir") ]]
        then
#Log individual deleted files if advanced debugging is enabled.
            if [ $debug -ge "2" ]
                then
                echo -e "\e[32m\e[1mDeleting: \e[0m""$emptyDir"
            fi
#Actually do the removing and count how many directories have been deleted.
            if [ $testing -eq 0 ]
            then
                rmdir "${emptyDir}"
                ((deletedDirCount++))
            fi
        fi
    fi
done

#Clear empty tv show season bins (This has to be done before trying to remove the show folder)
for emptyDir in "$binTV"*
do
    for emptySeason in "$binTV"*/*
    do
#Check that the scanned item is a directory
        if [ -d "${emptySeason}" ]
        then
#Check for empty directories only
            if [[ -z $(ls -A "$emptySeason") ]]
            then
#Log individual deleted files if advanced debugging is enabled.
                if [ $debug -ge "2" ]
                    then
                    echo -e "\e[32m\e[1mDeleting: \e[0m""$emptySeason"
                fi
#Actually do the removing and add to how many directories have been deleted.
                if [ $testing -eq 0 ]
                then
                    rmdir "${emptySeason}"
                    ((deletedDirCount++))
                fi
            fi
        fi
    done
done

#Clear empty tv show bins (this has to be done after removing the seasons first [above])
for emptyDir in "$binTV"*
do
#Check that the scanned item is a directory
    if [ -d "${emptyDir}" ]
    then
#Check for empty directories only
        if [[ -z $(ls -A "$emptyDir") ]]
        then
#Log individual deleted files if advanced debugging is enabled.
            if [ $debug -ge "2" ]
                then
                echo -e "\e[32m\e[1mDeleting: \e[0m""$emptyDir"
            fi
#Actually do the removing and add to how many directories have been deleted.
            if [ $testing -eq 0 ]
            then
                rmdir "${emptyDir}"
                ((deletedDirCount++))
            fi
        fi
    fi
done

#Log the deleted files and print message if testing is enabled instead.
if [ $testing -eq 0 ]
then
    echo -e "\e[32m\e[1mEmpty directories deleted: \e[0m""$deletedDirCount"
else
    echo -e "\e[95m\e[1mTesting is enabled, so nothing has been deleted.\e[0m"
fi

#Send a notification with total files copied.
((passNumber--))

#Notification where nothing was deleted but files were copied.
if [[ $passNumber -gt 1 && $testing -eq 0 && $deletedDirCount -eq 0 ]]
then
    /usr/local/emhttp/webGui/scripts/notify -e "Radarr Copy" -s "Copy Notifcation" -d "$passNumber files have been copied." -i "warning"
fi

#Notification where directories were deleted and files were copied.
if [[ $passNumber -gt 1 && $testing -eq 0 && $deletedDirCount -gt 0 ]]
then
    /usr/local/emhttp/webGui/scripts/notify -e "Radarr Copy" -s "Copy Notifcation" -d "$passNumber files have been copied, and $deletedDirCount empty directories have been deleted." -i "warning"
fi
