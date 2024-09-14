#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.1 | Date Modified: 2021-09-23 ######
##################################################################################
PROJINFO="/home/stack/scriptsDIRXstack/addtnlScriptsDIRXstack/addtnlPostDepFiles/proj-info.txt"
rm $PROJINFO 2> /dev/null
source /home/stack/overcloudrc
echo "Setting Quota to infinite for admin user..."
openstack quota set --backup-gigabytes -1 --backups -1 --cores -1 --floating-ips -1 --gigabytes -1 --instances -1 --key-pairs -1 --networks -1 --per-volume-gigabytes -1 --ports -1 --properties -1 --ram -1 --routers -1 --secgroup-rules -1 --secgroups -1 --server-group-members -1 --server-groups -1 --snapshots -1 --subnets -1 --volumes -1 admin
echo "Creating heat_stack_owner role..."
openstack role create heat_stack_owner
echo ""
echo "Enter the name of projects/users, seperated by space."
read line;
declare -i x=1
for ch in $line
do
  echo -e  $ch '\t' '\t' $ch "Project\t" '\t' $ch "\t\torganization   " $ch >> $PROJINFO
  x+=1
done
echo ""
echo "Selected Projects/User/Role"
echo "-------------------------------------------------------------------------"
echo "Project-Name     Project-Des             User-Name      Password   Role"
echo "-------------------------------------------------------------------------"
cat $PROJINFO
echo "-------------------------------------------------------------------------"
echo ""
echo "Confirm Project/Users Details (yes/no)"
read ans;
if [ "$ans" == "yes" ] ;then
  echo "-------------------------------------------------------------------------"
  echo "Project-Name     Project-Des             User-Name      Password   Role"
  echo "-------------------------------------------------------------------------"
  while read line1; do
  declare -i y=1
    for word in $line1
    do
      if [ $y -eq 1 ];then
        projname=$word
      elif [ $y -eq 2 ];then
        projdes1=$word
      elif [ $y -eq 3 ];then
        projdes="$projdes1 $word"
      elif [ $y -eq 4 ];then
        username=$word
      elif [ $y -eq 5 ];then
        pass=$word
      elif [ $y -eq 6 ];then
        role=$word
      else
        echo "fatal error, check text file '$PROJINFO'"
      fi
      y+=1
      done
      echo -e "$projname \t\t $projdes \t\t $username \t\t$pass    $role"
      echo "-------------------------------------------------------------------------"
      openstack project create --description "$projdes" $projname
      openstack user create --password mavenir $username
      openstack role create $role
      openstack role add --project $projname --user $username $role
      openstack role add --project $projname --user $username heat_stack_owner
      openstack quota set --backup-gigabytes -1 --backups -1 --cores -1 --floating-ips -1 --gigabytes -1 --instances -1 --key-pairs -1 --networks -1 --per-volume-gigabytes -1 --ports -1 --properties -1 --ram -1 --routers -1 --secgroup-rules -1 --secgroups -1 --server-group-members -1 --server-groups -1 --snapshots -1 --subnets -1 --volumes -1 $username
    done < $PROJINFO
elif [ "$ans" == "no" ] ;then
  echo "Taking Back to Projects/Users Creation..."
  . /home/stack/scriptsDIRXstack/addtnlScriptsDIRXstack/createCloudUsrProjQuota.sh
else
    echo "Not Valid input"
    echo "Taking Back to main List..."
fi
