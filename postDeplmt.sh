#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.2 | Date Modified: 2021-09-23 ######
##################################################################################
source /home/stack/overcloudrc
sudo chown stack:stack /home/stack/scriptsDIRXstack/*
sudo chown stack:stack /home/stack/scriptsDIRXstack/addtnlScriptsDIRXstack/*
sudo chmod +x /home/stack/scriptsDIRXstack/addtnlScriptsDIRXstack/*.sh
echo -e "\n##############################################\n######### Post Deployment Activities #########\n##############################################\n"
echo -e "[1] Create Alias for Overcloud Nodes\n[2] Cinder Changes\n[3] Create Networks/Subnets\n[4] Create Flavors\n[5] Create overcloud images\n[6] Create Cloud Users/Projects/Roles and change Quota\n[7] Create Availability Zones\n[8] Basic Sanity Test\n\033[0;34m[9] EXIT...\033[0m\n"
echo "Select the desired option."
read option;

###### [1] Create Alias for Overcloud Nodes
if [ "$option" == "1" ];then
  . ~/scriptsDIRXstack/addtnlScriptsDIRXstack/createAlias.sh
  echo -e "\n\033[0;32m---------- Alias Created Successfully ----------\n\033[0m"
  source ~/.bashrc
  . ~/scriptsDIRXstack/postDeplmt.sh
  
###### [2] Cinder Changes
elif [ "$option" == "2" ];then
  cinder --os-username admin --os-tenant-name admin type-create volumes_ceph
  cinder type-key volumes_ceph set volume_backend_name=tripleo_ceph
  cinder --os-username admin --os-tenant-name admin type-create volumes_ssd
  cinder type-key volumes_ssd set volume_backend_name=tripleo_ceph_volumes_ssd
  cinder type-key tripleo set volume_backend_name=tripleo_ceph
  cinder extra-specs-list
  echo -e "\n\033[0;32m---------- Cinder Changes Completed Successfully ----------\n\033[0m"
  . ~/scriptsDIRXstack/postDeplmt.sh

###### [3] Create Networks/Subnets
elif [ "$option" == "3" ];then
  echo -e "Enter the file name containing network details with full path like '/home/stack/scriptsDIRXstack/addtnlFilesDIRXstack/addtnlPostDepFiles/EPC.txt'"
  read nwDetailsFullPath
  echo -e "\nIf you have input the correct values in above mentioned file, type 'yes' to proceed further or 'no' to exit."
  read ans1;
  if [ "$ans1" == "yes" ] ;then
    echo "Available Networks List"
    echo "-----------------------------------------------------------------------------------------------"
    echo "Network-Name            VLAN            IPv4/IPv6       Network/Prefix          Gateway"
    echo "-----------------------------------------------------------------------------------------------"
    cat $nwDetailsFullPath
    echo "-----------------------------------------------------------------------------------------------"
        echo -e "\nConfirm Networks (yes/no)"
    read ans2;
    if [ "$ans2" == "yes" ] ;then
      . ~/scriptsDIRXstack/addtnlScriptsDIRXstack/netSubnetCreate.sh $nwDetailsFullPath
      echo -e "\n\033[0;32m---------- Desired Networks/Subnets Created Successfully ----------\n\033[0m"
    else echo -e "\nRestarting Script...\n"
    fi
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsDIRXstack/postDeplmt.sh


###### [4] Create Flavors
elif [ "$option" == "4" ];then
  echo -e "Enter the file name containing flavor details with full path like '/home/stack/scriptsDIRXstack/addtnlFilesDIRXstack/addtnlPostDepFiles/flavorList.txt'"
  read flavorDetailsFullPath
  echo -e "\nIf you have input the correct values in above mentioned file, type 'yes' to proceed further or 'no' to exit."
  read ans3;
  if [ "$ans3" == "yes" ] ;then
    . ~/scriptsDIRXstack/addtnlScriptsDIRXstack/flavorSelect.sh $flavorDetailsFullPath
    echo -e "\n\033[0;32m---------- Desired Flavors Created Successfully ----------\n\033[0m"
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsDIRXstack/postDeplmt.sh

###### [5] Create overcloud images
elif [ "$option" == "5" ];then
  echo -e "\nEnter qcow2 image full path and image name sperated by space, press ENTER for next value, and type 'EXIT' only if there is no further input..."
  condtn=1
  while [ "$condtn" == "1" ]
  do
    read line
    if [ "$line" == "EXIT" ];then
      condtn=0
      break;
    fi
    echo $line >> imageList.txt
  done
  imagepath=""
  imagename=""
  while read line
  do
    declare -i x=1
    for word in $line
	do
      if [ $x -eq 1 ];then
        imagepath=$word
      elif [ $x -eq 2 ];then
        imagename=$word
      else
        echo "fatal error check text file probable there is an additional space or extra entries"
      fi
      x+=1
    done
    virt-customize -a $imagepath --root-password password:mavenir
    openstack image create --disk-format qcow2 --container-format bare --public --file $imagepath $imagename
  done  < imageList.txt
  rm -f imageList.txt
  echo -e "\n\033[0;32m---------- Desired Overcloud Images Created Successfully ----------\n\033[0m"
  . ~/scriptsDIRXstack/postDeplmt.sh

###### [6] Create Cloud Users/Projects/Roles and change Quota
elif [ "$option" == "6" ];then
  . ~/scriptsDIRXstack/addtnlScriptsDIRXstack/createCloudUsrProjQuota.sh
  echo -e "\n\033[0;32m---------- Desired Cloud Users/Projects/Roles Created and Quota Changed Successfully ----------\n\033[0m"
  . ~/scriptsDIRXstack/postDeplmt.sh

###### [7] Create Availability Zones
elif [ "$option" == "7" ];then
  HOSTSEL="/home/stack/scriptsDIRXstack/addtnlFilesDIRXstack/addtnlPostDepFiles/hosts.txt"
  rm $HOSTSEL 2> /dev/null
  touch $HOSTSEL
  openstack hypervisor list -c "Hypervisor Hostname" -f value | egrep -i 'cmps|com' | sort >> $HOSTSEL
  declare -i x=1
  while read line
  do
    agg="comp$x"
	openstack aggregate create --zone $agg $agg
	openstack aggregate add host $agg $line
    x+=1
  done < $HOSTSEL
  echo -e "\n\033[0;32m---------- Desired Availability Zones Successfully ----------\n\033[0m"
  echo -e "\n---------- Availability Zones Available ----------\n"
  openstack aggregate list
  openstack availability zone list
  echo ""
  . ~/scriptsDIRXstack/postDeplmt.sh
  
###### [8] Basic Sanity Test
elif [ "$option" == "8" ];then
  . ~/scriptsDIRXstack/addtnlScriptsDIRXstack/basicSanity.sh
  echo -e "\n\033[0;32m---------- Desired Networks/Subnets Created Successfully ----------\n\033[0m"
  . ~/scriptsDIRXstack/postDeplmt.sh

###### [9] EXIT...
elif [ "$option" == "9" ];then
  echo "Exiting............"  

###### Invalid Choice
else echo "Invalid Choice, running script again"
  . ~/scriptsDIRXstack/postDeplmt.sh
fi
