#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.1.0 | Date Modified: 2022-02-04 ######
##################################################################################

######### Declaring variables
rhelImgPath=''
rhelImgName=''
varImgName=''
kvmImgName=''
vmSize=''
vmMem=''
vmVcpus=''
osVariant=''
resizePart=''
vmBridges=''
vmName=''
brcount=''
brName=''
lineBridge=''
files=''

######### Getting Input
cp ~/scriptsNode/addtnlFiles/detailsVM ~/
declare -i x=1
while read line
do
  if [ $x -eq 1 ];then
    rhelImgPath=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 2 ];then
    rhelImgName=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 3 ];then
    varImgName=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 4 ];then
    kvmImgName=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 5 ];then
    vmSize=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 6 ];then
    vmMem=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 7 ];then
    vmVcpus=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 8 ];then
    osVariant=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 9 ];then
    resizePart=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 10 ];then
    vmBridges=`echo $line | awk -F"=" '{print $2}'`
  elif [ $x -eq 11 ];then
    vmName=`echo $line | awk -F"=" '{print $2}'`
  else
    echo -e "fatal error, check \"/scriptsNode/addtnlFiles/detailsVM\" file and verify..."
  fi
  x+=1
done < ~/detailsVM

brcount=`echo $vmBridges | awk -F"," '{print NF}'`
let "i=1"
while [ "$i" -le "$brcount" ]
do
  brName=`echo $vmBridges | cut -d "," -f $i`
  lineBridge+="--network bridge:$brName "
  let "i=i+1"
done

######### Creating Directories
echo -e "\nPlease make sure all details are correctly fille in \"/scriptsNode/addtnlFiles/detailsVM\" file.\nPress any key to continue."
read anykey;
if [ ! -d "/kvm_data/kvm_images/" ]; then
  mkdir -p /kvm_data
  if [ `lsblk | grep sdb | awk '{print$1}'` == "sdb" ]; then
    fdisk /dev/sdb
    pvcreate /dev/sdb1
    vgcreate kvm_vg /dev/sdb1
    lvcreate -L 550G -n kvm_lv kvm_vg
    mkfs.xfs /dev/kvm_vg/kvm_lv -f
    mount /dev/kvm_vg/kvm_lv /kvm_data
    echo /dev/kvm_vg/kvm_lv /kvm_data  xfs defaults 0 0 >>/etc/fstab
  fi
  mkdir -p /kvm_data/kvm_images/
fi
#echo "$rhelImgPath $rhelImgName $varImgName $kvmImgName $vmSize $vmMem $vmVcpus $osVariant $resizePart $vmBridges $vmName $brcount $lineBridge"

######### Deleting and recreating VM
echo -e "---------- Following details are found ----------\n"
cat ~/scriptsNode/addtnlFiles/detailsVM
echo -e "-------------------------------------------------\n"
echo -e "\n\033[0;31m!!!!!!!!!! WARNING: Procedding further, all related files to VM will be destroyed... !!!!!!!!!!\n\033[0m"
echo "Are you sure you want to continue (yes/no)?"
read ans;
if [ "$ans" == "yes" ] ;then
  virsh destroy $vmName
  virsh autostart $vmName --disable
  virsh undefine $vmName
  rm -f /kvm_data/kvm_images/$kvmImgName
  rm -f /var/lib/libvirt/images/$varImgName
  echo -e "\n############### Deleted all file for $vmName... ###############\n"
  echo "Do you want to create new VM (yes/no)?"
  read ans1;
  if [ "$ans1" == "yes" ] ;then
    if [ ! -f "$rhelImgPath/$rhelImgName" ]; then
      echo -e "\n\033[0;31m!!!!! ERROR: Required Files couldn't be found. VM couldn't be created... !!!!!\n\033[0m"
    else
      export LIBGUESTFS_BACKEND=direct
      cp $rhelImgPath/$rhelImgName /var/lib/libvirt/images/
      virt-customize -a /var/lib/libvirt/images/$rhelImgName --root-password password:mavenir
      virt-filesystems --long -h --all -a /var/lib/libvirt/images/$rhelImgName
      qemu-img create -f qcow2 /var/lib/libvirt/images/$varImgName $vmSize
      virt-resize --expand /dev/$resizePart /var/lib/libvirt/images/$rhelImgName /var/lib/libvirt/images/$varImgName
      qemu-img create -f qcow2 -b /var/lib/libvirt/images/$varImgName /kvm_data/kvm_images/$kvmImgName
      guestfish -a /kvm_data/kvm_images/$kvmImgName -i ln-sf /dev/null /etc/systemd/system/cloud-init.service
      virt-install --cpu host --memory $vmMem --vcpus $vmVcpus --os-variant $osVariant --disk path=/kvm_data/kvm_images/$kvmImgName,device=disk,bus=virtio,format=qcow2 --import --noautoconsole --vnc $lineBridge --name $vmName
      echo -e "\n############### VM Created Successfully... Waiting for 20 secs to finish. ###############\n"
      sleep 20s
    fi
  else echo -e "\n############### Skipping VM Creation... ###############\n"
  fi
fi
echo -e "\nDo you want to copy files inside the VM (yes/no)?"
read ans2;
if [ "$ans2" == "yes" ] ;then
  virsh destroy $vmName
  echo -e "\nEnter the name of files/directories (space seperated) to be copied inside the VM:"
  read files;
  tar -cvf files.tar $files
  echo -e "\n########## Waiting for VM to shut down... ##########\n"
  sleep 10s
  virt-copy-in -a /kvm_data/kvm_images/$kvmImgName /root/scriptsNode/files.tar /root/
  echo -e "\n########## Copying files to VM and powering it ON... ##########\n"
  virsh start $vmName
  virsh autostart $vmName
fi
rm -f files.tar
rm -f ~/detailsVM
