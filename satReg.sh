#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.1 | Date Modified: 2022-02-12 ######
##################################################################################
DETAILSPATH="addtnlFiles/satDetails"
DETAILSPATH="$1"

satIP=''
satFQDN=''
satHostname=''
satOrg=''
satActKey=''
subsAttach=''
subsPool=''

declare -i x=1
while read line
do
  if [ $x -eq 1 ];then
    satIP=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 2 ];then
    satFQDN=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 3 ];then
    satHostname=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 4 ];then
    satOrg=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 5 ];then
    satActKey=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 6 ];then
    subsAttach=`echo $line | awk -F"=" '{print $2}'`
  else
    echo -e "fatal error check \"satDetails\" file and verify..."
  fi
  x+=1
done < $DETAILSPATH
echo -e "\n##############################################################"
echo "########## Welcome to Satellite Registration Script ##########"
echo "##############################################################"
echo -e "\nPress any key to continue..."
read inp1;
desEtcHosts=$(echo "$satIP $satFQDN $satHostname")
etcHosts=$(cat /etc/hosts | grep $satIP)
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
cat $DETAILSPATH
echo "--------------------------------------------------"
echo -e "\nPress any key to continue..."
read inp2;
echo -e "\n------ Installing katello-ca-consumer rpm... ------\n"
sudo rpm -Uvh http://$satFQDN/pub/katello-ca-consumer-latest.noarch.rpm
echo -e "\n\n------ Registering to satellite... ------\n"
sudo subscription-manager register --org="$satOrg" --activationkey="$satActKey" --force
echo -e "\n------ Disabling all repos... ------\n"
sudo subscription-manager repos --disable=*
echo -e "\n\n------ Enabling only required repos... ------\n"
sudo subscription-manager repos --enable=rhel-8-for-x86_64-baseos-eus-rpms --enable=rhel-8-for-x86_64-appstream-eus-rpms --enable=rhel-8-for-x86_64-highavailability-eus-rpms --enable=ansible-2.9-for-rhel-8-x86_64-rpms --enable=openstack-16.1-for-rhel-8-x86_64-rpms --enable=fast-datapath-for-rhel-8-x86_64-rpms --enable=advanced-virt-for-rhel-8-x86_64-rpms --enable=rhceph-4-tools-for-rhel-8-x86_64-rpms
echo ""
sudo subscription-manager release --set=8.2
echo ""
subsPool=`sudo subscription-manager list --available --matches "$subsAttach" | grep Pool | awk -F ':' '{print$2}' | awk -F ' ' '{print$1}' | head -1`
sudo subscription-manager attach --pool=$subsPool 
echo ""
sudo dnf module disable -y container-tools:rhel8
echo ""
sudo dnf module enable -y container-tools:2.0
echo ""
sudo dnf module disable -y virt:rhel
echo ""
sudo dnf module enable -y virt:8.2