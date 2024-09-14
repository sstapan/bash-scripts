#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2022-04-10 ######
##################################################################################
#set -x
SPATH="$1"

######### Declare variables
lceName=''
lceDes=''
satOrgName=''
actKey=''
actKeyRelVer=''
contentView=''
contentViewDes=''
contentViewVer=''
contentViewVerDes=''
satIp1=''
satIp2=''
filterName=''
filterType=''
filterIncl=''
filterDes=''
filterErrEndDate=''
containerPf=''


######### Getting Input
satOrgName=`hammer organization list | awk 'NR==4' | awk '{print$5}'`

echo -e "\n#########################################\n########## Manage Content View ##########\n#########################################\n"
echo -e "[1] Create Lifecysle Environment.\n[2] Manage Activation Key.\n[3] Create Content View.\n[4] Publish new version of Content View to Lifecycle Envirnment.\n[5] Create filters for Content View.\n[6] Promote version of Content View to Lifecycle Envirnment.\n[7] Get Satellite Registration Details.\n[0] EXIT from this MENU...\033[0m\n"
read -p "Select the desired option: " option;
echo ""

######### [1] Create Lifecysle Environment.
if [ "$option" == "1" ];then
  read -p "Enter the lifecylce environment name: " lceName;
  read -p "Enter the lifecylce environment description: " lceDes;
  hammer lifecycle-environment create --name "$lceName" --label "$lceName" --description "$lceDes" --prior "Library" --organization "$satOrgName"
  echo -e "\n\033[0;32m------------- Lifecycle environment created successfully... -------------\n\033[0m"
  . $SPATH/manageContentView.sh

######### [2] View/Edit Satellite Details / Register to Red Hat.
elif [ "$option" == "2" ];then
  read -p "Create new activation key (y/n): " ans1;
  if [ "$ans1" == "y" ] || [ "$ans1" == "yes" ]; then
    read -p "Enter Activation Key Name: " actKey;
    read -p "Enter Activation Key Release Version: " actKeyRelVer;
    hammer activation-key create --name "$actKey" --organization "$satOrgName"
    hammer activation-key update --name "$actKey" --organization "$satOrgName" --release-version "$actKeyRelVer"
    echo -e "\n\033[0;32m---------------- Activation Key created successfully... -----------------\n\033[0m"
  else
    read -p "Edit Activation Key Content Details (y/n): " ans2
    if [ "$ans2" == "y" ] || [ "$ans2" == "yes" ]; then
      echo -e "\nAvailable Activation Keys...\n"
      hammer activation-key list --organization "$satOrgName"
      echo ""
      read -p "Enter Activation Key Name: " actKey;
      echo -e "\nAvailable Lifecycle Environment...\n"
      hammer lifecycle-environment list --organization "$satOrgName"
      echo ""
      read -p "Enter Lifecycle Environment Name for above Activation Key: " lceName;
      hammer activation-key update --name "$actKey" --organization "$satOrgName" --lifecycle-environment "$lceName"
      echo -e "\nAvailable Content View Versions...\n"
      hammer content-view version list --organization "$satOrgName"
      echo ""
      read -p "Enter Content View promtoted to above environment, to attach to above Activation Key: " contentView;
      hammer activation-key update --name "$actKey" --organization "$satOrgName" --content-view "$contentView"
      echo -e "\nOverriding 'Red Hat Satellite Tools 6.9 for RHEL 8 x86_64 (RPMs)' repo to 'Enabled' by default...\n"
      hammer activation-key content-override --value 1 --name "$actKey" --content-label "satellite-tools-6.9-for-rhel-8-x86_64-rpms" --organization "$satOrgName"
      echo -e "\n\033[0;32m---------------- Activation Key modified successfully... ----------------\n\033[0m"
    fi
  fi
  . $SPATH/manageContentView.sh

######### [3] Create Content View.
elif [ "$option" == "3" ];then
  read -p "Enter Content View Name: " contentView;
  read -p "Enter Content View Decription: " contentViewDes;
  hammer content-view create --name "$contentView" --label "$contentView" --description "$contentViewDes" --organization "$satOrgName"
  echo -e "\nAdding below all yum repositories to above content view...\n"
  hammer repository list --content-type yum --organization "$satOrgName" | awk -F"|" '{print $1 $2 $4}'
  echo ""
  for repo in $(hammer repository list --content-type yum --organization "$satOrgName" | grep yum | awk -F"|" '{print $1}'); do hammer content-view add-repository --name "$contentView" --organization "$satOrgName" --repository-id "$repo"; done
  echo ""
  echo -e "\nAdding below all docker repositories to above content view...\n"
  hammer repository list --content-type docker --organization "$satOrgName" | awk -F"|" '{print $1 $2 $4}'
  echo ""
  for repo in $(hammer repository list --content-type docker --organization "$satOrgName" | grep docker | awk -F"|" '{print $1}'); do hammer content-view add-repository --name "$contentView" --organization "$satOrgName" --repository-id "$repo"; done
  echo ""
  echo -e "\nFollowing Content View Versions are available...\n"
  hammer content-view version list --organization "$satOrgName"
  echo -e "\n\033[0;32m----------------- Content View created successfully... ------------------\n\033[0m"
  . $SPATH/manageContentView.sh

######### [4] Publish new version of Content View to Lifecycle Envirnment.
elif [ "$option" == "4" ];then
  echo -e "Available Content View...\n"
  hammer content-view version list --organization "$satOrgName"
  echo ""
  read -p "Enter Content View Name to be published: " contentView;
  read -p "Enter Content View Version Description for above Content View: " contentViewVerDes;
  echo ""
  read -p "Continue to publish version for the above content view to 'Library' environment by default (y/n): " ans3;
  if [ "$ans3" == "y" ] || [ "$ans3" == "yes" ]; then
    echo ""
    hammer content-view publish --name "$contentView" --description "$contentViewVerDes" --organization "$satOrgName"
  fi
  echo -e "\n\033[0;32m---------------- Content View published successfully... -----------------\n\033[0m"
  . $SPATH/manageContentView.sh

######### [5] Create filters for Content View.
elif [ "$option" == "5" ];then
  echo -e "Available Content View...\n"
  hammer content-view version list --organization "$satOrgName"
  echo ""
  read -p "Enter Content View Name: " contentView;
  read -p "Enter filter name: " filterName;
  read -p "Enter filter description: " filterDes;
  read -p "Filter inclusion 'yes' or 'no': " filterIncl;
  read -p "Enter filter type (can be one of rpm, package_group, erratum, docker, deb, modulemd): " filterType;
  hammer content-view filter create --organization "$satOrgName" --content-view "$contentView" --name "$filterName" --type "$filterType" --inclusion "$filterIncl" --description "$filterDes"
  echo ""
  if [ "$filterType" == "erratum" ]; then
    read -p "Enter errata filter end date (yyyy-mm-dd): " filterErrEndDate;
    hammer content-view filter rule create --organization "$satOrgName" --content-view "$contentView" --content-view-filter "$filterName" --end-date "$filterErrEndDate" --types security,enhancement,bugfix --date-type updated
  fi
  if [ "$filterType" == "rpm" ]; then
    echo -e "\033[1;33mPlease manually update this filter from GUI to tick 'Include all RPMs with no errata.'\033[0m"
  fi
  echo -e "\n\033[0;32m-------------- Content View filter created successfully... --------------\n\033[0m"
  . $SPATH/manageContentView.sh

######### [6] Promote version of Content View to Lifecycle Envirnment.
elif [ "$option" == "6" ];then
  echo -e "Available Content View Versions...\n"
  hammer content-view version list --organization "$satOrgName"
  echo ""
  read -p "Enter Content View Name to be promoted: " contentView;
  echo -e "\nAvailable Lifecycle Environments...\n"
  hammer lifecycle-environment list --organization "$satOrgName"
  echo ""
  read -p "Enter Lifecycle Environment Name to have above content view promoted to: " lceName;
  hammer content-view show --name "$contentView" --organization "$satOrgName" --fields Name,Description,"Lifecycle Environments",Versions,"Activation Keys"
  read -p "Enter Content View Version to promote to above Lifecycle Environment: " contentViewVer;
  hammer content-view version promote --content-view "$contentView" --version "$contentViewVer" --organization "$satOrgName" --to-lifecycle-environment "$lceName"
  echo -e "\n\033[0;32m----------------- Content View promoted successfully... -----------------\n\033[0m"
  . $SPATH/manageContentView.sh

######### [7] Get Satellite Registration Details.
elif [ "$option" == "6" ];then
  satOrgName=`hammer organization list | awk 'NR==4' | awk '{print$5}'`
  satIp1=`ip a | grep inet | grep global | grep -oP '(?<=inet ).*(?=/)' | head -1`
  satIp2=`ip a | grep inet | grep global | grep -oP '(?<=inet ).*(?=/)' | tail -1`
  satFQDN=`hostname`
  echo "-------------------------------------------------"
  echo -e "\nSatellite Organization Name: $satOrgName"
  echo -e "Satellite IPs: $satIp1, $satIp2"
  echo -e "Satellite FQDN: $satFQDN"
  echo "-------------------------------------------------"
  echo -e "\nActivation Key Details...\n"
  hammer activation-key list --organization "$satOrgName"
  echo -e "\nContent View  Details...\n"
  hammer content-view version list --organization "$satOrgName"
  echo -e "\nLifecycle Environment Details...\n"
  hammer lifecycle-environment list --organization "$satOrgName"
  echo -e "\nTo get container prefix details, go to GUI > Content View > Version > Docker Repositories..."
  . $SPATH/manageContentView.sh

######### [0] EXIT from this MENU...
elif [ "$option" == "0" ];then
  echo -e "Exiting............\n"
  echo -e "\n\033[0;32m--------------------- Returning back to Main Menu... --------------------\n\033[0m"

######### Invalid Choice
else echo -e "\033[0;31mInvalid choice...!!! Running script again...\n\033[0m"
  . $SPATH/manageContentView.sh
fi

