#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-08-28 ######
##################################################################################
if [ ! -d "/.selfDfiles" ]; then
  `sudo mkdir /.selfDfiles`
fi
if [ "$1" == "now" ] ;then
  echo -e "#############################################\n########## Self-Destruct begins... ##########\n#############################################\n"
  baseDirName=`basename "$PWD"`
  mydate="`date +%Y%m%d%H%M`"
  fileName="$baseDirName-$mydate"
  echo $fileName
  sudo tar -cf /.selfDfiles/$fileName.tar ../$baseDirName &> /dev/null
#  sudo rm -fr ../$baseDirName
else 
  at -f `. .selfDestruct/selfD.sh now` now + $1 min
fi
