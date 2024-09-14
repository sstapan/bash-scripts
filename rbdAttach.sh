#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-12-03 ######
##################################################################################
cephPoolName=`cat rbdDetails | grep cephPool | awk -F "=" '{print $2}' |awk -F "/" '{print $1}'`
cephUser=`cat rbdDetails | grep cephPool | awk -F "=" '{print $2}' | awk -F "/" '{print $2}'`
keyringName=`cat rbdDetails | grep keyringName | awk -F "=" '{print $2}'`
rbdSize=`cat rbdDetails | grep rbdSize | awk -F "=" '{print $2}'`
rbdSecretXmlName=`cat rbdDetails | grep rbdSecretXmlName | awk -F "=" '{print $2}'`
rbdDeviceXmlName=`cat rbdDetails | grep rbdDeviceXmlName | awk -F "=" '{print $2}'`
cephMonIp1=`cat rbdDetails | grep cephMonIps | awk -F "=" '{print $2}' | awk -F "," '{print $1}'`
cephMonIp2=`cat rbdDetails | grep cephMonIps | awk -F "=" '{print $2}' | awk -F "," '{print $2}'`
cephMonIp3=`cat rbdDetails | grep cephMonIps | awk -F "=" '{print $2}' | awk -F "," '{print $3}'`
rbdUuid=""
rbdKey=""
echo -e "\n\033[0;31m!!!!!!!!!! WARNING: Before proceeding further, make sure respective ceph pool is created and its keyring is placed in '/etc/ceph/' and all details are correct in 'rbdDetails' file... !!!!!!!!!!\n\033[0m"
echo -e "\n---------- RBD Details ----------\n"
cat rbdDetails
echo -e "\nAre you sure you want to continue (yes/no)?"
read ans;
if [ "$ans" == "yes" ] ;then
  if [ ! -d "/root/ceph" ]; then
    `sudo mkdir /root/ceph`
  fi
  echo -e "\n---------- Checking ceph status and health ----------\n"
  CEPH_ARGS="--keyring /etc/ceph/$keyringName --id $cephUser"
  export CEPH_ARGS
  ceph -s
  cephHealthStatus=`ceph health detail`
  if [ "$cephHealthStatus" == "HEALTH_OK" -o "$cephHealthStatus" == "HEALTH_OK" ] ;then
    echo -e "\n---------- Creating rbd volume ----------\n"
    rbd create $cephPoolName/$cephUser --size=$rbdSize
    echo "<secret ephemeral='no' private='no'>" > /root/ceph/$rbdSecretXmlName
    echo "  <usage type='ceph'>" >> /root/ceph/$rbdSecretXmlName
    echo -e "  <name>client.$cephUser secret</name>" >> /root/ceph/$rbdSecretXmlName
    echo "  </usage>" >> /root/ceph/$rbdSecretXmlName
    echo "</secret>" >> /root/ceph/$rbdSecretXmlName
    virsh secret-define --file /root/ceph/$rbdSecretXmlName
    rbdUuid=`virsh secret-list | grep $cephUser | awk '{print $1}'`
    rbdKey=`grep key /etc/ceph/$keyringName | awk '{print $3}'`
    virsh secret-set-value --secret $rbdUuid --base64 $rbdKey
    echo "    <disk type='network' device='disk'>" > /root/ceph/$rbdDeviceXmlName
    echo "      <driver name='qemu'/>" >> /root/ceph/$rbdDeviceXmlName
    echo -e "      <auth username='$cephUser'>" >> /root/ceph/$rbdDeviceXmlName
    echo -e "        <secret type='ceph' uuid='$rbdUuid'/>" >> /root/ceph/$rbdDeviceXmlName
    echo "      </auth>" >> /root/ceph/$rbdDeviceXmlName
    echo -e "      <source protocol='rbd' name='$cephPoolName/$cephUser'>" >> /root/ceph/$rbdDeviceXmlName
    echo -e "        <host name='$cephMonIp1' port='6789'/>" >> /root/ceph/$rbdDeviceXmlName
    echo -e "        <host name='$cephMonIp2' port='6789'/>" >> /root/ceph/$rbdDeviceXmlName
    echo -e "        <host name='$cephMonIp3' port='6789'/>" >> /root/ceph/$rbdDeviceXmlName
    echo "      </source>" >> /root/ceph/$rbdDeviceXmlName
    echo "      <target dev='vdb' bus='virtio'/>" >> /root/ceph/$rbdDeviceXmlName
    echo "    </disk>" >> /root/ceph/$rbdDeviceXmlName
  else echo -e "\n\033[0;31mCeph Health degraded, please resolve before trying again...\n\033[0m"
  fi
  #echo "$cephPoolName $cephUser $keyringName $cephHealthStatus $rbdSize $rbdSecretXmlName $rbdDeviceXmlName $cephMonIp1 $cephMonIp2 $cephMonIp3 $rbdUuid $rbdKey"
  echo -e "\n---------- Available VMs ----------\n"
  virsh list --all
  echo -e "\nEnter which VM to attach rbd to?"
  read vm;
  virsh attach-device $vm /root/ceph/$rbdDeviceXmlName --persistent
else echo -e "\nExiting........\n"
fi
