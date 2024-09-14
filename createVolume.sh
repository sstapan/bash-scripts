#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-09-23 ######
##################################################################################
source /home/stack/overcloudrc
while read line
do
  volname=`echo $line | awk '{print $1}'`
  volsize=`echo $line | awk '{print $2}'`
  openstack volume create --size $volsize $volname
done < $1