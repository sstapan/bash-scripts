#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-11-12 ######
##################################################################################
compName=''
compIp=''
for comp in cmps01 cmps02
do
compName=`openstack server list -c Name -c Networks | egrep -i $comp | awk '{print $2}'`
compIp=`openstack server list -c Name -c Networks | egrep -i $comp | awk '{print $4}' | awk -F"=" '{print $2}'`
echo "$compName"
ssh heat-admin@$compIp "sudo podman exec -it nova_libvirt virsh list --all | grep inst | cut -d ' ' -f 6-7" > temp
for inst in $(cat temp); do echo $inst; ssh heat-admin@$compIp "sudo podman exec -it nova_libvirt virsh dommemstat $inst"; done
done
rm -f temp