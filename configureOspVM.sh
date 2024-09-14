#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.1.0 | Date Modified: 2021-11-18 ######
##################################################################################
CPATH="/etc/sysconfig/network-scripts"
nodeHostname=''
fqdn=''
nodeFQDN=''
intProvPool=''
ntpIP1=''
ntpIP2=''
dirxIp=''
satPf=''
option=''
int=''
vlan=''
ip=''
pf=''
gw=''
tgint=''
cp ospDetails ~/
declare -i x=1
while read line
do
  if [ $x -eq 1 ];then
    nodeHostname=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 2 ];then
    fqdn=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 3 ];then
    intProvPool=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 4 ];then
    ntpIP1=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 5 ];then
    ntpIP2=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 6 ];then
    dirxIp=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 7 ];then
    satPf=`echo $line | awk -F"=" '{print $2}'`
  else
    echo -e "fatal error, check \"nodeDetails\" file and verify..."
  fi
  x+=1
done < ~/ospDetails
nodeFQDN="$nodeHostname.$fqdn"
oamint="ifcfg-eth1.$nodeVl"
USERINFO="/root/scriptsOsp/user-info.txt"
if [ ! -f "$USERINFO" ]; then
  `touch $USERINFO`
fi
rm $USERINFO 2> /dev/null
echo -e "\n##############################################################"
echo "################# Ospclient VM Configuration #################"
echo "##############################################################"
echo -e "\n[1] Network Configuration.\n[2] Change Hostname and mount rbd volume.\n[3] Satellite Registration.\n[4] Set NTP and Timezone.\n[5] Update all packages.\n[6] Install rquired packages.\n[7] Create osp users, and modify rc files.\n[8] Exit."
echo -e "\nSelect the desired option."
read option;

#### [1] Network Configuration
if [ "$option" == "1" ];then
  echo "Enter interface name:"
  read int;
  echo -e "Enter vlan (or \033[1;33mna\033[0m if Not Applicable) to be tagged to above interface:"
  read vlan;
  echo -e "Enter ip (or \033[1;33mna\033[0m if Not Applicable) for the above tagged interface:"
  read ip;
  echo "Enter prefix for the above tagged interface:"
  read pf;
  echo "Enter gateway for the above tagged interface:"
  read gw;
  tgint="$int.$vlan"
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int $vlan $tgint $ip $pf $gw"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int $CPATH/ifcfg-$tgint
	echo 'TYPE="Ethernet"' > $CPATH/ifcfg-$int
    echo 'BOOTPROTO="none"' >> $CPATH/ifcfg-$int
    echo "NAME=$int" >> $CPATH/ifcfg-$int
    echo "DEVICE=$int" >> $CPATH/ifcfg-$int
    echo 'ONBOOT="yes"' >> $CPATH/ifcfg-$int
	if [ "$vlan" != "na" ] ;then
	  echo 'TYPE="Ethernet"' > $CPATH/ifcfg-$tgint
      echo 'BOOTPROTO="none"' >> $CPATH/ifcfg-$tgint
      echo "DEVICE=$tgint" >> $CPATH/ifcfg-$tgint
      echo 'ONBOOT="yes"' >> $CPATH/ifcfg-$tgint
	  echo 'VLAN="yes"' >> $CPATH/ifcfg-$tgint
      echo "IPADDR=$ip" >> $CPATH/ifcfg-$tgint
      echo "PREFIX=$pf" >> $CPATH/ifcfg-$tgint
      echo "GATEWAY=$gw" >> $CPATH/ifcfg-$tgint
	fi
  systemctl restart NetworkManager
  else echo -e "\nRestarting Script...\n"
  fi
  systemctl restart NetworkManager
  ./configureOspVM.sh
  
#### [2] Change Hostname and mount rbd volume
elif [ "$option" == "2" ];then
  xfs_growfs /dev/vda3
  hostnamectl set-hostname $nodeFQDN 
  hostnamectl set-hostname --transient $nodeFQDN
  sed -i "/127.0.0.1/c\127.0.0.1   $nodeFQDN $nodeHostname" /etc/hosts
  mkfs.xfs /dev/vdb
  echo "/dev/vdb /home/                       xfs     defaults        0 0" >> /etc/fstab
  mount -a
  df -h
  ./configureOspVM.sh
  
#### [3] Satellite Registration
elif [ "$option" == "3" ];then
  ./satReg.sh
  ./configureOspVM.sh
  
#### [4] Set NTP and Timezone
elif [ "$option" == "4" ];then
  echo -e "\nNo. of NTP IPs (1/2):"
  read ntpct;
  if [ "$ntpct" == "1" ];then
    sed -i "/rhel.pool.ntp.org/c\server $ntpIP1 iburst minpoll 6 maxpoll 10\nbindcmdaddress 127.0.0.1\nbindcmdaddress ::1\nallow $intProvPool" /etc/chrony.conf
  elif [ "$ntpct" == "2" ];then
    sed -i "/rhel.pool.ntp.org/c\server $ntpIP1 iburst\nserver $ntpIP2 iburst\nbindcmdaddress 127.0.0.1\nbindcmdaddress ::1\nallow $intProvPool" /etc/chrony.conf
  else 
    echo "Invalid Choice, running script again"
    ./configureOspVM.sh
  fi
  systemctl restart  chronyd.service
  echo -e "\n############### NTP Service ###############\n"
  chronyc sources
  echo -e "\nSelect Timezone:\na. IST\nb. UTC"
  read tz;
  if [ "$tz" == "a" ];then
    rm -f /etc/localtime
    timedatectl set-timezone Asia/Kolkata
  elif [ "$tz" == "b" ];then
    ln -sf /usr/share/zoneinfo/Europe/Prague  /etc/localtime
  else
    echo "Invalid Choice, running script again"
    ./configureOspVM.sh
  fi
  echo -e "\n############### timedatectl ###############\n"
  timedatectl
  ./configureOspVM.sh
  
#### [5] Update all packages
elif [ "$option" == "5" ];then
  echo -e "\n#################### Updating all packages... ####################\n"
  sudo dnf update -y
  ./configureOspVM.sh
  
#### [6] Install rquired packages
elif [ "$option" == "6" ];then
  echo -e "\n#################### Installing the following packages... ####################\n"
  cat reqPackages
  while read line1; do
    pkg=`echo $line1 | awk -F"." '{print $2}'`
    echo -e "\n##############################################################################\n"
    sudo dnf install -y $pkg
  done < reqPackages
  ./configureOspVM.sh
  
#### [7] Create osp users, and modify rc files
elif [ "$option" == "7" ];then
  sshpass -p "stack" scp -r stack@$dirxIp:/home/stack/overcloudrc /root/scriptsOsp/
  rcname="rc"
  echo ""
  echo "Enter users names to be created seperated by space."
  read line;
  echo ""
  echo "Selected Users/Password/rc-file"
  echo "---------------------------------------------"
  echo "User             Password        rc-file"
  echo "---------------------------------------------"
  declare -i x=1
  for user in $line
  do
  filename="$user$rcname"
  echo -e "$user \t\t $user \t\t $filename"
  x+=1
  done
  echo "---------------------------------------------"
  echo ""
  echo "Confirm Users Details (yes/no)"
  read ans;
  if [ "$ans" == "yes" ] ;then
  declare -i y=1
  for userf in $line
  do
  useradd $userf
  echo $userf | passwd --stdin $userf
  filename="$userf$rcname"
  cp /root/scriptsOsp/overcloudrc /root/scriptsOsp/$filename
  sed -i '/export OS_PASSWORD=/c\export OS_PASSWORD=mavenir' /root/scriptsOsp/$filename
  sed -i "s/overcloud/${userf}/g" /root/scriptsOsp/$filename
  sed -i "s/admin/${userf}/g" /root/scriptsOsp/$filename
  chown $userf:$userf /root/scriptsOsp/$filename
  mv /root/scriptsOsp/$filename /home/$userf
  cat /home/$userf/$filename | egrep 'OS_USERNAME=|OS_CLOUDNAME=|OS_PASSWORD=|OS_PROJECT_NAME='
  y+=1
  done
  elif [ "$ans" == "no" ] ;then
  echo "Taking Back to Users Creation..."
  ./configureOspVM.sh
  else echo "Exiting..."
  fi
  
#### [8] Exit
elif [ "$option" == "8" ];then
  echo -e "Exiting............\n"
else echo -e "Invalid Choice, running script again\n"
  ./configureOspVM.sh
fi
rm -f ~/ospDetails
