#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.1 | Date Modified: 2021-07-28 ######
##################################################################################
echo ""
echo "Get PXE MAC Address for Nodes..."
echo ""
echo "[1] Controller"
echo "[2] Storage"
echo "[3] Compute"
echo "[4] EXIT..."
echo ""
echo "Select the desired option."
read option;
if [ $option -eq 1 ];then
  rm /root/TK/macPXE/bash-macPXEctrl 2> /dev/null
  rm temp 2> /dev/null
  while read line; do
    ctrname=$(racadm -r $line -u root -p m4venir2! get iDRAC.NIC.DNSRacName | grep DNSRacName | awk -F"=" '{print $2$3}')
    macadd=$(racadm -r $line -u root -p m4venir2! hwinventory nic | grep NIC.Integrated.1-1-1 | awk '{print $7}')
    echo -e "$ctrname\t\t\t$macadd\t\t\t\t\t\t$line"
    echo -e "$ctrname  \t\t$macadd\t\t$line" >> temp
  done < "/root/TK/ipPlan/controller"
  tr -d '\r' < temp > /root/TK/macPXE/bash-macPXEctrl
  . /root/TK/addtnlScripts/getPXEmac-v1.0.1.sh
elif [ $option -eq 2 ];then
  rm /root/TK/macPXE/bash-macPXEstrg 2> /dev/null
  rm temp 2> /dev/null
  while read line; do
    strname=$(racadm -r $line -u root -p m4venir2! get iDRAC.NIC.DNSRacName | grep DNSRacName | awk -F"=" '{print $2}')
    macadd=$(racadm -r $line -u root -p m4venir2! hwinventory nic | grep NIC.Integrated.1-1-1 | awk '{print $7}')
    echo -e "$strname\t\t\t$macadd\t\t\t\t\t\t$line"
    echo -e "$strname  \t\t$macadd\t\t$line" >> temp
  done < "/root/TK/ipPlan/storage"
  tr -d '\r' < temp > /root/TK/macPXE/bash-macPXEstrg
  . /root/TK/addtnlScripts/getPXEmac-v1.0.1.sh
elif [ $option -eq 3 ];then
  rm /root/TK/macPXE/bash-macPXEcomp 2> /dev/null
  rm temp 2> /dev/null
  while read line; do
    cmpname=$(racadm -r $line -u root -p m4venir2! get iDRAC.NIC.DNSRacName | grep DNSRacName | awk -F"=" '{print $2}')
    macadd=$(racadm -r $line -u root -p m4venir2! hwinventory nic | grep NIC.Integrated.1-1-1 | awk '{print $7}')
    echo -e "$cmpname\t\t\t$macadd\t\t\t\t\t\t$line"
    echo -e "$cmpname  \t\t$macadd\t\t$line" >> temp
  done < "/root/TK/ipPlan/compute"
  tr -d '\r' < temp > /root/TK/macPXE/bash-macPXEcomp
  . /root/TK/addtnlScripts/getPXEmac-v1.0.1.sh
elif [ $option -eq 4 ];then
  rm temp 2> /dev/null
  echo "Exiting............"  
else echo "Invalid Choice, running script again"
  . /root/TK/addtnlScripts/getPXEmac-v1.0.1.sh
fi
