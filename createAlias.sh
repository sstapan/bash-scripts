#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-09-16 ######
##################################################################################
podPREFIX="rcsbal"
podPOSTFIX=""
nodeTYPE=""
pf_len=`expr length "$podPOSTFIX"`
source /home/stack/stackrc
for i in $(nova list | grep -i $podPREFIX | awk '{print $4":"$12}');do
  nodeHOST="$(echo $i | awk -F":" '{print $1}')"
  nodeIP="$(echo $i | awk -F"=" '{print $2}')"
  temp1="${nodeHOST#$podPREFIX}"
  if [ "$podPOSTFIX" == "" ];then
    nodeHOSTShort="${temp1}"
    nodeHOSTNo="${nodeHOSTShort: -2}"
  else
    nodeHOSTShort="${temp1:: -$pf_len}"
    nodeHOSTNo="${nodeHOSTShort: -2}"
  fi
  if echo "$nodeHOST" | egrep -i -q "ctrl|con|cpmo|cnt";then
    nodeTYPE="ctrl"
  fi
  if echo "$nodeHOST" | egrep -i -q "strg|st|cpsg";then
    nodeTYPE="strg"
  fi
  if echo "$nodeHOST" | egrep -i -q "comp|com|cmps|cmp";then
    nodeTYPE="comp"
  fi
  #echo "$nodeHOST,$nodeIP,$nodeHOSTShort,$nodeHOSTNo,$nodeTYPE"
  case $nodeTYPE in
  ctrl) echo "alias ctrl$nodeHOSTNo='ssh heat-admin@$nodeIP'" >> ~/.bashrc
        echo "alias ctrl$nodeHOSTNo='ssh heat-admin@$nodeIP'"
        ;;
  strg) echo "alias strg$nodeHOSTNo='ssh heat-admin@$nodeIP'" >> ~/.bashrc
        echo "alias strg$nodeHOSTNo='ssh heat-admin@$nodeIP'"
        ;;
  comp) echo "alias comp$nodeHOSTNo='ssh heat-admin@$nodeIP'" >> ~/.bashrc
        echo "alias comp$nodeHOSTNo='ssh heat-admin@$nodeIP'"
        ;;
  *) ;;
  esac
done
#source ~/.bashrc/
