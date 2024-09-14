#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.1 | Date Modified: 2022-04-10 ######
##################################################################################
#set -x
MNGCONTVSHPATH="/root/scriptsSatl/addtnlFiles"

######### Declare variables
connect=''
proxyEn="false"
proxyIp=''
proxyPort=''
proxyHttp=''
proxyHttpStatus=''
proxyHttpsStatus=''
proxyTempVariable1=''
proxyTempVariable2=''
proxyTempVariable3=''
proxyTempVariable4=''
proxyExists=''
proxyChk=''
proxyRemoved=''
proxyRmChk=''
fmuser=''
fmpass=''
enabledRepo=''
satOrgName=''
satLoc=''
satAdminUser=''
satAdminPass=''
satIntIp=''
satExtIp=''
satHostName=''
satDns=''
satPool=''
satHealth=''
satTempVar=''
hammerPingOkCount=''
hammerHealthCheck=''
manifestPath=''
manifestCheck=''
varResolveConf=''
fnVariable=''
option="0"

######### Check connectivity to https://subscription.rhsm.redhat.com


######### FUNCTIONS #########

######### Check proxy available
function checkProxy {
  if [ -f "proxy" ]; then
    proxyEn=`cat ~/scriptsSatl/proxy | grep proxyEnabled | awk -F"=" '{print$2}'`
    proxyIp=`cat ~/scriptsSatl/proxy | grep proxyIp | awk -F"=" '{print$2}'`
    proxyPort=`cat ~/scriptsSatl/proxy | grep proxyPort | awk -F"=" '{print$2}'`
    proxyHttp=`echo "http://$proxyIp:$proxyPort"`
    if [ "$proxyEn" == "true" ]; then
      proxyTempVariable1=`env | grep -i http_proxy | awk -F"=" '{print$2}'`
      proxyTempVariable2=`env | grep -i https_proxy | awk -F"=" '{print$2}'`
      if [ "$proxyTempVariable1" == "$proxyHttp" ] && [ "$proxyTempVariable2" == "$proxyHttp" ]; then
        proxyExists="true"
      else proxyExists="false"
      fi
    else proxyExists="NA"
    fi
  else proxyExists="NA"
  fi
  echo $proxyExists
}

######### Check if proxy removed
function removeProxy {
  if [ -f "proxy" ]; then  
    satTempVar=`cat ~/scriptsSatl/proxy | grep satelliteCapsuleInstalled | tail -1 | awk -F'=' '{print$2}'`
    proxyIp=`cat ~/scriptsSatl/proxy | grep proxyIp | awk -F"=" '{print$2}'`
    if [ "$satTempVar" == "yes" ]; then
      unset http_proxy
      unset https_proxy
      sudo sed -i -e "/$proxyIp/d" ~/.bashrc
      sudo sed -i "/proxyEnabled/c\proxyEnabled=false" ~/scriptsSatl/proxy
      echo -e "\033[1;33mPlease make sure manually, that proxy is removed by using the commands 'unset http_proxy' and 'unset https_proxy'.\n\033[0m" > /dev/stderr
      proxyRemoved="yes"
    fi
  else proxyRemoved="NA"
  fi
  echo $proxyRemoved
}

######### Check hammer health
function hammerPing {
  hammerPingOkCount=`hammer ping | grep "Status:          ok" | wc -l`
  if [ "$hammerPingOkCount" == "8" ]; then
    satHealth="good"
  else satHealth="bad"
  fi
  echo $satHealth
}

######### Function for option '2'
function fn2 {
  echo -e "---------- Following details are found ----------\n" > /dev/stderr
  cat addtnlFiles/satelliteFullDetails > /dev/stderr
  echo -e "-------------------------------------------------\n" > /dev/stderr
  echo -e "\033[1;33mType 'r' to reset and re-enter above details, else press any other key to continue\033[0m" > /dev/stderr
  read key;
  if [ "$key" == "r" ] ;then
    rm -f addtnlFiles/satelliteFullDetails
  else
    fmuser=`cat addtnlFiles/satelliteFullDetails | grep ForemanUsername | awk -F ':' '{print$2}'`
    fmpass=`cat addtnlFiles/satelliteFullDetails | grep ForemanPassword | awk -F ':' '{print$2}'`
    sudo subscription-manager remove --all > /dev/stderr
    sudo subscription-manager unregister > /dev/stderr
    sudo subscription-manager clean > /dev/stderr
    sudo yum clean all > /dev/stderr
    sudo rm -rf /var/cache/yum/*
    sudo subscription-manager register --username $fmuser --password $fmpass --force > /dev/stderr
    echo -e "\n\033[0;32m------------------- Registered to Red Hat successfully... --------------------\n\033[0m" > /dev/stderr
  fi
}

######### Function for option '3'
function fn3 {
  satPool=`sudo subscription-manager list --all --available --matches 'Red Hat Satellite Infrastructure Subscription' | grep Pool | awk -F ':' '{print$2}' | awk -F ' ' '{print$1}' | head -1`
  sudo subscription-manager attach --pool=$satPool > /dev/stderr
  echo -e "\n------ Disabling all repos... ------\n" > /dev/stderr
  sudo subscription-manager repos --disable=* > /dev/stderr
  if [ -f "addtnlFiles/enabledRepos" ]; then
    echo -e "\n------ Enabling the following repos... ------\n" > /dev/stderr
    cat addtnlFiles/enabledRepos > /dev/stderr
    echo -e "\n---------------------------------------------\n" > /dev/stderr
    read -p "Type any key to proceed with above or type 'q' to skip: " ans1;
    if [ "$ans1" == "q" ]; then
      echo "" > /dev/stderr
    else
      while read line 
      do 
        enabledRepo=`echo $line | awk -F":" '{print$2}'`
        sudo subscription-manager repos --enable=$enabledRepo
      done < addtnlFiles/enabledRepos
      sudo yum clean all > /dev/stderr
      sudo yum repolist enabled > /dev/stderr
      sudo yum update -y > /dev/stderr
      echo -e "\n\033[0;32m----------- Repos enabled and all packages updated successfully... -----------\n\033[0m" > /dev/stderr
    fi
  else echo -e "\n\033[0;31m---------------------- File containing repos not found -----------------------\n\033[0m" > /dev/stderr
  fi
}

######### Function for option '4'
function fn4 {
  satOrgName=`cat addtnlFiles/satelliteFullDetails | grep SatelliteOrganizationName | awk -F ':' '{print$2}'`
  satLoc=`cat addtnlFiles/satelliteFullDetails | grep SatelliteLocation | awk -F ':' '{print$2}'`
  satAdminUser=`cat addtnlFiles/satelliteFullDetails | grep SatelliteAdminUser | awk -F ':' '{print$2}'`
  satAdminPass=`cat addtnlFiles/satelliteFullDetails | grep SatelliteAdminPassword | awk -F ':' '{print$2}'`
  satIntIp=`cat addtnlFiles/satelliteFullDetails | grep SatelliteInternalIp | awk -F ':' '{print$2}'`
  satExtIp=`cat addtnlFiles/satelliteFullDetails | grep SatelliteExternalIp | awk -F ':' '{print$2}'`
  satHostName=`cat addtnlFiles/satelliteFullDetails | grep SatelliteHostname | awk -F ':' '{print$2}'`
  satDns=`cat addtnlFiles/satelliteFullDetails | grep SatelliteDns | awk -F ':' '{print$2}'`
  desEtcHosts=$(echo "$satIntIp $satHostName.$satDns $satHostName")
  etcHosts=$(cat /etc/hosts | grep $satIntIp | head -1)
  if [ "$etcHosts" == "$desEtcHosts" ]; then
    echo -e "\nHost entry exists for satellite in '/etc/hosts' file." > /dev/stderr
  else
    sudo echo $desEtcHosts >> /etc/hosts
    echo -e "\nHost entry added for satellite in '/etc/hosts' file as below," > /dev/stderr
    cat /etc/hosts | grep $satIntIp > /dev/stderr
  fi
  desEtcHosts=$(echo "$satExtIp $satHostName.$satDns $satHostName")
  etcHosts=$(cat /etc/hosts | grep $satExtIp | head -1)
  if [ "$etcHosts" == "$desEtcHosts" ]; then
    echo -e "\nHost entry exists for satellite in '/etc/hosts' file." > /dev/stderr
  else
    sudo echo $desEtcHosts >> /etc/hosts
    echo -e "\nHost entry added for satellite in '/etc/hosts' file as below," > /dev/stderr
    cat /etc/hosts | grep $satExtIp > /dev/stderr
  fi
  echo ""
  read -p "Type 'y' to begin satellite capsule installation, else press any other key to skip: " confrm;
  echo "" > /dev/stderr
  if [ "$confrm" == "y" ] ;then
    sudo yum install satellite -y > /dev/stderr
    sudo satellite-installer --scenario satellite --foreman-initial-organization "$satOrgName" --foreman-initial-location "$satLoc" --foreman-initial-admin-username $satAdminUser --foreman-initial-admin-password $satAdminPass > /dev/stderr
    sudo foreman-maintain packages install tfm-rubygem-hammer_cli_katello tfm-rubygem-hammer_cli_csv -y > /dev/stderr
    if [ -f "proxy" ]; then
      echo "satelliteCapsuleInstalled=yes" >> ~/scriptsSatl/proxy
    fi
    echo -e "\n\033[0;32m---------------- Satellite capsule installed successfully... -----------------\n\033[0m" > /dev/stderr
  fi
}

######### Function for option '5'
function fn5 {
  satOrgName=`cat addtnlFiles/satelliteFullDetails | grep SatelliteOrganizationName | awk -F ':' '{print$2}'`
  satAdminUser=`cat addtnlFiles/satelliteFullDetails | grep SatelliteAdminUser | awk -F ':' '{print$2}'`
  satAdminPass=`cat addtnlFiles/satelliteFullDetails | grep SatelliteAdminPassword | awk -F ':' '{print$2}'`
  hammer settings set --name default_redhat_download_policy --value immediate > /dev/stderr
  hammer settings set --name default_download_policy --value immediate > /dev/stderr
  echo "" > /dev/stderr
  read -p "Do you want to upload manifest file? (y/n): " ans2;
  if [ "$ans2" == "y" ]; then
    echo -e "\nEnter path for mainfest file (zip format) to be uploaded to satellite:" > /dev/stderr
    read manifestPath;
    echo -e "\n--------- Uploading Manifest file ---------\n" > /dev/stderr
    hammer -u $satAdminUser -p $satAdminPass subscription upload --file $manifestPath --organization "$satOrgName" > /dev/stderr
  fi
  echo -e "\n\033[0;32m---------------- Satellite capsule configured successfully... ----------------\n\033[0m" > /dev/stderr
}

######### Function for option '6'
function fn6 {
  fmuser=`cat addtnlFiles/satelliteFullDetails | grep ForemanUsername | awk -F ':' '{print$2}'`
  fmpass=`cat addtnlFiles/satelliteFullDetails | grep ForemanPassword | awk -F ':' '{print$2}'`
  satOrgName=`cat addtnlFiles/satelliteFullDetails | grep SatelliteOrganizationName | awk -F ':' '{print$2}'`
  ospContName=`cat addtnlFiles/ospContainers | grep OspContainerName | awk -F ':' '{print$2}'`
  dockerTag=`cat addtnlFiles/ospContainers | grep OspDockerTag | awk -F ':' '{print$2}'`
  satImgPath=`cat addtnlFiles/ospContainers | grep SatelliteImagePath | awk -F ':' '{print$2}'`
  manifestCheck=`hammer subscription manifest-history --organization "$satOrgName" | grep -i ':' | head -1 | awk '{print$1}'`
  if [[ "$manifestCheck" == *"SUCCESS"* ]]; then
    hammerHealthCheck=$(hammerPing)
    if [ "$hammerHealthCheck" == "good" ]; then
      if [ -f "addtnlFiles/subscriptionRepositories" ]; then
        echo -e "---------- Following details are found ----------\n" > /dev/stderr
        cat addtnlFiles/subscriptionRepositories > /dev/stderr
        echo -e "-------------------------------------------------\n" > /dev/stderr
        read -p "Enter 'y' to enable above repository sets: " ans3;
        if [ "$ans3" == "y" ]; then
          while read line
          do
            if [[ "$line" == *"Red Hat Enterprise Linux 8"* ]]; then
              hammer repository-set enable --name "$line" --basearch x86_64 --releasever "8.2" --organization "$satOrgName" > /dev/stderr
            else
              hammer repository-set enable --name "$line" --basearch x86_64 --organization "$satOrgName" > /dev/stderr
            fi
          done < addtnlFiles/subscriptionRepositories
        fi
        echo -e "\n\033[0;32m-------------------- Repositories enabled successfully... --------------------\n\033[0m" > /dev/stderr
      else echo -e "\n\033[0;31m------------ File containing subscription repositories not found -------------\n\033[0m" > /dev/stderr
      fi
      if [ -f "addtnlFiles/ospContainers" ]; then
        echo -e "---------- Following details are found ----------\n" > /dev/stderr
        cat addtnlFiles/ospContainers > /dev/stderr
        echo -e "-------------------------------------------------\n" > /dev/stderr
        read -p "Enter 'y' to create OSP Container Product with above details: " ans4;
        if [ "$ans4" == "y" ]; then
          hammer product create  --organization "$satOrgName" --name "$ospContName" > /dev/stderr
          while read IMAGE; 
		  do 
            IMAGENAME=$(echo $IMAGE | cut -d"/" -f2 | sed "s/openstack-//g" | sed "s/:.*//g") 
            hammer repository create --organization "$satOrgName" --product "$ospContName" --content-type docker --url https://registry.redhat.io --docker-upstream-name $IMAGE --docker-tags-whitelist $dockerTag --upstream-username $fmuser --upstream-password $fmpass --name $IMAGENAME > /dev/stderr
          done < $satImgPath
          hammer repository create --organization "$satOrgName" --product "$ospContName" --content-type docker --url https://registry.redhat.io --docker-upstream-name rhceph/rhceph-4-rhel8 --docker-tags-whitelist latest --upstream-username $fmuser --upstream-password $fmpass --name rhceph-4-rhel8 > /dev/stderr
        fi
        echo -e "\n\033[0;32m---------------------- Product created successfully... -----------------------\n\033[0m" > /dev/stderr
      else echo -e "\n\033[0;31m-------------- File containing OSP Container details not found ---------------\n\033[0m" > /dev/stderr
      fi
    else echo -e "\033[0;31mSatellite in bad health...!!! Please resolve...\n\033[0m" > /dev/stderr
    fi
  echo -e "\nFollowing Red Hat Reository Sets are Enabled...\n" > /dev/stderr
  hammer repository-set list --enabled yes --organization "$satOrgName" > /dev/stderr
  echo -e "\nFollowing repositories found in the Continer Product...\n" > /dev/stderr
  hammer repository list --product "$ospContName" --organization "$satOrgName" > /dev/stderr
  else echo -e "\n\033[0;31m-------------------------- Manifest file not found ---------------------------\n\033[0m" > /dev/stderr
  fi
}


######### Getting Input
if [ ! -f "addtnlFiles/satelliteFullDetails" ]; then
  echo -e "\nBefore proceeding any further, please input the following details,\n";
  read -p "Enter the foreman username: " fmuser;
  read -p "Enter the foreman password: " fmpass;
  read -p "Enter the satellite organization name: " satOrgName;
  read -p "Enter the satellite location: " satLoc;
  read -p "Enter the satellite admin user: " satAdminUser;
  read -p "Enter the satellite admin password: " satAdminPass;
  read -p "Enter the satellite internal IP: " satIntIp;
  read -p "Enter the satellite external IP: " satExtIp;
  satHostName=`hostname | cut -d "." -f 1`
  satDns=`hostname | cut -d "." -f2-`
  echo "ForemanUsername:$fmuser" > addtnlFiles/satelliteFullDetails
  echo "ForemanPassword:$fmpass" >> addtnlFiles/satelliteFullDetails
  echo "SatelliteOrganizationName:$satOrgName" >> addtnlFiles/satelliteFullDetails
  echo "SatelliteLocation:$satLoc" >> addtnlFiles/satelliteFullDetails
  echo "SatelliteAdminUser:$satAdminUser" >> addtnlFiles/satelliteFullDetails
  echo "SatelliteAdminPassword:$satAdminPass" >> addtnlFiles/satelliteFullDetails
  echo "SatelliteInternalIp:$satIntIp" >> addtnlFiles/satelliteFullDetails
  echo "SatelliteExternalIp:$satExtIp" >> addtnlFiles/satelliteFullDetails
  echo "SatelliteHostname:$satHostName" >> addtnlFiles/satelliteFullDetails
  echo "SatelliteDns:$satDns" >> addtnlFiles/satelliteFullDetails
  echo -e "-------------------------------------------------\n"
fi

#echo "$proxyEn $proxyIp $proxyPort $proxyHttp $proxyExists $fmuser $fmpass $satOrgName $satLoc $satAdminUser $satAdminPass $satIntIp $satExtIp $satHostName $satDns"
echo -e "\n################################################\n############ Satellite Installation ############\n################################################\n"
echo -e "[1] Set up proxy.\n[2] View/Edit Satellite Details / Register to Red Hat.\n[3] Enable repos and update all packages.\n[4] Installing satellite capsule.\n[5] Configuring satellite capsule.\n[6] Enable Repositories / Create products.\n[7] Sync satellite repos.\n[8] Manage Content View.\n[9] Revert satellite to fresh install.\n\033[0;34m[0] EXIT...\033[0m\n"
read -p "Select the desired option: " option;
echo ""

######### [1] Set up proxy.
if [ "$option" == "1" ];then
  if [ ! -f "proxy" ]; then
    read -p "\nEnter the proxy IP: " proxyIp;
    read -p "\nEnter the proxy port: " proxyPort;
    echo "proxyEnabled=true" > ~/scriptsSatl/proxy
    echo "proxyIp=$proxyIp" >> ~/scriptsSatl/proxy
    echo "proxyPort=$proxyPort" >> ~/scriptsSatl/proxy
  fi
  proxyIp=`cat ~/scriptsSatl/proxy | grep proxyIp | awk -F"=" '{print$2}'`
  proxyPort=`cat ~/scriptsSatl/proxy | grep proxyPort | awk -F"=" '{print$2}'`
  proxyHttp=`echo "http://$proxyIp:$proxyPort"`
  sudo sed -i "/proxy_hostname =/c\proxy_hostname = $proxyIp" /etc/rhsm/rhsm.conf
  sudo sed -i "/proxy_port =/c\proxy_port = $proxyPort" /etc/rhsm/rhsm.conf
  satDns=`cat addtnlFiles/satelliteFullDetails | grep SatelliteDns | awk -F ':' '{print$2}'`
  varResolveConf=`cat /etc/resolv.conf | grep $satDns | awk '{print$2}'`
  if [ "$varResolveConf" == "$satDns" ]; then
    echo ""
  else echo "search $satDns" >> /etc/resolv.conf
  fi
  export http_proxy=$proxyHttp
  export https_proxy=$proxyHttp
  proxyTempVariable3=`echo "http_proxy=$proxyHttp"`
  proxyTempVariable4=`cat ~/.bashrc | grep http_proxy | awk '{print$2}'`
  if [ "$proxyTempVariable3" == "$proxyTempVariable4" ]; then
    echo "HTTP proxy already exists..."
  else
    echo "export http_proxy=$proxyHttp" >> ~/.bashrc
  fi
  proxyTempVariable3=`echo "https_proxy=$proxyHttp"`
  proxyTempVariable4=`cat ~/.bashrc | grep https_proxy | awk '{print$2}'`
  if [ "$proxyTempVariable3" == "$proxyTempVariable4" ]; then
    echo "HTTPS proxy already exists..."
  else
    echo "export https_proxy=$proxyHttp" >> ~/.bashrc
  fi
  echo -e "\n\033[1;33m!!! Please execute the command 'source ~/.bashrc' manually after script execution... !!!\033[0m"
  echo -e "\n\033[0;32m------------------------- Proxy set successfully... --------------------------\n\033[0m"
  ./configureSatellite.sh

######### [2] View/Edit Satellite Details / Register to Red Hat.
elif [ "$option" == "2" ];then
  proxyChk=$(checkProxy)
  if [ "$proxyChk" == "true" ]; then
    fnVariable=$(fn2)
  elif [ "$proxyChk" == "NA" ]; then
    fnVariable=$(fn2)
  else  
    echo -e "\033[0;31mProxy Missing...!!! Please set up proxy first...\n\033[0m"
  fi
  ./configureSatellite.sh

######### [3] Enable repos and update all packages.
elif [ "$option" == "3" ];then
  proxyChk=$(checkProxy)
  if [ "$proxyChk" == "true" ]; then
    fnVariable=$(fn3)
  elif [ "$proxyChk" == "NA" ]; then
    fnVariable=$(fn3)
  else  
    echo -e "\033[0;31mProxy Missing...!!! Please set up proxy first...\n\033[0m"
  fi
  ./configureSatellite.sh

######### [4] Installing satellite capsule.
elif [ "$option" == "4" ];then
  proxyChk=$(checkProxy)
  if [ "$proxyChk" == "true" ]; then
    fnVariable=$(fn4)
  elif [ "$proxyChk" == "NA" ]; then
    fnVariable=$(fn4)
  else  
    echo -e "\033[0;31mProxy Missing...!!! Please set up proxy first...\n\033[0m"
  fi
  ./configureSatellite.sh

######### [5] Configuring satellite capsule.
elif [ "$option" == "5" ];then
  proxyRmChk=$(removeProxy)
  if [ "$proxyRmChk" == "yes" ]; then
    proxyHttp=`echo "http://$proxyIp:$proxyPort"`
    hammer http-proxy create --name=redhat-proxy --url $proxyHttp
    hammer settings set --name=content_default_http_proxy --value=redhat-proxy
    fnVariable=$(fn5)
  elif [ "$proxyRmChk" == "NA" ]; then
    fnVariable=$(fn5)
  fi
  ./configureSatellite.sh

######### [6] Enable Repositories / Create products.
elif [ "$option" == "6" ];then
  echo -e "\033[1;33mPlease make sure manually, that proxy is removed by using the commands 'unset http_proxy' and 'unset https_proxy'.\n\033[0m"
  proxyRmChk=$(removeProxy)
  if [ "$proxyRmChk" == "yes" ]; then
    fnVariable=$(fn6)
  elif [ "$proxyRmChk" == "NA" ]; then
    fnVariable=$(fn6)
  fi
  ./configureSatellite.sh

######### [7] Sync satellite repos.
elif [ "$option" == "7" ];then
  satOrgName=`cat addtnlFiles/satelliteFullDetails | grep SatelliteOrganizationName | awk -F ':' '{print$2}'`
  hammerHealthCheck=$(hammerPing)
  echo -e "\033[1;33mPlease make sure manually, that proxy is removed by using the commands 'unset http_proxy' and 'unset https_proxy'.\n\033[0m"
  if [ "$hammerHealthCheck" == "good" ]; then
    echo -e "\n------------------- Enabled Respositories Product Details -------------------\n"
    hammer product list --organization "$satOrgName" --enabled yes
    echo -e "\n"
    read -p "Press Enter to proceed with repository synchronization: " ans5;
    for id in $(hammer product list --organization "$satOrgName" --enabled yes | grep "$satOrgName" | awk '{print$1}');
    do
      hammer product synchronize --organization "$satOrgName" --id $id --async
    done
    echo -e "\n\033[0;32m---------------- Satellite repos sync started successfully... ----------------\n\033[0m"
    echo -e "\033[1;33mRun command 'watch hammer product list --organization $satOrgName --enabled yes' to check sync status...\n\033[0m"
    else echo -e "\033[0;31mSatellite in bad health...!!! Please resolve...\n\033[0m"
  fi
  ./configureSatellite.sh

######### [8] Manage Content View..
elif [ "$option" == "8" ];then
  echo -e "\033[1;33mPlease make sure manually, that proxy is removed by using the commands 'unset http_proxy' and 'unset https_proxy'.\n\033[0m"
  . addtnlFiles/manageContentView.sh $MNGCONTVSHPATH
  echo -e "\n\033[0;32m------------------- Content view modified successfully... --------------------\n\033[0m"
  ./configureSatellite.sh
  
######### [9] Revert satellite to fresh install.
elif [ "$option" == "9" ];then
  echo -e "\033[0;31mWarning...!!! This will delete all satellite configuration...\n\033[0m"
  read -p "Type 'confirm' to reset satellite, else press any other key to skip: " resetConfirm;
  if [ "$resetConfirm" == "confirm" ] ;then
    sudo satellite-installer --reset -v
    sudo yum remove satellite -y
    sudo katello-remove -y
    sudo subscription-manager unregister
    if [ -f "proxy" ]; then
      rm -f ~/scriptsSatl/proxy
    fi
    echo -e "\n\033[0;32m------------ Satellite reverted to fresh install successfully... -------------\n\033[0m"
  else echo -e "Skipping............\n"
  fi
  ./configureSatellite.sh

######### [0] EXIT...
elif [ "$option" == "0" ];then
  echo -e "Exiting............\n"

######### Invalid Choice
else echo -e "\033[0;31mInvalid choice...!!! Running script again...\n\033[0m"
  ./configureSatellite.sh
fi

