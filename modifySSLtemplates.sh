#!/bin/bash
##################################################################################
###### Author: Tapan Kesarwani | version: 1.0.1 | Date Modified: 2021-10-06 ######
##################################################################################
source /home/stack/stackrc
if [ ! -f "/home/stack/ssl_gen/server.crt.pem" ]; then
  echo -e "\n!!! \"server.crt.pem\" and \"server.key.pem\" files not found in \"/home/stack/ssl_gen/\". Restarting script... !!!\n"
else 
  echo -e "\nMaking Changes in \"enable-tls.yaml\" file..."
  sed -n '/^-----BEGIN CERTIFICATE-----$/,$p' /home/stack/ssl_gen/server.crt.pem > tempCert
  sed -i -e 's/^/    /' tempCert
  sed '/The contents of your certificate go here/,$d' /home/stack/templates/enable-tls.yaml > temp1
  sed '1,/^    The contents of your certificate go here$/d' /home/stack/templates/enable-tls.yaml > temp2
  cat tempCert >> temp1
  cat temp2 >> temp1
  cat /home/stack/ssl_gen/server.key.pem > tempKey
  sed -i -e 's/^/    /' tempKey
  sed '/The contents of the private key go here/,$d' temp1 > enable-tls.yaml
  sed '1,/^    The contents of the private key go here$/d' temp1 > temp3
  cat tempKey >> enable-tls.yaml
  cat temp3 >> enable-tls.yaml
fi
if [ ! -f "/home/stack/ssl_gen/ca.crt.pem" ]; then
  echo -e "\n!!! \"ca.crt.pem\" file not found in \"/home/stack/ssl_gen/\". Restarting script... !!!\n"
else
  echo -e "\nMaking Changes in \"inject-trust-anchor-hiera.yaml\" file..."
  cat /home/stack/ssl_gen/ca.crt.pem > tempCaCert
  sed -i -e 's/^/        /' tempCaCert
  sed -n '/The content of the CA cert goes here/q;p' /home/stack/templates/inject-trust-anchor-hiera.yaml > inject-trust-anchor-hiera.yaml
  sed -n '/^    second-ca-name:$/,$p' /home/stack/templates/inject-trust-anchor-hiera.yaml > temp4
  cat tempCaCert >> inject-trust-anchor-hiera.yaml
  cat temp4 >> inject-trust-anchor-hiera.yaml
fi
rm -f temp*