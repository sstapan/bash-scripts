#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.1 | Date Modified: 2021-09-22 ######
##################################################################################
set -x
myscript="$1"
int=""
for i in dpdk0
do
if [ "$i" == "sriovnet0" ];then
  int="ens2f0"
elif [ "$i" == "sriovnet1" ];then
  int="ens2f1"
elif [ "$i" == "sriovnet2" ];then
  int="ens3f0"
elif [ "$i" == "sriovnet3" ];then
  int="ens3f1"
elif [ "$i" == "sriovnet4" ];then
  int="eno5"
elif [ "$i" == "sriovnet5" ];then
  int="ens1f1"
else int="$i"
fi

while read  line; do 
echo $line
name=$(echo $line | awk -F"|" '{print $1}'| sed 's/ //g')
vlan=$(echo $line | awk -F"|" '{print $2}'| sed 's/ //g')
vtype=$(echo $line | awk -F"|" '{print $3}'| sed 's/ //g')
cidr=$(echo $line | awk -F"|" '{print $4}'| sed 's/ //g')
gw=$(echo $line | awk -F"|" '{print $5}'| sed 's/ //g')
openstack network create net_${name}_${vlan}_${int} --provider-physical-network $i --provider-network-type vlan --provider-segment $vlan --share --external
openstack subnet create net_${name}_${vlan}_${int}_subnet --network net_${name}_${vlan}_${int} --ip-version $vtype  --no-dhcp  --subnet-range $cidr --gateway $gw
done < $myscript
done
