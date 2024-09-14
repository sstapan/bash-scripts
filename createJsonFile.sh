#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.2.0 | Date Modified: 2023-11-11 ######
##################################################################################

#set -x
######## VARIABLES ########
declare -a inputcsvfile="$1"
declare -a nodestartcount="$2"
declare -a nodeendcount="$3"
declare -a outputfile
declare -a ctrlcount
declare -a nodename
declare -a nodeprofile
declare -a nodeiloip
declare -a nodeilouser
declare -a nodeilopass
declare -a nodepxemac
declare -a noderootdev
declare -a nodecount
declare -i ctrlindex=0
declare -i compindex=0
declare -i strgindex=0
declare -i skipctrlcount=0
declare -i skipcompcount=0
declare -i skipstrgcount=0

day=$(date +"%Y-%m-%d_%H_%M")
logfile="logs_createJsonFile_$day"


######## FUNCTIONS ########

######## Error Handling
error(){
  echo -e "\033[0;31m\nError !\033[0m\nUsage: ./createJsonFile.sh <input-nodes-csv-file-name-with-path> [(optional) <start-node-count> <end-node-count>]\n"
}

errorFileMissing(){
  echo -e "\033[0;31m\nError !\033[0m\nFile Missing: '$1' file not found...\n"
  exit 0
}

errorInvalidNodeCount(){
  echo -e "\033[0;31m\nError !\033[0m\nInvalid node count...\n"
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

######## Parse csv file
function parse_csv {
  loc_col_a=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "$1" | tr -d " " | awk -F " " '{print $1}')
  loc_col_b=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "$2" | tr -d " " | awk -F " " '{print $1}')
  loc_col_c=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "$3" | tr -d " " | awk -F " " '{print $1}')
  loc_col_d=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "$4" | tr -d " " | awk -F " " '{print $1}')
  loc_col_e=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "$5" | tr -d " " | awk -F " " '{print $1}')
  while IFS="," read -r rec_a rec_b rec_c rec_d rec_e
  do
    echo "$rec_a $rec_b $rec_c $rec_d $rec_e"
  done < <(cut -d "," -f${loc_col_a},${loc_col_b},${loc_col_c},${loc_col_d},${loc_col_e} $inputcsvfile | tail -n +2)
}

function parse_csv_to_array {
arr_csv=()
while IFS= read -r line
do
    arr_csv+=("$line")
done < $2

echo "Displaying the contents of array mapped from csv file:"
index=0
for record in "${arr_csv[@]}"
do
    echo "Record at index-${index} : $record"
        ((index++))
done
}


######## MAIN ########

######## Pre-checks

if [[ "$#" -ne "1" ]] && [[ "$#" -ne "3" ]]; then
  error
  exit 0
fi

if [ ! -f "$inputcsvfile" ]; then
  errorFileMissing $inputcsvfile
fi

######## Fetching Input

ctrlcount=`cat $inputcsvfile | grep -i controller | wc -l`
nodecount=`cat $inputcsvfile | sed '/^\s*#/d;/^\s*$/d' | tail -n+2 |wc -l`

if [[ "$ctrlcount" -eq "3" ]] && [[ "$#" -eq "1" ]];then
  outputfile="instack-nodes.json"
  echo -e "{\n  \"nodes\": [" > $outputfile

  ######## Node Details
  loc_col_a=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "hostname" | tr -d " " | awk -F " " '{print $1}')
  loc_col_b=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "node_profile" | tr -d " " | awk -F " " '{print $1}')
  loc_col_c=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "ilo_ip" | tr -d " " | awk -F " " '{print $1}')
  loc_col_d=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "ilouser" | tr -d " " | awk -F " " '{print $1}')
  loc_col_e=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "ilopass" | tr -d " " | awk -F " " '{print $1}')
  loc_col_f=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "pxe_mac" | tr -d " " | awk -F " " '{print $1}')
  loc_col_g=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "root_device_hints" | tr -d " " | awk -F " " '{print $1}')

  ######## Push individual node details
  while IFS="," read -r nodename nodeprofile nodeiloip nodeilouser nodeilopass nodepxemac noderootdev
  do
#    echo "$nodename $nodeprofile $nodeiloip $nodeilouser $nodeilopass $nodepxemac $noderootdev"
    echo -e "    {\n      \"pm_password\": \"$nodeilopass\",\n      \"ports\": [{\n        \"address\": \"$nodepxemac\"\n      }],\n      \"name\": \"$nodename\",\n      \"pm_type\": \"ipmi\",\n      \"pm_user\": \"$nodeilouser\",\n      \"pm_addr\": \"$nodeiloip\",\n      \"root_device\": {\n        \"name\": \"$noderootdev\"\n      }," >> $outputfile
    if [[ $nodeprofile = "controller" ]];then
      echo -e "      \"capabilities\": \"node:$nodeprofile-$ctrlindex,boot_option:local,boot_mode:uefi\"" >> $outputfile
      let "ctrlindex=$((ctrlindex+1))"
    fi
    if [[ $nodeprofile = *"compute"* ]];then
      echo -e "      \"capabilities\": \"node:$nodeprofile-$compindex,boot_option:local,boot_mode:uefi\"" >> $outputfile
      let "compindex=$((compindex+1))"
    fi
    if [[ $nodeprofile = *"storage"* ]];then
      echo -e "      \"capabilities\": \"node:$nodeprofile-$strgindex,boot_option:local,boot_mode:uefi\"" >> $outputfile
      let "strgindex=$((strgindex+1))"
    fi
    echo -e "    }," >> $outputfile
  done < <(cut -d "," -f${loc_col_a},${loc_col_b},${loc_col_c},${loc_col_d},${loc_col_e},${loc_col_f},${loc_col_g} $inputcsvfile | tail -n +2)
  sed -i '$d' $outputfile
  echo -e "    }\n  ]\n}" >> $outputfile
  echo -e "\033[0;32mJson file generated\033[0m -> '$outputfile'"
elif [[ "$#" -eq "3" ]];then
  outputfile="instack-nodes$nodestartcount-$nodeendcount.json"
  skipctrlcount=`cat $inputcsvfile | head -$nodestartcount | grep -i controller | wc -l`
  skipcompcount=`cat $inputcsvfile | head -$nodestartcount | grep -i compute | wc -l`
  skipstrgcount=`cat $inputcsvfile | head -$nodestartcount | grep -i storage | wc -l`
  let "nodestartcount=$((nodestartcount+1))"
#  echo $nodecount $(($nodestartcount-1)) $nodeendcount $skipctrlcount $skipcompcount $skipstrgcount
  ctrlindex=$(($ctrlindex + $skipctrlcount))
  compindex=$(($compindex + $skipcompcount))
  strgindex=$(($strgindex + $skipstrgcount))
  echo -e "{\n  \"nodes\": [" > $outputfile

  ######## Node Details
  loc_col_a=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "hostname" | tr -d " " | awk -F " " '{print $1}')
  loc_col_b=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "node_profile" | tr -d " " | awk -F " " '{print $1}')
  loc_col_c=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "ilo_ip" | tr -d " " | awk -F " " '{print $1}')
  loc_col_d=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "ilouser" | tr -d " " | awk -F " " '{print $1}')
  loc_col_e=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "ilopass" | tr -d " " | awk -F " " '{print $1}')
  loc_col_f=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "pxe_mac" | tr -d " " | awk -F " " '{print $1}')
  loc_col_g=$(head -1 $inputcsvfile | tr ',' '\n' | nl | grep -w "root_device_hints" | tr -d " " | awk -F " " '{print $1}')

  ######## Push individual node details
  while IFS="," read -r nodename nodeprofile nodeiloip nodeilouser nodeilopass nodepxemac noderootdev
  do
#    echo "$nodename $nodeprofile $nodeiloip $nodeilouser $nodeilopass $nodepxemac $noderootdev"
    echo -e "    {\n      \"pm_password\": \"$nodeilopass\",\n      \"ports\": [{\n        \"address\": \"$nodepxemac\"\n      }],\n      \"name\": \"$nodename\",\n      \"pm_type\": \"ipmi\",\n      \"pm_user\": \"$nodeilouser\",\n      \"pm_addr\": \"$nodeiloip\",\n      \"root_device\": {\n        \"name\": \"$noderootdev\"\n      }," >> $outputfile
    if [[ $nodeprofile = "controller" ]];then
      echo -e "      \"capabilities\": \"node:$nodeprofile-$ctrlindex,boot_option:local,boot_mode:uefi\"" >> $outputfile
      let "ctrlindex=$((ctrlindex+1))"
    fi
    if [[ $nodeprofile = *"compute"* ]];then
      echo -e "      \"capabilities\": \"node:$nodeprofile-$compindex,boot_option:local,boot_mode:uefi\"" >> $outputfile
      let "compindex=$((compindex+1))"
    fi
    if [[ $nodeprofile = *"storage"* ]];then
      echo -e "      \"capabilities\": \"node:$nodeprofile-$strgindex,boot_option:local,boot_mode:uefi\"" >> $outputfile
      let "strgindex=$((strgindex+1))"
    fi
    echo -e "    }," >> $outputfile
  done < <(cut -d "," -f${loc_col_a},${loc_col_b},${loc_col_c},${loc_col_d},${loc_col_e},${loc_col_f},${loc_col_g} $inputcsvfile | tail -n +$nodestartcount | head -n "$((nodeendcount-nodestartcount+2))")
  sed -i '$d' $outputfile
  echo -e "    }\n  ]\n}" >> $outputfile
  echo -e "\033[0;32mJson file generated\033[0m -> '$outputfile'"
else
  errorInvalidNodeCount
fi

