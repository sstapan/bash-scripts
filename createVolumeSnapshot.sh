#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-12-21 ######
##################################################################################
vmName=""
vmState=""
volDetails=""
volId=""
volName=""
source ~/stlrc
echo -e "\nEnter the UUID of the VM."
read vmId;
vmName=`openstack server show $vmId -c name -f value`
echo ""
openstack server stop $vmId
while [ "$vmState" != "SHUTOFF" ]
do
  vmState=`openstack server show $vmId -c status -f value`
  echo -e "Current VM state: $vmState"
  continue
done
volDetails=`openstack volume list | grep -i os_ | egrep -i "$vmName|$vmId"`
volId=`echo $volDetails | awk '{print $2}'`
volName=`echo $volDetails | awk '{print $4}'`
openstack volume set --state available $volId
echo -e "\n\n---------- Creating Snapshot for the volume ----------\n"
openstack volume snapshot create --volume $volId $volName-snap
sleep 10
echo -e "\n\n---------- Available Volume Snapshots ----------\n"
openstack volume snapshot list
echo -e "\nWant to power on the VM:"
read ans;
openstack volume set --state in-use $volId
if [ "$ans" == "yes" ] ;then
  openstack server start $vmId
  while [ "$vmState" != "ACTIVE" ]
  do
    vmState=`openstack server show $vmId -c status -f value`
    echo -e "Current VM state: $vmState"
    continue
  done
fi
echo -e "\n\nEXITING..........\n"