#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-07-31 ######
##################################################################################
racadm -r $1 -u root -p m4venir2! get iDRAC.NIC.DNSRacName | grep DNSRacName | awk -F"=" '{print $2}'
echo "$1"
prec=$(racadm -r $1 -u root -p m4venir2! get bios.SysSecurity.AcPwrRcvry | grep -i AcPwr)
echo $prec
echo -e "Changing AC Power Recovery for $1 to \"$2\"...\n"
racadm -r $1 -u root -p m4venir2! set bios.SysSecurity.AcPwrRcvry $2
racadm -r $1 -u root -p m4venir2! jobqueue create BIOS.Setup.1-1 -r pwrcycle
