#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-07-31 ######
##################################################################################
racadm -r $1 -u root -p m4venir2! get iDRAC.NIC.DNSRacName | grep DNSRacName | awk -F"=" '{print $2}'
echo "$1"
sprf=$(racadm -r $1 -u root -p m4venir2! get bios.SysProfileSettings.SysProfile | grep -i SysProfile=)
echo $sprf
