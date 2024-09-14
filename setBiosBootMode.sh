#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-07-31 ######
##################################################################################
racadm -r $1 -u root -p password get iDRAC.NIC.DNSRacName | grep DNSRacName | awk -F"=" '{print $2}'
echo "$1"
bmode=$(racadm -r $1 -u root -p password get bios.BiosBootSettings.BootMode | grep -i bootmode)
echo $bmode
echo -e "Changing BootMode for $1 to \"$2\"...\n"
racadm -r $1 -u root -p password set bios.BiosBootSettings.BootMode $2
racadm -r $1 -u root -p password jobqueue create BIOS.Setup.1-1 -r pwrcycle
