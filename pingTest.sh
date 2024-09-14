#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2022-01-25 ######
##################################################################################

echo -e "\n###########################################################\n########## Ceph External Baremetal Configuration ##########\n###########################################################\n"

if [ ! -f "/root/details" ]; then
  echo -e "\nEnter the hostname (small letters) for the server:"
  read hname;
  echo -e "\nEnter the domain name:"
  read dn;
  hnameFQDN="$hname.$dn"
  echo -e "\nEnter satellite server internal IP:"
  read satIp;
  echo -e "\nEnter satellite server full hostname (small letters):"
  read satHname;
  echo -e "\nEnter satellite organization:"
  read satOrg;
  echo -e "\nEnter satellite activation key:"
  read satKey;
  echo -e "\nEnter ceph user name:"
  read cuser;
  echo -e "\nEnter osd names, space-seperated (sda sdb ...):"
  read osds;
  echo -e "\nEnter osd names, space-seperated to be used for journaling (sdo ...):"
  read osdsj;
  echo "Hostname:$hname" > /root/details
  echo "HostnameFQDN:$hnameFQDN" >> /root/details
  echo "SatelliteInternalIP:$satIp" >> /root/details
  echo "SatelliteHostname:$satHname" >> /root/details
  echo "SatelliteOrganization:$satOrg" >> /root/details
  echo "SatelliteActivationKey:$satKey" >> /root/details
  echo "CephUser:$cuser" >> /root/details
  echo "CephOSDs:$osds" >> /root/details
  echo "CephOSDsJournaling:$osdsj" >> /root/details

else
  echo -e "---------- Following details are found ----------\n"
  cat /root/details
fi

echo -e "-------------------------------------------------\n"
echo -e "\033[1;33mPress 'r' to reset and re-enter above details, else press any other key to continue\033[0m"
read key;
if [ "$key" == "r" ] ;then
  rm -f /root/details
  ./cephExternalBaremetalSetup.sh
fi

echo -e "\n[1] Bond Configuration of Storage N/W / Storage Mgmt. N/W\n[2] Set Hostname and add host entry\n[3] Register to satellite\n[4] Install desired packages and update all\n[5] Set up NTP\n[6] Create and configure user\n[7] Create partitions in all Non-RAID disks\n[8] Reset and clear all Non-RAID disks\n\033[0;34m[9] EXIT...\033[0m\n"
echo "Select the desired option."
read option;

CPATH="/etc/sysconfig/network-scripts"
#CPATH="/root"

###### [1] Bond Configuration of Storage N/W / Storage Mgmt. N/W
if [ "$option" == "1" ];then
  echo "Enter interface 1 name:"
  read int1;
  echo "Enter interface 2 name:"
  read int2;
  echo "Enter bond name over above interfaces:"
  read bond;
  echo "Enter vlan to be tagged to above bond:"
  read vlan;
  echo "Enter ip for the above tagged interface:"
  read ip;
  echo "Enter prefix for the above tagged interface:"
  read pf;
  tgvlan="vlan$vlan"
  echo -e "\nDo you want to continue with the information entered as below (yes/no):\n$int1 $int2 $bond $vlan $tgvlan $ip $pf $gw"
  read ans;
  if [ "$ans" == "yes" ] ;then
    rm -f $CPATH/ifcfg-$int1 $CPATH/ifcfg-$int2 $CPATH/ifcfg-$bond $CPATH/ifcfg-$tgvlan
    echo -e "\nConfiguring Bond with above details...\n"

    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int1
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int1
    echo "NAME=$int1" >> $CPATH/ifcfg-$int1
    echo "DEVICE=$int1" >> $CPATH/ifcfg-$int1
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int1
    echo "USERCTL=no" >> $CPATH/ifcfg-$int1
    echo "MASTER=$bond" >> $CPATH/ifcfg-$int1
    echo "SLAVE=yes" >> $CPATH/ifcfg-$int1
    echo "MTU=9000" >> $CPATH/ifcfg-$int1

    echo "TYPE=Ethernet" > $CPATH/ifcfg-$int2
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$int2
    echo "NAME=$int2" >> $CPATH/ifcfg-$int2
    echo "DEVICE=$int2" >> $CPATH/ifcfg-$int2
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$int2
    echo "USERCTL=no" >> $CPATH/ifcfg-$int2
    echo "MASTER=$bond" >> $CPATH/ifcfg-$int2
    echo "SLAVE=yes" >> $CPATH/ifcfg-$int2
    echo "MTU=9000" >> $CPATH/ifcfg-$int2

    echo "TYPE=Bond" > $CPATH/ifcfg-$bond
    echo "BOOTPROTO=none" >> $CPATH/ifcfg-$bond
    echo "NAME=$bond" >> $CPATH/ifcfg-$bond
    echo "DEVICE=$bond" >> $CPATH/ifcfg-$bond
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$bond
    echo "IPV6_DISABLED=yes" >> $CPATH/ifcfg-$bond
    echo "BONDING_MASTER=yes" >> $CPATH/ifcfg-$bond
    echo -e "BONDING_OPTS=\"downdelay=100 miimon=1000 mode=802.3ad updelay=100\"" >> $CPATH/ifcfg-$bond
    echo "MTU=9000" >> $CPATH/ifcfg-$bond

    echo "TYPE=Vlan" > $CPATH/ifcfg-$tgvlan
    echo "NAME=$tgvlan" >> $CPATH/ifcfg-$tgvlan
    echo "BOOTPROTO=static" >> $CPATH/ifcfg-$tgvlan
    echo "DEFROUTE=yes" >> $CPATH/ifcfg-$tgvlan
    echo "ONBOOT=yes" >> $CPATH/ifcfg-$tgvlan
    echo "VLAN=yes" >> $CPATH/ifcfg-$tgvlan
    echo "PHYSDEV=$bond" >> $CPATH/ifcfg-$tgvlan
    echo "VLAN_ID=$vlan" >> $CPATH/ifcfg-$tgvlan
    echo "IPADDR=$ip" >> $CPATH/ifcfg-$tgvlan
    echo "PREFIX=$pf" >> $CPATH/ifcfg-$tgvlan
    systemctl restart NetworkManager
    echo -e "\n\033[0;32m---------- Bond configured for interfaces successfully ----------\n\033[0m"
  else echo -e "\nRestarting Script...\n"
  fi
  ./cephExternalBaremetalSetup.sh

###### [2] Set Hostname and add host entry
elif [ "$option" == "2" ];then
  hname=`cat /root/details | grep HostnameFQDN | awk -F ':' '{print$2}'`
  hostnamectl set-hostname $hname
  hostnamectl set-hostname --transient $hname
  echo -e "\nEnter the '/etc/hosts' entry, followed by EOT"
  read line
  while [ "$line" != "EOT" ];
  do
    echo $line >> /etc/hosts
    read line
  done
  echo -e "\n\033[0;32m---------- Hostname set and hostname entry modified successfully ----------\n\033[0m"
  ./cephExternalBaremetalSetup.sh

###### [3] Register to satellite
elif [ "$option" == "3" ];then
  satIP=`cat /root/details | grep SatelliteInternalIP | awk -F ':' '{print$2}'`
  satFQDN=`cat /root/details | grep SatelliteHostname | awk -F ':' '{print$2}'`
  satHostname=`cat /root/details | grep SatelliteHostname | awk -F ':' '{print$2}' | awk -F '.' '{print$1}'`
  satOrg=`cat /root/details | grep SatelliteOrganization | awk -F ':' '{print$2}'`
  satActKey=`cat /root/details | grep SatelliteActivationKey | awk -F ':' '{print$2}'`
  desEtcHosts=$(echo "$satIP $satFQDN $satHostname")
  etcHosts=$(cat /etc/hosts | grep $satIP)
  if [ "$etcHosts" == "$desEtcHosts" ];then
    echo -e "\nHost entry exists for satellite in \etc\hosts file."
  else
    sudo echo $desEtcHosts >>/etc/hosts
    echo -e "\nHost entry added for satellite in \etc\hosts file as below,"
    cat /etc/hosts | grep $satIP
  fi
  echo -e "\n------ Cleaning all satellite data, if exists... ------\n"
  sudo yum clean all
  sudo subscription-manager remove --all
  sudo subscription-manager unregister
  sudo subscription-manager clean
  sudo dnf remove -y katello-ca-consumer-*
  echo -e "\n------ All satellite data cleaned... ------\n\n\nRegistering to satellite with below details,\n"
  cat details | grep Satellite
  echo -e "-------------------------------------------\n\n"
  sudo rpm -Uvh http://$satFQDN/pub/katello-ca-consumer-latest.noarch.rpm
  sudo subscription-manager register --org="$satOrg" --activationkey="$satActKey" --force
  satPool=`sudo subscription-manager list --all --available --matches 'Red Hat Ceph Storage, Premium (Up to 256TB on a maximum of 12 Physical Nodes)' | grep Pool | awk -F ':' '{print$2}' | awk -F ' ' '{print$1}' | head -1`
  sudo subscription-manager attach --pool=$satPool
  sudo subscription-manager release --set=8.2
  echo -e "\n------ Disabling all repos... ------\n"
  sudo subscription-manager repos --disable=*
  echo -e "\n------ Enabling only required repos... ------\n"
  sudo subscription-manager repos --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=rhel-8-for-x86_64-appstream-eus-rpms --enable=rhel-8-for-x86_64-baseos-eus-rpms
  echo -e "\n\033[0;32m---------- Registered to satellite successfully ----------\n\033[0m"
  ./cephExternalBaremetalSetup.sh 

###### [4] Install desired packages and update all
elif [ "$option" == "4" ];then
  echo -e "Enter the name of packages to be installed seperated by space"
  read pkgs
  dnf install -y chrony $pkgs
  dnf update -y
  echo -e "\n\033[0;32m---------- Packages Installed and Updated Successfully ----------\n\033[0m"
  ./cephExternalBaremetalSetup.sh

###### [5] Set up NTP
elif [ "$option" == "5" ];then
  echo -e "\nEnter Utility Internal IP:"
  read utilIp;
  sed -i "/rhel.pool.ntp.org/c\server $utilIp iburst\nbindcmdaddress 127.0.0.1\nbindcmdaddress ::1" /etc/chrony.conf
  systemctl restart  chronyd.service
  echo -e "\n############### NTP Service ###############\n"
  chronyc sources
  timedatectl set-timezone Asia/Kolkata
  echo -e "\n############### timedatectl ###############\n"
  timedatectl
  echo -e "\n\033[0;32m---------- NTP IP set successfully ----------\n\033[0m"
  ./cephExternalBaremetalSetup.sh

###### [6] Create and configure user
elif [ "$option" == "6" ];then
  uname=`cat /root/details | grep CephUser | awk -F ':' '{print$2}'`
  useradd $uname
  echo $uname | passwd --stdin $uname
  echo "$uname ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/$uname
  chmod 0440 /etc/sudoers.d/mavadmin
  mkdir /home/$uname/ceph-ansible-keys
  chown $uname:$uname /home/$uname/ceph-ansible-keys
  echo -e "\n\033[0;32m---------- User created and configured successfully ----------\n\033[0m"
  ./cephExternalBaremetalSetup.sh

###### [7] Create partitions in all Non-RAID disks
elif [ "$option" == "7" ];then
  osds=`cat /root/details | grep CephOSDs: | awk -F ':' '{print$2}'`
  osdsj=`cat /root/details | grep CephOSDsJournaling | awk -F ':' '{print$2}'`
  osdsCount=`cat /root/details | grep CephOSDs: | awk '{print NF}'`
  let "osdsCountBy2=(osdsCount/2)" 
  let "osdsCountBy2Plus1=(osdsCountBy2+1)"
  for i in $osds; do echo $i; parted --script /dev/$i mklabel gpt; parted --script /dev/$i mkpart primary 1 100%; done
  for i in $osdsj; do echo $i; parted --script /dev/$i mklabel gpt; parted --script /dev/$i mkpart primary 1 100%; done
  for i in $osds; do echo $i; pvcreate /dev/${i}1; done
  for i in $osdsj; do echo $i; pvcreate /dev/${i}1; done
  j=0; for i in $osdsj; do let "j=(j+1)"; echo $i; vgcreate vg-cephdb-disk${j} /dev/${i}1; done
  for i in $(seq 1 $osdsCountBy2); do lvcreate -L 150g -n lv-cephdb-disk${i} vg-cephdb-disk1; done
  for i in $(seq $osdsCountBy2Plus1 $osdsCount); do lvcreate -L 150g -n lv-cephdb-disk${i} vg-cephdb-disk2; done
  j=0; for i in $osds; do let "j=(j+1)"; echo $i; vgcreate vg-cephdata-disk${j} /dev/${i}1; done
  for i in $(seq 1 $osdsCount); do lvcreate -l 100%FREE -n lv-cephdata-disk${i} vg-cephdata-disk${i}; done
  echo -e "\n\033[0;32m---------- All Non-RAID disks partitions ceated successfully ----------\n\033[0m"
  ./cephExternalBaremetalSetup.sh

###### [8] Reset and clear all Non-RAID disks
elif [ "$option" == "8" ];then
  echo -e "\nType 'delete' to confirm deletion:"
  read confirm;
  if [ "$confirm" == "delete" ];then
    osds=`cat /root/details | grep CephOSDs: | awk -F ':' '{print$2}'`
    osdsj=`cat /root/details | grep CephOSDsJournaling | awk -F ':' '{print$2}'`
    osdsCount=`cat /root/details | grep CephOSDs: | awk '{print NF}'`
    osdsjCount=`cat /root/details | grep CephOSDsJournaling | awk '{print NF}'`
    for i in $(seq 1 $osdsCount); do lvremove /dev/mapper/vg--cephdata--disk${i}-lv--cephdata--disk${i} -y; done
    for i in $(seq 1 $osdsCount); do vgremove vg-cephdata-disk${i}; done
    for i in $(seq 1 $osdsjCount); do vgremove vg-cephdb-disk${i} -y; done
    for i in $osds; do echo $i; pvremove /dev/${i}1; done
    for i in $osdsj; do echo $i; pvremove /dev/${i}1; done
    for i in $osds; do echo $i; wipefs -a /dev/${i}; done
    for i in $osdsj; do echo $i; wipefs -a /dev/${i}; done
    echo -e "\n\033[0;32m---------- Deleted and cleared all Non-RAID disks successfully ----------\n\033[0m"
  else echo -e "\n\033[0;31m---------- Canceled Deletion of Non-RAID disks ----------\n\033[0m"
  fi
  ./cephExternalBaremetalSetup.sh
  
###### [9] EXIT...
elif [ "$option" == "9" ];then
  echo "Exiting............"

###### Invalid Choice
else echo "Invalid Choice, running script again"
  ./cephExternalBaremetalSetup.sh
fi

