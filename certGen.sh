#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.0 | Date Modified: 2021-08-16 ######
##################################################################################
source /home/stack/stackrc
if [ ! -d "/etc/pki/CA" ]; then
  `sudo mkdir /etc/pki/CA`
  `sudo mkdir /etc/pki/CA/private /etc/pki/CA/certs /etc/pki/CA/crl /etc/pki/CA/newcerts`
  `sudo chmod 700 /etc/pki/CA/private`
fi
if [ ! -f "/home/stack/bkp-deploy.sh" ]; then
  cp /home/stack/deploy*.sh /home/stack/bkp-deploy.sh
fi
serial="1000"
echo ""
echo -e "###############################################\n###### SSL/TLS Certificate Generation... ######\n###############################################\n"
echo "Creating the appropriate directories..."
echo ""
echo "Selct the step you want to proceed with,"
echo ""
echo -e "[1] Step 1: Create the respective files (\"/etc/pki/CA/index.txt\" and \"/etc/pki/CA/serial\")."
echo -e "[2] Step 2: Create \"ssl_gen\" directory, and generate CA Key and Certifiacte in it."
echo "[3] Step 3: Copying files, updating trust and generating server key."
echo -e "[4] Step 4: Edit \"openssl.cnf\" file in \"/home/stack/ssl_gen/\" directory."
echo "[5] Step 5: Setting up Server Certificates."
echo "[6] Step 6: Copying the files to the correct places."
echo "[7] Reset values and start fresh..."
echo "[8] EXIT..."
echo ""
option=``
deployFileName=`find /home/stack/ -type f -iname "deploy*.sh" | awk -F"/" '{print $4}'`
echo "Select the desired option."
read option;
if [ "$option" == "1" ];then
  if [ ! -f "/etc/pki/CA/index.txt" ]; then
    `sudo touch /etc/pki/CA/index.txt`
  fi
  if [ ! -f "/etc/pki/CA/serial" ]; then
    echo -e "\nPresent Value of \"/etc/pki/CA/serial\""
    echo $serial | sudo tee /etc/pki/CA/serial
  else 
  while read LINE  
  do  
    serial=$LINE
    echo -e "\nPrevious Value of \"/etc/pki/CA/serial\"\n$serial"
    let "serial=(serial+1)"
    echo -e "\nPresent Value of \"/etc/pki/CA/serial\""
    echo $serial | sudo tee /etc/pki/CA/serial
  done <  /etc/pki/CA/serial
  fi
  echo -e "\n#### Step [1] Successfully Completed. ####\n"
  . /home/stack/scriptsDIRXstack/scriptCertGen/certGen.sh
elif [ "$option" == "2" ];then
  if [ ! -d "/home/stack/ssl_gen" ]; then
  `mkdir /home/stack/ssl_gen`
  fi
  if [ ! -f "/home/stack/ssl_gen/ca.key.pem" ]; then
    openssl genrsa -out /home/stack/ssl_gen/ca.key.pem 4096
  fi
  echo -e "\nPlease continue, only if Certificate Details have been correctly filled in \"/home/stack/scriptsDIRXstack/scriptCertGen/siteDetails\"."
  echo "Continue (yes/no): "
  read ans;
  if [ "$ans" == "yes" ] ;then
    echo -e "\n\n###### Site Details for Certificate ######\n"
    cat /home/stack/scriptsDIRXstack/scriptCertGen/siteDetails
    echo -e "\n\n!!! Please input the same values below as given above... !!!\n\n"
    openssl req -key /home/stack/ssl_gen/ca.key.pem -new -x509 -days 7300 -extensions v3_ca -out /home/stack/ssl_gen/ca.crt.pem
  else echo "Restarting Script..."
  fi
  echo -e "\n#### Step [2] Successfully Completed. ####\n"
  . /home/stack/scriptsDIRXstack/scriptCertGen/certGen.sh
elif [ "$option" == "3" ];then
  sudo cp /home/stack/ssl_gen/ca.crt.pem /etc/pki/ca-trust/source/anchors/
  sudo update-ca-trust extract
  openssl genrsa -out /home/stack/ssl_gen/server.key.pem 2048
  cp /etc/pki/tls/openssl.cnf /home/stack/ssl_gen/
  echo -e "\n#### Step [3] Successfully Completed. ####\n"
  . /home/stack/scriptsDIRXstack/scriptCertGen/certGen.sh
elif [ "$option" == "4" ];then
  . /home/stack/scriptsDIRXstack/scriptCertGen/editOpensslConf.sh
  echo -e "\n#### Step [4] Successfully Completed. ####\n"
  . /home/stack/scriptsDIRXstack/scriptCertGen/certGen.sh
elif [ "$option" == "5" ];then
  echo -e "\n\n!!! Please input the same values below as given inside []... !!!\n\n"
  openssl req -config /home/stack/ssl_gen/openssl.cnf -key /home/stack/ssl_gen/server.key.pem -new -out /home/stack/ssl_gen/server.csr.pem
  sudo openssl ca -config /home/stack/ssl_gen/openssl.cnf -extensions v3_req -days 3650 -in /home/stack/ssl_gen/server.csr.pem -out /home/stack/ssl_gen/server.crt.pem -cert /home/stack/ssl_gen/ca.crt.pem -keyfile /home/stack/ssl_gen/ca.key.pem
  echo -e "\n#### Step [5] Successfully Completed. ####\n"
  . /home/stack/scriptsDIRXstack/scriptCertGen/certGen.sh
elif [ "$option" == "6" ];then
  cp -r /usr/share/openstack-tripleo-heat-templates/environments/ssl/enable-tls.yaml /home/stack/templates/
  cp -r /usr/share/openstack-tripleo-heat-templates/environments/ssl/inject-trust-anchor-hiera.yaml /home/stack/templates/
  . /home/stack/scriptsDIRXstack/scriptCertGen/modifySSLtemplates.sh
  if [ ! -f "/home/stack/scriptsDIRXstack/scriptCertGen/enable-tls.yaml" ]; then
    echo -e "\n!!! \"enable-tls.yaml\" coulldn't be modified. Restarting script... !!!\n"
  else
    rm -f /home/stack/templates/enable-tls.yaml
    mv /home/stack/scriptsDIRXstack/scriptCertGen/enable-tls.yaml /home/stack/templates/
  fi
  if [ ! -f "/home/stack/scriptsDIRXstack/scriptCertGen/inject-trust-anchor-hiera.yaml" ]; then
    echo -e "\n!!! \"inject-trust-anchor-hiera.yaml\" coulldn't be modified. Restarting script... !!!\n"
  else
    rm -f /home/stack/templates/inject-trust-anchor-hiera.yaml
    mv /home/stack/scriptsDIRXstack/scriptCertGen/inject-trust-anchor-hiera.yaml /home/stack/templates/
  fi
  echo -e "\n#### Step [6] Successfully Completed. ####\n"
  echo -e "Do you also want to edit \"deploy.sh\" file to accomodate SSL/TLS templates? (yes/no):"
  read ans1;
  if [ "$ans1" == "yes" ] ;then
    echo -e "\n###### \"$deployFileName\" Modified as below... ######\n"
    sed -i "/rhsm_rhops16.yaml/c\  -e ~/templates/rhsm_rhops16.yaml\n  -e ~/templates/enable-tls.yaml\n  -e ~/templates/inject-trust-anchor-hiera.yaml\n  -e /usr/share/openstack-tripleo-heat-templates/environments/ssl/tls-endpoints-public-ip.yaml" /home/stack/$deployFileName
    sed -i "/rhsm_rhops16.yaml/c\  -e ~/templates/rhsm_rhops16.yaml \\" /home/stack/$deployFileName
    sed -i "/enable-tls.yaml/c\  -e ~/templates/enable-tls.yaml \\" /home/stack/$deployFileName
    sed -i "/inject-trust-anchor-hiera.yaml/c\  -e ~/templates/inject-trust-anchor-hiera.yaml \\" /home/stack/$deployFileName
    sed -i "/tls-endpoints-public-ip.yaml/c\  -e /usr/share/openstack-tripleo-heat-templates/environments/ssl/tls-endpoints-public-ip.yaml \\" /home/stack/$deployFileName
    more /home/stack/deploy*.sh 
    echo -e "\nPress any key to continue...\n"
    read key;
  else echo -e "\nRestarting Script...\n"
  fi
  . /home/stack/scriptsDIRXstack/scriptCertGen/certGen.sh
elif [ "$option" == "7" ];then
  echo "Deleting all files..."
  sudo rm -fr /etc/pki/CA /home/stack/ssl_gen
  sudo rm -f /etc/pki/ca-trust/source/anchors/ca.crt.pem
  rm -f /home/stack/deploy*.sh /home/stack/templates/enable-tls.yaml /home/stack/templates/inject-trust-anchor-hiera.yaml
  mv /home/stack/bkp-deploy.sh /home/stack/$deployFileName
elif [ "$option" == "8" ];then
  echo "Exiting............"
else echo "Invalid Choice, running script again"
  . /home/stack/scriptsDIRXstack/scriptCertGen/certGen.sh
fi
