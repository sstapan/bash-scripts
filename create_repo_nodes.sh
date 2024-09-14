#!/bin/sh
REPOFILE="/var/www/html/osprepo/osp_nodes.repo"
ADDRESS="192.168.5.2"
rm $REPOFILE 2> /dev/null
touch $REPOFILE
for DIR in `find /var/www/html/osprepo -maxdepth 1 -mindepth 1 -type d`
do
        echo -e "[`basename $DIR`]" >> $REPOFILE
        echo -e "name=`basename $DIR`" >> $REPOFILE
        echo -e "baseurl=http://$ADDRESS/osprepo/`basename $DIR`/" >> $REPOFILE
        echo -e "enabled=1" >> $REPOFILE
        echo -e "gpgcheck=1" >> $REPOFILE
        echo -e "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release" >> $REPOFILE
        echo -e "\n" >> $REPOFILE
done
