#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-08-18 ######
##################################################################################
source /home/stack/stackrc
country=``
province=``
city=``
company=``
unit=``
hostname=``
email=``
declare -i x=1
while read line
do
  if [ $x -eq 1 ];then
    country=`echo $line | awk -F":" '{print $2}'`
  elif [ $x -eq 2 ];then
    province=`echo $line | awk -F":" '{print $2}'`
  elif [ $x -eq 3 ];then
    city=`echo $line | awk -F":" '{print $2}'`
  elif [ $x -eq 4 ];then
    company=`echo $line | awk -F":" '{print $2}'`
  elif [ $x -eq 5 ];then
    unit=`echo $line | awk -F":" '{print $2}'`
  elif [ $x -eq 6 ];then
    hostname=`echo $line | awk -F":" '{print $2}'`
  elif [ $x -eq 7 ];then
    email=`echo $line | awk -F":" '{print $2}'`
  else
    echo -e "fatal error check \"siteDetails\" file and verify..."
  fi
  x+=1
done < /home/stack/scriptsDIRXstack/scriptCertGen/siteDetails
if [ ! -f "/home/stack/ssl_gen/openssl.cnf" ]; then
  echo -e "\n!!! \"openssl.cnf\" file not found in \"/home/stack/ssl_gen/\". Restarting script... !!!\n"
else 
  echo -e "\nMaking Changes in \"openssl.cnf\" file..."
  sudo sed -i "/countryName_default/c\countryName_default             = $country" /home/stack/ssl_gen/openssl.cnf
  sudo sed -i "/stateOrProvinceName_default/c\stateOrProvinceName_default     = $province" /home/stack/ssl_gen/openssl.cnf
  sudo sed -i "/localityName_default/c\localityName_default            = $city" /home/stack/ssl_gen/openssl.cnf
  sudo sed -i "/0.organizationName_default/c\0.organizationName_default      = $company" /home/stack/ssl_gen/openssl.cnf
  sudo sed -i "/organizationalUnitName_default/c\organizationalUnitName_default  = $unit" /home/stack/ssl_gen/openssl.cnf
  sudo sed -i "/commonName_max/c\commonName_max                  = 64\ncommonName_default              = $hostname" /home/stack/ssl_gen/openssl.cnf
  sudo sed -i "/emailAddress_max/c\emailAddress_max                = 64\nemailAddress_default            = $email" /home/stack/ssl_gen/openssl.cnf
fi
