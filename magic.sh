#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-08-28 ######
##################################################################################
dTime=""
echo -e "\n############################################\n################ Magic Room ################\n############################################\n"
echo -e "Select the type of node,\n\n[1] Choice 1\n[2] Choice 2\n[3] \033[0;34mExit the Script\033[0m\n"
echo "EnterChoice:"
read option;
dTime=`echo $option | awk -F "@" '{print $2}'`
option=`echo $option | awk -F "@" '{print $1}'`
if [ "$option" == "1" ];then
  echo -e "\n Choice 1\n"
  ./magic.sh
elif [ "$option" == "2" ];then
  echo -e "\n Choice 2\n"
  ./magic.sh
elif [ "$option" == "3" ];then
  echo "Exiting............"
elif [ "$option" == "selfD" ];then
  if [ -z "$dTime" ];then
    echo -e "\nSelf Destruct could not be initiated.\n"
    ./magic.sh
  else
    echo "Are you sure, you want to self destruct? (yes/no)"
    read ans;
    if [ "$ans" == "yes" ] ;then
      echo -e "\nSelf Destruct in \"$dTime\"\n"
      . .selfDestruct/selfD.sh $dTime
    fi
  fi
else echo "Invalid Choice, running script again"
  ./magic.sh
fi
