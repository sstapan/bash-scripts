#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.1 | Date Modified: 2021-09-23 ######
##################################################################################
FLAVSEL="/home/stack/scriptsDIRXstack/addtnlScriptsDIRXstack/addtnlPostDepFiles/selectFlavor.txt"
rm $FLAVSEL 2> /dev/null
touch $FLAVSEL
echo ""
echo "Flavors List"
echo "---------------------------------------------------------------"
echo "No. Flavor-Name                     RAM     vCPU   DISK    NUMA"
echo "---------------------------------------------------------------"
cat $1
echo "---------------------------------------------------------------"
echo ""
echo "Enter 'all' for all flavors or integer values (with space) of flavors you want created: "
read line; 
if [ "$line" == "all" ] ;then
  cat $1 >> $FLAVSEL
else
  p="p"
  declare -i x=1
  for ch in $line
  do
    A=$ch$p
    sed -n $A $1 >> $FLAVSEL
    x+=1
  done
fi
echo ""
echo "Selected Flavors"
echo "---------------------------------------------------------------"
echo "No. Flavor-Name                     RAM     vCPU   DISK    NUMA"
echo "---------------------------------------------------------------"
cat $FLAVSEL
echo "---------------------------------------------------------------"
echo ""
echo "Confirm Flavors (yes/no)"
read ans;
if [ "$ans" == "yes" ] ;then
    . /home/stack/scriptsDIRXstack/addtnlScriptsDIRXstack/flavorCreate.sh
elif [ "$ans" == "no" ] ;then
    echo "Taking Back to Flavors List..."
    . /home/stack/scriptsDIRXstack/addtnlScriptsDIRXstack/flavorSelect.sh
else
    echo "Not Valid input"
    echo "Taking Back to main List..."
fi
