#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2023-10-20 ######
##################################################################################

#set -x
######## VARIABLES ########
declare -a outputfile="offline.repo"
declare -a outputfilepath="."
declare -a directory="/var/www/html"
declare -a repoDir="$directory/repo"
declare -a repoIP

######## FUNCTIONS ########

######## Check ilorest installed
function checkHttpdRunning() {
  output=`systemctl status httpd | grep -i active`
  if [[ "$output" == *"active (running)"* ]];then
    echo -e "\033[0;32m\nhttpd service installed and running...Continuing ahead...\033[0m"
  else
    echo -e "\033[0;31mhttpd service not installed/running...\033[0m"
    exit 0
  fi
}

######## MAIN ########

checkHttpdRunning

if [ ! -d "$repoDir" ]; then
  mkdir $directory/repo
fi

touch $outputfilepath/$outputfile

repoIP=$1
if [ "$#" -ne "1" ]; then
  echo ""
  read -p "Enter reposerver IP: " repoIP
fi

# Loop through files in the target directory
for dir in $repoDir/*; do
  if [ -d "$dir" ]; then
    repo=`echo "$dir" | awk -F'/' '{print$NF}'`
#    echo $repo
    echo -e "[$repo]" >> $outputfilepath/$outputfile
    echo -e "name=$repo" >> $outputfilepath/$outputfile
    echo -e "baseurl=http://[$repoIP]/repo/$repo/" >> $outputfilepath/$outputfile
    echo -e "enabled=1\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release\n" >> $outputfilepath/$outputfile
  fi
done
echo -e "\nOutput file generated at '$outputfilepath/$outputfile'"

