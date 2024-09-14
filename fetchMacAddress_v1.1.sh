#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.1.0 | Date Modified: 2023-01-03 ######
##################################################################################

#set -x

######## VARIABLES ########
declare -a folder="ilorestScripts"
declare -a nodetag="hpe"
declare -a inputfile="$1"
declare -a outputpath="/root/$folder/output"
declare -a rpmsdirectory="rpms"
declare -a rpmname
declare -a jsonpath="/root/$folder/temp"
declare -a jsonfile
declare -a ofile
declare -a nodename
declare -a nodeip
declare -a choice
declare -a extension
declare -i temp=1
declare -i count=0


######## FUNCTIONS ########

######## Error Handling
error(){
  echo -e "\033[0;31m\nError !\033[0m\nUsage: ./fetchMacAddress.sh <input-file-name-with-path>\n"
}

errorFileMissing(){
  echo -e "\033[0;31m\nError !\033[0m\nFile Missing: '$1' file not found...\n"
  exit 0
}

######## Parse yaml/yml file
function parse_yaml {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\):|\1|" \
      -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
      -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
      vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
      printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
    }
  }'
}

######## Check ilorest installed
function checkIlorestInstalled() {
  output=`ilorest -V`
  if [[ "$output" == *"RESTful Interface Tool"* ]];then
    echo -e "\033[0;32milorest tool already installed...Continuing ahead...\033[0m\n"
  else
    echo -e "\033[0;31milorest tool not installed...\033[0m\n"
    rpmname=`ls $rpmsdirectory | grep ilorest | tail -1`
    if [[ "$rpmname" == *"ilorest-"* ]]; then
      sudo dnf localinstall $rpmsdirectory/$rpmname
    else errorFileMissing "ilorest-*.rpm"
    fi
  fi
}

######## Fetch JSON Input using ilorest command
function fetchJsonInput() {
  echo -e "\ni\n==============================================================================="
  echo -e "                        ETHERNET INTERFACES PARAMETERS\n===============================================================================\n"
  ilorest list --selector EthernetInterface --url "$1" -u "$2" -p "$3" --json
  echo -e "\n==============================================================================="
}

function getMacInt0() {
  cat $1/$2 | grep "Manager Dedicated Network Interface" -A 5 -B 5 | grep MACAddress | cut -d'"' -f4
}

function getMacInt1() {
  cat $1/$2 | grep "EthernetInterfaces/1/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt2() {
  cat $1/$2 | grep "EthernetInterfaces/2/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt3() {
  cat $1/$2 | grep "EthernetInterfaces/3/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt4() {
  cat $1/$2 | grep "EthernetInterfaces/4/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt5() {
  cat $1/$2 | grep "EthernetInterfaces/5/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt6() {
  cat $1/$2 | grep "EthernetInterfaces/6/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt7() {
  cat $1/$2 | grep "EthernetInterfaces/7/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt8() {
  cat $1/$2 | grep "EthernetInterfaces/8/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt9() {
  cat $1/$2 | grep "EthernetInterfaces/9/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt10() {
  cat $1/$2 | grep "EthernetInterfaces/10/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt11() {
  cat $1/$2 | grep "EthernetInterfaces/11/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt12() {
  cat $1/$2 | grep "EthernetInterfaces/12/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt13() {
  cat $1/$2 | grep "EthernetInterfaces/13/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacInt14() {
  cat $1/$2 | grep "EthernetInterfaces/14/" -A 15 | grep MACAddress | cut -d'"' -f4
}

function getMacAll() {
  printf '%-40s%-30s\n' "$int0" "`getMacInt0 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int1" "`getMacInt1 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int2" "`getMacInt2 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int3" "`getMacInt3 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int4" "`getMacInt4 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int5" "`getMacInt5 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int6" "`getMacInt6 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int7" "`getMacInt7 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int8" "`getMacInt8 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int9" "`getMacInt9 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int10" "`getMacInt10 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int11" "`getMacInt11 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int12" "`getMacInt12 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int13" "`getMacInt13 $1 $2`" | tee -a $outputpath/$ofile
  printf '%-40s%-30s\n' "$int14" "`getMacInt14 $1 $2`" | tee -a $outputpath/$ofile
}


######## MAIN ########

if [ "$#" -ne "1" ]; then
  error
  exit 0
fi

if [ ! -f "$inputfile" ]; then
  errorFileMissing $inputfile
fi

######## Fetching Input

day=$(date +"%Y-%m-%d_%H_%M")
eval $(parse_yaml $inputfile)
nodecount=`cat $inputfile | grep $nodetag | wc -l`

echo -e "\nCHECKING IF ILOREST INSTALLED..........\n"
checkIlorestInstalled
read -p "Select output format (1) .csv  (2) .txt : " extension
echo -e "\n==========================================================="
echo -e "Select which MAC addresses to fetch from below...\n"
echo -e "1.  iLO\n2.  $int1\n3.  $int2\n4.  $int3\n5.  $int4\n6.  $int5\n7.  $int6\n8.  $int7\n9.  $int8\n10. $int9\n11. $int10\n12. $int11\n13. $int12\n14. $int13\n15. $int14"
echo -e "===========================================================\n"
read -p "Enter 'space-seperated integer choices' from above or 'all' (for all MAC) : " choice
echo -e "\nRUNNING ILOREST COMMANDS TO FETCH MAC ADDRESSES..........\n"
echo -e "This may take a while\n"

cat $inputfile | grep $nodetag | while read line;
do
  node=`echo $line | awk -F":" '{print$1}'`
  nodeip=`echo ${!node}`
  jsonfile="$node-EthInt-$nodeip.json"
  cat /dev/null > $jsonpath/$jsonfile
  echo "iLO IP : $nodeip" | tee -a $jsonpath/$jsonfile
  fetchJsonInput $nodeip $username $password >> $jsonpath/$jsonfile  
done
echo ""

######## Processing Output

if [[ "$extension" == "1" ]]; then
  extension=".csv"
  ofile="macAddressDetails-$day$extension"
  printf "Hostname of VM:  %s\n" $(hostname) > $outputpath/$ofile
  echo -e "Time:  $day\n" >> $outputpath/$ofile
  temp="1"
  if [[ "$choice" == "all" ]];then
    echo "iLO IP,$int0,$int1,$int2,$int3,$int4,$int5,$int6,$int7,$int8,$int9,$int10,$int11,$int12,$int13,$int14" >> $outputpath/$ofile
  else
    echo -n "iLO IP" >> $outputpath/$ofile
    for temp in {1..15}
    do
      count=`echo $choice | grep -w -c $temp`
      if [[ "$count" -gt "0" ]];then
        tmp="int$(($temp-1))"
        int="${!tmp}"
        echo -n ",$int" >> $outputpath/$ofile
      fi
    done
  echo "" >> $outputpath/$ofile
  fi
  cat $inputfile | grep $nodetag | while read line;
  do
    node=`echo $line | awk -F":" '{print$1}'`
    nodeip=`echo ${!node}`
    jsonfile="$node-EthInt-$nodeip.json"
    temp="1"
    if [[ "$choice" == "all" ]];then
      echo "$nodeip,`getMacInt0 $jsonpath $jsonfile`,`getMacInt1 $jsonpath $jsonfile`,`getMacInt2 $jsonpath $jsonfile`,`getMacInt3 $jsonpath $jsonfile`,`getMacInt4 $jsonpath $jsonfile`,`getMacInt5 $jsonpath $jsonfile`,`getMacInt6 $jsonpath $jsonfile`,`getMacInt7 $jsonpath $jsonfile`,`getMacInt8 $jsonpath $jsonfile`,`getMacInt9 $jsonpath $jsonfile`,`getMacInt10 $jsonpath $jsonfile`,`getMacInt11 $jsonpath $jsonfile`,`getMacInt12 $jsonpath $jsonfile`,`getMacInt13 $jsonpath $jsonfile`,`getMacInt14 $jsonpath $jsonfile`" >> $outputpath/$ofile
    else
      echo -n "$nodeip" >> $outputpath/$ofile
      for temp in {1..15}
      do
        count=`echo $choice | grep -w -c $temp`
        tmp="int$(($temp-1))"
        int="${!tmp}"
        if [[ "$count" -gt "0" ]];then
          echo -n ",`getMacInt$(($temp-1)) $jsonpath $jsonfile`" >> $outputpath/$ofile
        fi
      done
    echo "" >> $outputpath/$ofile
    fi
  done
else 
  extension=".txt"
  ofile="macAddressDetails-$day$extension"
  printf "Hostname of VM:  %s\n" $(hostname) > $outputpath/$ofile
  echo -e "Time:  $day\n" >> $outputpath/$ofile
  cat $inputfile | grep $nodetag | while read line;
  do
    node=`echo $line | awk -F":" '{print$1}'`
    nodeip=`echo ${!node}`
    jsonfile="$node-EthInt-$nodeip.json"
    temp="1"
    echo "===========================================================" | tee -a $outputpath/$ofile
    echo "Node iLO IP  $nodeip" | tee -a $outputpath/$ofile
    echo "===========================================================" | tee -a $outputpath/$ofile
    if [[ "$choice" == "all" ]];then
      getMacAll $jsonpath $jsonfile $outputpath $ofile
    else
      for temp in {1..15}
      do
        count=`echo $choice | grep -w -c $temp`
        tmp="int$(($temp-1))"
        int="${!tmp}"
        output=`getMacInt$(($temp-1)) $jsonpath $jsonfile`
        if [[ "$count" -gt "0" ]];then
          printf '%-40s%-30s\n' "$int" "$output" | tee -a $outputpath/$ofile
        fi
      done
    fi
    echo -e "===========================================================\n" | tee -a $outputpath/$ofile
  done
fi

