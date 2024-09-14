#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2022-10-04 ######
##################################################################################

######## VARIABLES ########
declare -a nodetag="hpe"
declare -a inputfile="$1"
declare -a desiredvaluesfile="$2"
declare -a outputpath="output"
declare -a rpmsdirectory="rpms"
declare -a rpmname
declare -a jsonpath="temp"
declare -a jsonfile
declare -a ofile
declare -a failedcasesfilename
declare -a nodename
declare -a nodeip
declare -i passcounter=0
declare -i failcounter=0
declare -i totalcounter=0
declare -i nodeCount=0
declare -i jsonCount=0


######## FUNCTIONS ########

######## Error Handling
error(){
  echo -e "\033[0;31m\nError !\033[0m\nUsage: ./checkAllParamsHp.sh <input-file-name-with-path> <desired-values-file-name-with-path>\n"
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
  echo -e "===============================================================================" > $jsonpath/$4
  echo -e "                                BIOS PARAMETERS\n===============================================================================\n" >> $jsonpath/$4
  ilorest list --selector Bios. --url "$1" -u "$2" -p "$3" --json >> $jsonpath/$4
  echo -e "\n===============================================================================" >> $jsonpath/$4
  echo -e "                          NETWORK PROTOCOL PARAMETERS\n===============================================================================\n" >> $jsonpath/$4
  ilorest list --selector ManagerNetworkProtocol --url "$1" -u "$2" -p "$3" --json >> $jsonpath/$4
  echo -e "\n===============================================================================" >> $jsonpath/$4
  echo -e "                             STORAGE PARAMETERS\n===============================================================================\n" >> $jsonpath/$4
  ilorest list --selector SmartStorageConfig --url "$1" -u "$2" -p "$3" --json >> $jsonpath/$4
  echo -e "\n===============================================================================" >> $jsonpath/$4
  echo -e "                             FIRMWARE PARAMETERS\n===============================================================================\n" >> $jsonpath/$4
  ilorest serverinfo --firmware --url "$1" -u "$2" -p "$3" --json >> $jsonpath/$4
  ilorest logout >> $jsonpath/$4
}


######## MAIN ########

if [ "$#" -ne "2" ]; then
  error
  exit 0
fi

if [ ! -f "$inputfile" ]; then
  errorFileMissing $inputfile
fi

if [ ! -f "$desiredvaluesfile" ]; then
  errorFileMissing $desiredvaluesfile
fi


######## Fetching Input

filenames=`ls $jsonpath/ | grep ".json"`
day=$(date +"%Y-%m-%d_%H:%M")
failedcasesfilename="failedCases-${day}.txt"
eval $(parse_yaml $inputfile)
eval $(parse_yaml $desiredvaluesfile)
nodecount=`cat $inputfile | grep $nodetag | wc -l`

echo -e "\nCHECKING IF ILOREST INSTALLED..........\n"
checkIlorestInstalled
echo -e "\nRUNNING ILOREST COMMANDS TO FETCH ALL PARAMETERS..........\n"
echo -e "This may take a while\n"

for (( i=1; i<=$nodecount; i++));
do
  node="$nodetag$i"
  nodeip="${!node}"
  jsonfile="$node-$nodeip.json"
  fetchJsonInput $nodeip $username $password $jsonfile  
done

######## Processing Output

echo "Failed Cases Output" > $outputpath/$failedcasesfilename
echo "Time:  $day" >> $outputpath/$failedcasesfilename
printf "Hostname of VM:  %s\n" $(hostname) >> $outputpath/$failedcasesfilename
echo "" | tee -a $outputpath/$failedcasesfilename

for (( i=1; i<=$nodecount; i++));
do
  node="$nodetag$i"
  nodeip="${!node}"
  jsonfile="$node-$nodeip.json"
  declare -i passcounter=0
  declare -i failcounter=0
  declare -i totalcounter=0
  ofile="logs-$node-$nodeip"

  ######## Get Server Details
  servername=`cat $jsonpath/$jsonfile | grep "ServerName" | cut -d'"' -f4`

  echo -e "Time:  $day\n" > $outputpath/$ofile
  echo "===========================================================================================" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
  echo "Node Details:   Name [$servername]     iLO IP $nodeip" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
  echo "===========================================================================================" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
  printf 'Parameter \t \t \t DesiredValue \t          ObservedValue\n' | expand -t 15 | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
  echo "-------------------------------------------------------------------------------------------" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile

  ######## Get C3 Power State / Minimum Processor Idle Power Core C-State
  output=`cat $jsonpath/$jsonfile | grep "MinProcIdlePower" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'Minimum Processor Idle Power Core C-State     %-23s %-23s\n' "$cPowerState" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$cPowerState" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get C6 Power State / Minimum Processor Idle Power Package Core C-State
  output=`cat $jsonpath/$jsonfile | grep "MinProcIdlePkgState" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'Min. Processor Idle Power Pkg Core C-State    %-23s %-23s\n' "$cPowerPackageState" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$cPowerPackageState" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get MLC Streamer

  ######## Get MLC Spacial Prefetcher / H/W Prefetcher
  output=`cat $jsonpath/$jsonfile | grep "HwPrefetcher" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'MLC Spacial Prefetcher / H/W Prefetcher       %-23s %-23s\n' "$hwPrefetch" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$hwPrefetch" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get DCU Data Prefetcher / DCU Stream Prefetcher
  output=`cat $jsonpath/$jsonfile | grep "DcuStreamPrefetcher" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'DCU Data Prefetcher / DCU Stream Prefetcher   %-23s %-23s\n' "$dcuStreamPrefetcher" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$dcuStreamPrefetcher" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get DCA / IO Direct Cache
  output=`cat $jsonpath/$jsonfile | grep "IODCConfiguration" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'DCA / IO Direct Cache                         %-23s %-23s\n' "$iodcConfig" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$iodcConfig" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get CPU Power and Performance / Energy/Performance Bias
  output=`cat $jsonpath/$jsonfile | grep "EnergyPerfBias" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'CPU Power & Performance / Energy/Perf. Bias   %-23s %-23s\n' "$energyPerfBias" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$energyPerfBias" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get Memory RAS and Performance Config → NUMA Optimized / Sub-NUMA Clustering
  output=`cat $jsonpath/$jsonfile | grep "SubNumaClustering" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'Memory RAS & Perf. Config / Sub-NUMA Cluster  %-23s %-23s\n' "$subNumaClustering" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$subNumaClustering" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get Turbo Boost
  output=`cat $jsonpath/$jsonfile | grep "ProcTurbo" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'Turbo Boost                                   %-23s %-23s\n' "$procTurbo" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$procTurbo" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get VT-d
  output=`cat $jsonpath/$jsonfile | grep "IntelProcVtd" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'VT-d                                          %-23s %-23s\n' "$intelProcVtd" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$intelProcVtd" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get NUMA memory interleave
  output=`cat $jsonpath/$jsonfile | grep "NodeInterleaving" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'NUMA memory interleave                        %-23s %-23s\n' "$nodeInterleaving" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$nodeInterleaving" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get RAID
  output=`cat $jsonpath/$jsonfile | grep "Raid" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'RAID                                          %-23s %-23s\n' "$raid" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$raid" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get SRIOV
  output=`cat $jsonpath/$jsonfile | grep "Sriov" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'SRIOV                                         %-23s %-23s\n' "$sriov" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$sriov" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get PCI Virtual Function Advertised

  ######## Get Boot Mode
  output=`cat $jsonpath/$jsonfile | grep "BootMode" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'Boot Mode                                     %-23s %-23s\n' "$bootMode" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$bootMode" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get Hyperthreading
  output=`cat $jsonpath/$jsonfile | grep "ProcHyperthreading" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'Hyperthreading                                %-23s %-23s\n' "$procHyperthreading" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$procHyperthreading" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get Enable PXE for eno5
  output=`cat $jsonpath/$jsonfile | grep "NicBoot5" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'PXE Embedded FlexibleLOM 1 Port 1             %-23s %-23s\n' "$nicBoot5" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$nicBoot5" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get Enable PXE for ens2f0
  output=`cat $jsonpath/$jsonfile | grep "Slot2NicBoot1" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'PXE Slot 2 Port 1                             %-23s %-23s\n' "$slot2NicBoot1" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$slot2NicBoot1" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get Internal SD Card
  output=`cat $jsonpath/$jsonfile | grep "InternalSDCardSlot" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'Internal SD Card                              %-23s %-23s\n' "$internalSDCardSlot" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$internalSDCardSlot" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get Pre-Boot Network Environment
  output=`cat $jsonpath/$jsonfile | grep "PrebootNetworkEnvPolicy" | cut -d'"' -f4`
  totalcounter=$(($totalcounter+1))
  printf 'Pre-Boot Network Environment                  %-23s %-23s\n' "$prebootNetworkEnvPolicy" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$prebootNetworkEnvPolicy" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get IPMI over LAN
  output=`cat $jsonpath/$jsonfile | grep "IPMI" -A 3 | grep "ProtocolEnabled" | awk -F": " '{print$2}'`
  totalcounter=$(($totalcounter+1))
  printf 'IPMI over LAN                                 %-23s %-23s\n' "$ipmiOverLAN" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$ipmiOverLAN" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get BIOS Firmware Version
  output=`cat $jsonpath/$jsonfile | grep "System ROM" | head -1 | cut -d'"' -f2 | awk -F ": " '{print$2}'`
  totalcounter=$(($totalcounter+1))
  printf 'Bios Version                                  %-23s %-23s\n' "$biosVersion" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$biosVersion" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get ILO Firmware Version
  output=`cat $jsonpath/$jsonfile | grep "iLO 5" | cut -d'"' -f2 | awk -F ": " '{print$2}'`
  totalcounter=$(($totalcounter+1))
  printf 'iLO Firmware Version                          %-23s %-23s\n' "$iloVersion" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$iloVersion" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get NIC Firmware Version HPE Ethernet 10/25Gb
  output=`cat $jsonpath/$jsonfile | grep "HPE Eth 10/25Gb 2p 640SFP28 Adptr" | head -1 | cut -d'"' -f2 | awk -F ": " '{print$2}'`
  totalcounter=$(($totalcounter+1))
  printf 'F/W Ver. HPE Eth 10/25Gb 2p 640SFP28 Adptr    %-23s %-23s\n' "$nic10_25g_1" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$nic10_25g_1" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get NIC Firmware Version HPE Ethernet 10/25Gb
  output=`cat $jsonpath/$jsonfile | grep "HPE Eth 10/25Gb 2p 640SFP28 Adptr" | tail -1 | cut -d'"' -f2 | awk -F ": " '{print$2}'`
  totalcounter=$(($totalcounter+1))
  printf 'F/W Ver. HPE Eth 10/25Gb 2p 640SFP28 Adptr    %-23s %-23s\n' "$nic10_25g_2" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$nic10_25g_2" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get NIC Firmware Version HPE Ethernet 10Gb
  output=`cat $jsonpath/$jsonfile | grep "HPE Ethernet 10Gb 2-port 562SFP+ Adapter" | head -1 | cut -d'"' -f2 | awk -F ": " '{print$2}'`
  totalcounter=$(($totalcounter+1))
  printf 'F/W Ver. HPE Eth 10Gb 2-port 562SFP+ Adapter  %-23s %-23s\n' "$nic10g_1" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$nic10g_1" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get NIC Firmware Version HPE Ethernet 10Gb
  output=`cat $jsonpath/$jsonfile | grep "HPE Ethernet 10Gb 2-port 562FLR-SFP+ Adpt" | tail -1 | cut -d'"' -f2 | awk -F ": " '{print$2}'`
  totalcounter=$(($totalcounter+1))
  printf 'F/W Ver. HPE Eth 10Gb 2-port 562FLR-SFP+ Adp  %-23s %-23s\n' "$nic10g_2" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$nic10g_2" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  ######## Get NIC Firmware Version HPE Ethernet 1Gb
  output=`cat $jsonpath/$jsonfile | grep "HPE Ethernet 1Gb 4-port 331i Adapter - NIC" | cut -d'"' -f2 | awk -F ": " '{print$2}'`
  totalcounter=$(($totalcounter+1))
  printf 'F/W Ver. HPE Eth 1Gb 4-port 331i Adapter NIC  %-23s %-23s\n' "$nic1g" "$output" | tee -a $outputpath/$ofile
  if [[ "$output" == "$nic1g" ]];then
    passcounter=$(($passcounter+1))
  else
    failcounter=$(($failcounter+1))
    cat $outputpath/$ofile | tail -1 >> $outputpath/$failedcasesfilename
  fi

  echo -e "\n***********************************" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
  echo "total cases:  $totalcounter" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
  echo "passed cases: $passcounter" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
  echo "failed cases: $failcounter" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
  echo -e "\n" | tee -a $outputpath/$failedcasesfilename $outputpath/$ofile
done
