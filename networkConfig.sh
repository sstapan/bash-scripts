#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.2 | Date Modified: 2022-02-04 ######
##################################################################################

######### Declaring variables
CPATH="/etc/sysconfig/network-scripts"
#CPATH="/root/test"
int1=""
int2=""
bond=""
br=""
vlan=""
ip=""
pf=""
gw=""
tgint=""

echo -e "\n###############################################\n############ Network Configuration ############\n###############################################\n"
echo -e "Select the type of configuration,\n\n[1] Interface Configuration without IP\n[2] IP Configuration over an interface\n[3] IP Configuration over a tagged interface\n[4] IP Configuration over a bridge over an interface\n[5] IP Configuration over a tagged bridge over an interface\n[6] IP Configuration over a bridge over bond with two interfaces\n[7] IP Configuration over a tagged bridge over bond with two interfaces\n[8] \033[0;34mExit the Script\033[0m\n"
read cnftype;

###### [1] Interface Configuration without IP
if [ "$cnftype" == "1" ];then
  echo "Enter interface name:"
  read int1;
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int1"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int1
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int1
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int1
    echo "NAME=$int1" >> $CPATH/ifcfg-$int1
    echo "DEVICE=$int1" >> $CPATH/ifcfg-$int1
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int1
    systemctl restart NetworkManager
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsNode/addtnlScripts/networkConfig.sh

###### [2] IP Configuration over an interface
elif [ "$cnftype" == "2" ];then
  echo "Enter interface name:"
  read int1;
  echo "Enter ip for the above interface:"
  read ip;
  echo "Enter prefix for the above interface:"
  read pf;
  echo "Enter gateway for the above interface:"
  read gw;
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int1 $ip $pf $gw"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int1
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int1
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int1
    echo "NAME=$int1" >> $CPATH/ifcfg-$int1
    echo "DEVICE=$int1" >> $CPATH/ifcfg-$int1
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int1
    echo "USERCTL=no" >> $CPATH/ifcfg-$int1
    echo "IPADDR=$ip" >> $CPATH/ifcfg-$int1
    echo "PREFIX=$pf" >> $CPATH/ifcfg-$int1
    echo "GATEWAY=$gw" >> $CPATH/ifcfg-$int1
    systemctl restart NetworkManager
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsNode/addtnlScripts/networkConfig.sh

###### [3] IP Configuration over a tagged interface
elif [ "$cnftype" == "3" ];then
  echo "Enter interface name:"
  read int1;
  echo "Enter vlan to be tagged to above interface:"
  read vlan;
  echo "Enter ip for the above tagged interface:"
  read ip;
  echo "Enter prefix for the above tagged interface:"
  read pf;
  echo "Enter gateway for the above tagged interface:"
  read gw;
  tgint="$int1.$vlan"
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int1 $vlan $tgint $ip $pf $gw"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int1 $CPATH/ifcfg-$tgint
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int1
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int1
    echo "NAME=$int1" >> $CPATH/ifcfg-$int1
    echo "DEVICE=$int1" >> $CPATH/ifcfg-$int1
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int1
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$tgint
    echo "BOOTPROTO=none" >> $CPATH/ifcfg-$tgint
    echo "NAME=$tgint" >> $CPATH/ifcfg-$tgint
    echo "DEVICE=$tgint" >> $CPATH/ifcfg-$tgint
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$tgint
    echo "VLAN=yes" >> $CPATH/ifcfg-$tgint
    echo "IPADDR=$ip" >> $CPATH/ifcfg-$tgint
    echo "PREFIX=$pf" >> $CPATH/ifcfg-$tgint
    echo "GATEWAY=$gw" >> $CPATH/ifcfg-$tgint
    systemctl restart NetworkManager
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsNode/addtnlScripts/networkConfig.sh

###### [4] IP Configuration over a bridge over an interface
elif [ "$cnftype" == "4" ];then
  echo "Enter interface name:"
  read int1;
  echo "Enter bridge name over the above interface:"
  read br;
  echo "Enter ip for the above bridge:"
  read ip;
  echo "Enter prefix for the above bridge:"
  read pf;
  echo "Enter gateway for the above bridge:"
  read gw;
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int1 $br $ip $pf $gw"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int1 $CPATH/ifcfg-$br
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int1
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int1
    echo "NAME=$int1" >> $CPATH/ifcfg-$int1
    echo "DEVICE=$int1" >> $CPATH/ifcfg-$int1
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int1
    echo "BRIDGE=$br" >> $CPATH/ifcfg-$int1
    echo "TYPE=Bridge" > $CPATH/ifcfg-$br
    echo "BOOTPROTO=none" >> $CPATH/ifcfg-$br
    echo "DEVICE=$br" >> $CPATH/ifcfg-$br
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$br
    echo "IPADDR=$ip" >> $CPATH/ifcfg-$br
    echo "PREFIX=$pf" >> $CPATH/ifcfg-$br
    echo "GATEWAY=$gw" >> $CPATH/ifcfg-$br
    systemctl restart NetworkManager
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsNode/addtnlScripts/networkConfig.sh

###### [5] IP Configuration over a tagged bridge over an interface
elif [ "$cnftype" == "5" ];then
  echo "Enter interface name:"
  read int1;
  echo "Enter bridge name over the above interface:"
  read br;
  echo "Enter vlan to be tagged to above bridge:"
  read vlan;
  echo "Enter ip for the above tagged interface:"
  read ip;
  echo "Enter prefix for the above tagged interface:"
  read pf;
  echo "Enter gateway for the above tagged interface:"
  read gw;
  tgint="$br.$vlan"
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int1 $br $vlan $tgint $ip $pf $gw"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int1 $CPATH/ifcfg-$br $CPATH/ifcfg-$tgint
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int1
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int1
    echo "NAME=$int1" >> $CPATH/ifcfg-$int1
    echo "DEVICE=$int1" >> $CPATH/ifcfg-$int1
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int1
    echo "BRIDGE=$br" >> $CPATH/ifcfg-$int1
    echo "TYPE=Bridge" > $CPATH/ifcfg-$br
    echo "BOOTPROTO=none" >> $CPATH/ifcfg-$br
    echo "DEVICE=$br" >> $CPATH/ifcfg-$br
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$br
    echo "BOOTPROTO=none" > $CPATH/ifcfg-$tgint
    echo "NAME=$tgint" >> $CPATH/ifcfg-$tgint
    echo "DEVICE=$tgint" >> $CPATH/ifcfg-$tgint
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$tgint
    echo "VLAN=yes" >> $CPATH/ifcfg-$tgint
    echo "IPADDR=$ip" >> $CPATH/ifcfg-$tgint
    echo "PREFIX=$pf" >> $CPATH/ifcfg-$tgint
    echo "GATEWAY=$gw" >> $CPATH/ifcfg-$tgint
    systemctl restart NetworkManager
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsNode/addtnlScripts/networkConfig.sh

###### [6] IP Configuration over a bridge over bond with two interfaces
elif [ "$cnftype" == "6" ];then
  echo "Enter interface 1 name:"
  read int1;
  echo "Enter interface 2 name:"
  read int2;
  echo "Enter bond name over above interfaces:"
  read bond;
  echo "Enter bridge name over the above bond:"
  read br;
  echo "Enter ip for the above bridge:"
  read ip;
  echo "Enter prefix for the above bridge:"
  read pf;
  echo "Enter gateway for the above bridge:"
  read gw;
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int1 $int2 $bond $br $ip $pf $gw"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int1 $CPATH/ifcfg-$int2 $CPATH/ifcfg-$bond $CPATH/ifcfg-$br
    echo -e "\nConfiguring Network for a tagged bridge over bond with two interfaces.\n"
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int1
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int1
    echo "NAME=$int1" >> $CPATH/ifcfg-$int1
    echo "DEVICE=$int1" >> $CPATH/ifcfg-$int1
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int1
    echo "USERCTL=no" >> $CPATH/ifcfg-$int1
    echo "MASTER=$bond" >> $CPATH/ifcfg-$int1
    echo "SLAVE=yes" >> $CPATH/ifcfg-$int1
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int2
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int2
    echo "NAME=$int2" >> $CPATH/ifcfg-$int2
    echo "DEVICE=$int2" >> $CPATH/ifcfg-$int2
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int2
    echo "USERCTL=no" >> $CPATH/ifcfg-$int2
    echo "MASTER=$bond" >> $CPATH/ifcfg-$int2
    echo "SLAVE=yes" >> $CPATH/ifcfg-$int2
    echo "TYPE=Bond" > $CPATH/ifcfg-$bond
    echo "BOOTPROTO=none" >> $CPATH/ifcfg-$bond
    echo "NAME=$bond" >> $CPATH/ifcfg-$bond
    echo "DEVICE=$bond" >> $CPATH/ifcfg-$bond
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$bond
    echo "USERCTL=no" >> $CPATH/ifcfg-$bond
    echo "BONDING_MASTER=yes" >> $CPATH/ifcfg-$bond
    echo -e "BONDING_OPTS=\"miimon=100 mode=4 lacp_rate=1\"" >> $CPATH/ifcfg-$bond
    echo "BRIDGE=$br" >> $CPATH/ifcfg-$bond
    echo "TYPE=Bridge" > $CPATH/ifcfg-$br
    echo "BOOTPROTO=none" >> $CPATH/ifcfg-$br
    echo "DEVICE=$br" >> $CPATH/ifcfg-$br
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$br
    echo "IPADDR=$ip" >> $CPATH/ifcfg-$br
    echo "PREFIX=$pf" >> $CPATH/ifcfg-$br
    echo "GATEWAY=$gw" >> $CPATH/ifcfg-$br
    systemctl restart NetworkManager
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsNode/addtnlScripts/networkConfig.sh

###### [7] IP Configuration over a tagged bridge over bond with two interfaces
elif [ "$cnftype" == "7" ];then
  echo "Enter interface 1 name:"
  read int1;
  echo "Enter interface 2 name:"
  read int2;
  echo "Enter bond name over above interfaces:"
  read bond;
  echo "Enter bridge name over the above bond:"
  read br;
  echo "Enter vlan to be tagged to above bridge:"
  read vlan;
  echo "Enter ip for the above tagged interface:"
  read ip;
  echo "Enter prefix for the above tagged interface:"
  read pf;
  echo "Enter gateway for the above tagged interface:"
  read gw;
  tgint="$br.$vlan"
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int1 $int2 $bond $br $vlan $tgint $ip $pf $gw"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int1 $CPATH/ifcfg-$int2 $CPATH/ifcfg-$bond $CPATH/ifcfg-$br $CPATH/ifcfg-$tgint
    echo -e "\nConfiguring Network for a tagged bridge over bond with two interfaces.\n"
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int1
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int1
    echo "NAME=$int1" >> $CPATH/ifcfg-$int1
    echo "DEVICE=$int1" >> $CPATH/ifcfg-$int1
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int1
    echo "USERCTL=no" >> $CPATH/ifcfg-$int1
    echo "MASTER=$bond" >> $CPATH/ifcfg-$int1
    echo "SLAVE=yes" >> $CPATH/ifcfg-$int1
    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int2
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int2
    echo "NAME=$int2" >> $CPATH/ifcfg-$int2
    echo "DEVICE=$int2" >> $CPATH/ifcfg-$int2
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int2
    echo "USERCTL=no" >> $CPATH/ifcfg-$int2
    echo "MASTER=$bond" >> $CPATH/ifcfg-$int2
    echo "SLAVE=yes" >> $CPATH/ifcfg-$int2
    echo "TYPE=Bond" > $CPATH/ifcfg-$bond
    echo "BOOTPROTO=none" >> $CPATH/ifcfg-$bond
    echo "NAME=$bond" >> $CPATH/ifcfg-$bond
    echo "DEVICE=$bond" >> $CPATH/ifcfg-$bond
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$bond
    echo "USERCTL=no" >> $CPATH/ifcfg-$bond
    echo "BONDING_MASTER=yes" >> $CPATH/ifcfg-$bond
    echo -e "BONDING_OPTS=\"miimon=100 mode=4 lacp_rate=1\"" >> $CPATH/ifcfg-$bond
    echo "BRIDGE=$br" >> $CPATH/ifcfg-$bond
    echo "TYPE=Bridge" > $CPATH/ifcfg-$br
    echo "BOOTPROTO=none" >> $CPATH/ifcfg-$br
    echo "DEVICE=$br" >> $CPATH/ifcfg-$br
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$br
    echo "BOOTPROTO=none" > $CPATH/ifcfg-$tgint
    echo "NAME=$tgint" >> $CPATH/ifcfg-$tgint
    echo "DEVICE=$tgint" >> $CPATH/ifcfg-$tgint
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$tgint
    echo "VLAN=yes" >> $CPATH/ifcfg-$tgint
    echo "IPADDR=$ip" >> $CPATH/ifcfg-$tgint
    echo "PREFIX=$pf" >> $CPATH/ifcfg-$tgint
    echo "GATEWAY=$gw" >> $CPATH/ifcfg-$tgint
    systemctl restart NetworkManager
  else echo -e "\nRestarting Script...\n"
  fi
  . ~/scriptsNode/addtnlScripts/networkConfig.sh

###### [8] Exit the Script
elif [ "$cnftype" == "8" ];then
  echo "Exiting............"

###### Invalid Choice
else echo "Invalid Choice, running script again"
  . ~/scriptsNode/addtnlScripts/networkConfig.sh
fi
