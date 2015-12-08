#!/bin/bash

VOLUME_HOME="/var/lib/mysql"

sed -ri -e "s/^upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" \
    -e "s/^post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE}/" /etc/php5/apache2/php.ini
if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysql_install_db > /dev/null 2>&1
    echo "=> Done!"  
    /create_mysql_admin_user.sh
else
    echo "=> Using an existing volume of MySQL"
fi

#修改config.php
#sed -ri -e "s/Asia SS/$SITE_NAME/"                             \
#        -e "s/https:\/\/ss.qaq.moe\//http:\/\/$DOMAIN\//"      \
#        -e "s/somethingRandomHere/$ENCRYPTION_KEY/"             /app/application/config/config.php
sed -i "s/Asia SS/$SITE_NAME/"                          /app/application/config/config.php
sed -i "s/https:\/\/ss.qaq.moe\//http:\/\/$DOMAIN\//"   /app/application/config/config.php
sed -i "s/somethingRandomHere/$ENCRYPTION_KEY/"         /app/application/config/config.php

#修改database.php    
#sed -ri -e "s/localhost/$HOSTNAME/"                            \
#        -e "s/ssuser/$USERNAME/"                               \
#        -e "s/yourDBPassword/$PASSWORD/"                       \ 
#        -e "s/shadowsocks/$DATABASE/"                           /app/application/config/database.php 
sed -i "s/localhost/$HOSTNAME/"                 /app/application/config/database.php
sed -i "s/ssuser/$USERNAME/"                    /app/application/config/database.php
sed -i "s/yourDBPassword/$PASSWORD/"            /app/application/config/database.php
sed -i "s/shadowsocks/$DATABASE/"               /app/application/config/database.php 

if [ "${AUTHORIZED_KEYS}" != "**None**" ]; then
    echo "=> Found authorized keys"
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    IFS=$'\n'
    arr=$(echo ${AUTHORIZED_KEYS} | tr "," "\n")
    for x in $arr
    do
        x=$(echo $x |sed -e 's/^ *//' -e 's/ *$//')
        cat /root/.ssh/authorized_keys | grep "$x" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "=> Adding public key to /root/.ssh/authorized_keys: $x"
            echo "$x" >> /root/.ssh/authorized_keys
        fi
    done
fi

if [ ! -f /.root_pw_set ]; then
	/set_root_pw.sh
fi

/usr/sbin/sshd -D

exec supervisord -n
