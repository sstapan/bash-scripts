#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-10-12 ######
##################################################################################
tag=""
satelliteHn=`cat nodeDetails | grep SatellitePrefix | awk -F '=' '{print $2}'`
containerPf=`cat nodeDetails | grep ContainerImagesPrefix | awk -F '=' '{print $2}'`
#satelliteHn="enetsat01.enetworks.gy"
#containerPf="enetwork-enet-rhosp16-2_0-osp16_1_containers"
echo -e "\n##########################################\n############ Podman Pull Test ############\n##########################################"
echo -e "\n[1] Pull Container images\n[2] Delete all container images\n\033[0;34m[3] EXIT...\033[0m\n"
echo "Select the desired option."
read option;

###### [1] Pull Container images
if [ "$option" == "1" ];then
  echo -e "\nEnter the path for the file containing satellite images:"
  read satImgPath
  echo -e "\nEnter the tag for the satellite images:"
  read tag
  while read IMAGE
  do
    IMAGENAME=$(echo $IMAGE | cut -d"/" -f2 | sed "s/openstack-//g" | sed "s/:.*//g")
    podman pull $satelliteHn:5000/$containerPf-$IMAGENAME:$tag
  done < $satImgPath
  podman pull $satelliteHn:5000/$containerPf-rhceph-4-rhel8:latest
  echo -e "\n\033[0;32m---------- Container Images pulled as below ----------\n\033[0m"
  podman images --all
  podCount=`podman images --all | grep -v IMAGE | wc -l`
  echo -e "\nNo. of podman images: $podCount\n" 
  . ~/scriptsDIRXstack/podmanPullTest.sh

###### [2] Delete all container images
elif [ "$option" == "2" ];then
  for pod in $(podman images --all | awk '{print $3}' | grep -v IMAGE); do podman rmi $pod ; done
  echo -e "\n\033[0;32m---------- All Container Images deleted, output as below ----------\n\033[0m"
  podman images --all
  echo ""
  . ~/scriptsDIRXstack/podmanPullTest.sh

###### [3] EXIT...
elif [ "$option" == "3" ];then
  echo "Exiting............"

###### Invalid Choice
else echo -e "Invalid Choice, running script again\n"
  . ~/scriptsDIRXstack/podmanPullTest.sh
fi
