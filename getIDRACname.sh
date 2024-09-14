#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-07-31 ######
##################################################################################
echo "View iDRAC.NIC.DNSRacName"
echo ""
echo "[1] Controller"
echo "[2] Storage"
echo "[3] Compute"
echo "[4] EXIT..."
echo ""
echo "Select the desired option."
read option;
if [ $option -eq 1 ];then
  while read line; do
    echo "Controller IP: $line"
    racadm -r $line -u root -p password get iDRAC.NIC.DNSRacName | grep DNSRac
    echo ""
    let "a+=1"
  done < "/root/TK/ipPlan/controller"
  ./getIDRACname.sh
elif [ $option -eq 2 ];then
  while read line; do
    echo "Storage IP: $line"
    racadm -r $line -u root -p password get iDRAC.NIC.DNSRacName | grep DNSRac
    echo ""
    let "b+=1"
  done < "/root/TK/ipPlan/storage"
  ./getIDRACname.sh
elif [ $option -eq 3 ];then
  while read line; do
    echo "Compute IP: $line"
    racadm -r $line -u root -p password get iDRAC.NIC.DNSRacName | grep DNSRac
    echo ""
    let "c+=1"
  done < "/root/TK/ipPlan/compute"
  ./getIDRACname.sh
elif [ $option -eq 4 ];then
  echo "Exiting............"  
else echo "Invalid Choice, running script again"
  ./getIDRACname.sh
fi
