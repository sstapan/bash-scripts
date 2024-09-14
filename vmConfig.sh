#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.2 | Date Modified: 2022-02-13 ######
##################################################################################

######### Declaring variables
nodeIf=''
nodeIp=''
nodePf=''
nodeGw=''
nodeVl=''
nodeHostname=''
fqdn=''
nodeFQDN=''
intProvPool=''
ntpIP1=''
ntpIP2=''
satIp=''
satFQDN=''
satHostname=''
satOrg=''
satActKey=''
subsAttach=''
rhelVer=''
growPart=''
option=''
nrUser=''
nrUserPass=''
sudoCh=''
rhelVer=`cat /etc/os-release | grep BUGZILLA_PRODUCT_VERSION | awk -F"=" '{print$2}' | awk -F"." '{print$1}'`

######### Getting Input
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
    satIp=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 7 ];then
    satFQDN=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 8 ];then
    satOrg=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 9 ];then
    satActKey=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 10 ];then
    subsAttach=`echo $line | awk -F"=" '{print $2}'`
  else
    echo -e "fatal error, check \"nodeDetails\" file and verify..."
  fi
  x+=1
done < nodeDetails

nodeFQDN="$nodeHostname.$fqdn"
#echo "$nodeHostname $fqdn $intProvPool $ntpIP1 $ntpIP2 $satIp $satFQDN $satOrg $satActKey"

echo -e "\n##############################################################"
echo "###################### VM Configuration ######################"
echo "##############################################################"
echo -e "\n[1] Network Configuration.\n[2] Increase Size of Disk Partitions.\n[3] Change Hostname.\n[4] Set NTP and Timezone.\n[5] Satellite Registration.\n[6] Install required packages and update all packages.\n[7] Create a non-root user.\n\033[0;34m[0] Exit...\033[0m\n"
echo -e "\033[1;33mBefore proceeding any further, please make sure all details are correctly filled in 'nodeDetails'\033[0m\n"
read -p "Select the desired option: " option;


###### [1] Network Configuration.
if [ "$option" == "1" ];then
  echo -e "\nEnter interface name:"
  read nodeIf;
  echo "Vlan tagging with IP to interface / IP to interface / Other ('vlan' / 'ip' / 'other':"
  read ans;
  rm -f /etc/sysconfig/network-scripts/ifcfg-$nodeIf*
  echo -e "\nConfiguring Network Interface $nodeIf..."
  echo "DEVICE=$nodeIf" > /etc/sysconfig/network-scripts/ifcfg-$nodeIf
  echo "BOOTPROTO=none" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf
  echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf
  echo "TYPE=Ethernet" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf
  if [ "$ans" == "vlan" ];then
    echo -e "\nEnter interface vlan:"
    read nodeVl;
    echo "Enter IP:"
    read nodeIp;
    echo "Enter Prefix:"
    read nodePf;
    echo "Enter Gateway:"
    read nodeGw;
    echo "DEVICE=$nodeIf.$nodeVl" > /etc/sysconfig/network-scripts/ifcfg-$nodeIf.$nodeVl
    echo "BOOTPROTO=none" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf.$nodeVl
    echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf.$nodeVl
    echo "VLAN=yes" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf.$nodeVl
    echo "IPADDR=$nodeIp" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf.$nodeVl
    echo "PREFIX=$nodePf" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf.$nodeVl
    echo "GATEWAY=$nodeGw" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf.$nodeVl
  elif [ "$ans" == "ip" ];then
    echo "Enter IP:"
    read nodeIp;
    echo "Enter Prefix:"
    read nodePf;
    echo "Enter Gateway:"
    read nodeGw;
    echo "IPADDR=$nodeIp" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf
    echo "PREFIX=$nodePf" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf
    echo "GATEWAY=$nodeGw" >> /etc/sysconfig/network-scripts/ifcfg-$nodeIf
  fi
  if [ "$rhelVer" == "8" ];then
    systemctl restart NetworkManager
    sudo ln -sf /dev/null /etc/systemd/system/cloud-init.service
  else
    systemctl stop NetworkManager
    systemctl disable NetworkManager
    systemctl mask NetworkManager
    systemctl restart network
    systemctl stop cloud-init
    systemctl disable cloud-init
    systemctl mask cloud-init
  fi
  sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  sudo sed -i "/UseDNS/c\UseDNS no" /etc/ssh/sshd_config
  systemctl reload sshd
  echo -e "\n\033[0;32m------------ Network Configured Successfully... ------------\n\033[0m\n"
  ./vmConfig.sh

###### [2] Increase Size of Disk Partitions.
elif [ "$option" == "2" ];then
  growPart=`lsblk | grep -w "part /" | awk '{print$1}' | awk -F"└─" '{print$2}'`
  xfs_growfs /dev/$growPart
  echo -e "\n\033[0;32m--------- Partition Size Increased Successfully... ---------\n\033[0m\n"
  ./vmConfig.sh
  
###### [3] Change Hostname.
elif [ "$option" == "3" ];then
  hostnamectl set-hostname $nodeFQDN 
  hostnamectl set-hostname --transient $nodeFQDN
  echo -e "\n\033[0;32m--------------- Hostname Set Successfully... ---------------\n\033[0m\n"
  ./vmConfig.sh

###### [4] Set NTP and Timezone.
elif [ "$option" == "4" ];then
  echo -e "\nNo. of NTP IPs (1/2):"
  read ntpct;
  if [ "$ntpct" == "1" ];then
    sed -i "/rhel.pool.ntp.org/c\server $ntpIP1 iburst minpoll 6 maxpoll 10\nbindcmdaddress 127.0.0.1\nbindcmdaddress ::1\nallow $intProvPool" /etc/chrony.conf
  elif [ "$ntpct" == "2" ];then
    sed -i "/rhel.pool.ntp.org/c\server $ntpIP1 prefer prefer iburst\nserver $ntpIP2 iburst\nbindcmdaddress 127.0.0.1\nbindcmdaddress ::1\nallow $intProvPool" /etc/chrony.conf
  else
    echo -e "\033[0;31mInvalid choice...!!! Running script again...\n\033[0m"
    ./serverSetup.sh
  fi
  systemctl restart chronyd.service
  sleep 5s
  echo -e "\n############### NTP Service ###############\n"
  chronyc sources
  echo -e "\nSelect Timezone:\na. IST\nb. UTC"
  read tz;
  if [ "$tz" == "a" ];then
    rm -f /etc/localtime
    timedatectl set-timezone Asia/Kolkata
    echo -e "\n############### timedatectl ###############\n"
    timedatectl
    echo -e "\n\033[0;32m------- Desired Timezone and NTP Set Successfully... -------\n\033[0m\n"
  elif [ "$tz" == "b" ];then
    echo -e "\nEnter timezone place (continent/city):"
    read tzone;
    ln -sf /usr/share/zoneinfo/$tzone  /etc/localtime
    echo -e "\n############### timedatectl ###############\n"
    timedatectl
    echo -e "\n\033[0;32m------- Desired Timezone and NTP Set Successfully... -------\n\033[0m\n"
  else
    echo -e "\033[0;31mInvalid choice...!!! Running script again...\n\033[0m"
  fi
  ./vmConfig.sh

###### [5] Satellite Registration.
elif [ "$option" == "5" ];then
  echo -e "\nPress any key to continue...\n"
  read inp;
  satHostname=`echo $satFQDN | awk -F '.' '{print$1}'`
  desEtcHosts=$(echo "$satIp $satFQDN $satHostname")
  etcHosts=$(cat /etc/hosts | grep $satIp)
  if [ "$etcHosts" == "$desEtcHosts" ];then
    echo "Host entry exists for satellite in /etc/hosts file."
  else
    sudo echo $desEtcHosts >>/etc/hosts
    echo "Host entry added for satellite in /etc/hosts file as below,"
    cat /etc/hosts | grep $satIP
  fi
  echo -e "\n------ Cleaning all satellite data, if exists... ------\n"
  sudo yum clean all
  sudo subscription-manager remove --all
  sudo subscription-manager unregister
  sudo subscription-manager clean
  sudo dnf remove -y katello-ca-consumer-*
  if [ ! -d "/etc/yum.repos.d/old" ]; then
    `sudo mkdir /etc/yum.repos.d/old`
  fi
  sudo mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/old/
  echo -e "\n------ All satellite data cleaned... ------\n\n--------------------------------------------------\nRegistering to satellite with below details,\n"
  cat nodeDetails | grep Satellite
  echo "--------------------------------------------------"
  echo -e "\nPress any key to continue..."
  read inp2;
  echo -e "\n------ Installing katello-ca-consumer rpm... ------\n"
  sudo rpm -Uvh http://$satFQDN/pub/katello-ca-consumer-latest.noarch.rpm
  sudo subscription-manager register --org="$satOrg" --activationkey="$satActKey" --force
  sudo subscription-manager release --set=8.2
  echo -e "\n------ Disabling all repos... ------\n"
  sudo subscription-manager repos --disable=*
  echo -e "\n------ Enabling only required repos... ------\n"
  sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-eus-rpms --enable=rhel-8-for-x86_64-appstream-eus-rpms --enable=rhel-8-for-x86_64-highavailability-eus-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=openstack-16.1-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=advanced-virt-for-rhel-8-x86_64-rpms --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms
  sudo subscription-manager release --set=8.2
  subsPool=`sudo subscription-manager list --available --matches "$subsAttach" | grep Pool | awk -F ':' '{print$2}' | awk -F ' ' '{print$1}' | head -1`
  sudo subscription-manager attach --pool=$subsPool 
  sudo dnf module disable -y container-tools:rhel8
  sudo dnf module enable -y container-tools:2.0
  sudo dnf module disable -y virt:rhel
  sudo dnf module enable -y virt:8.2
  echo -e "\n\033[0;32m--------- Registered to Satellite Successfully... ----------\n\033[0m"
  ./vmConfig.sh

###### [6] Install required packages and update all packages.
elif [ "$option" == "6" ];then
  echo -e "\nEnter the name of packages to be installed (space-seperated):"
  read pkgs;
  sudo dnf install -y sshpass $pkgs
  sudo dnf update -y
  echo -e "\n\033[0;32m----------- Installed packages & Updated all... -----------\n\033[0m\n"
  ./vmConfig.sh

###### [7] Create a non-root user.
elif [ "$option" == "7" ];then
  echo ""
  read -p "Enter the name of non-root user: " nrUser;
  read -p "Enter the password for above user: " nrUserPass;
  useradd $nrUser
  echo $nrUserPass | passwd --stdin $nrUser
  echo ""
  read -p "Make above user sudoer (y/n): " sudoCh;
  if [ "$sudoCh" == "y" ] || [ "$sudoCh" == "yes" ]; then
    echo "$nrUser ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/$nrUser
    chmod 0440 /etc/sudoers.d/$nrUser
  fi
  echo -e "\n\033[0;32m---------- Created non-root user Successfully... -----------\n\033[0m\n"
  ./vmConfig.sh

###### [0] EXIT...
elif [ "$option" == "0" ];then
  echo -e "\nExiting............\n"

###### Invalid Choice
else echo -e "\033[0;31mInvalid choice...!!! Running script again...\n\033[0m"
  ./vmConfig.sh
fi
