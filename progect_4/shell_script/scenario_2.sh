#!/bin/bash
#
#########################################################################################################
# Variables #############################################################################################
#########################################################################################################
# Global Variables (From Vagrant File)
source /home/vagrant/global_vars.sh
# Local Variables
WEB_DIR="/var/www/html"
MOODLE_DATA="/var/moodledata"
#
########################################################################################################
# Install and configure Nginx, PHP #####################################################################
########################################################################################################
#
# Install EPEL, update all and restart to apply
echo "Install Nginx"
sudo yum install epel-release -y
sudo yum install nginx -y
#
# Start the Nginx service
sudo systemctl start nginx
#
# Enable it to auto-start on boot
sudo systemctl enable nginx
#
# Install PHP 7.2
echo "Install PHP"
# Enable the Remo repository for PHP 7.2
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
sudo yum-config-manager --enable remi-php72
#
# Install yum-utils
sudo yum install yum-utils -y
#
# Install PHP 7.2
sudo yum --enablerepo=remi,remi-php72 install -y php php-fpm \
         php-common php-pear php-opcache php-mcrypt php-cli php-pspell php-gd php-curl php-pecl-memcached \
         php-mysql php-ldap php-zip php-fileinfo php-xml php-intl php-pecl-memcache php-readline \
         php-mbstring php-xmlrpc php-soap php-pdo php-pgsql php-pecl-apcu php-json
#
# Replace some parameters for project
sudo sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sudo sed -i -e 's+listen = 127.0.0.1:9000+listen = /var/run/php-fpm/php-fpm.sock+g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;env/env/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;security.limit_extensions = .php .php3 .php4 .php5 .php7/security.limit_extensions = .php/g' /etc/php-fpm.d/www.conf
#
# Create a new directory for the php session path
mkdir -p /var/lib/php/session/
sudo chown -R nginx:nginx /var/lib/php/session/
#
# Start the PHP-FPM service
sudo systemctl enable php-fpm
#
# Enable it to auto-start on boot
sudo systemctl start php-fpm
#
# Change owner of the php-fpm socket file directory to nginx
sudo chown -R nginx:nginx /var/run/php-fpm/
#
########################################################################################################
# Prepare for Moodle Install ###########################################################################
########################################################################################################
#
echo "Install Moodle"
# Install wget to download moodle
sudo yum install wget -y
#
# Download Moodle and unarchive it to Virtual host folder
sudo mkdir /temp
sudo wget https://download.moodle.org/download.php/direct/stable36/moodle-latest-36.tgz -O \
/temp/moodle-latest.tgz 
sudo rm -rf ${WEB_DIR}
sudo tar -zxvf /temp/moodle-latest.tgz -C /temp
sudo mv /temp/moodle ${WEB_DIR}
#
# Install required SELinux management tools
sudo yum -y install policycoreutils-python -y
#
# Add Moodle Data dir and chainge owner
sudo mkdir ${MOODLE_DATA}
sudo chown -R nginx:nginx ${MOODLE_DATA}
sudo chown -R nginx:nginx ${WEB_DIR}
#
# Changing SElinux policy to run in permissive mode for Nginx
sudo semanage permissive -a httpd_t
#
# Configure a virtual host for Moodle
#
# CAT SomeWay Everithing with $ is  a interpritation thats why:
#
CAT_FIX_1='$uri'
CAT_FIX_2='$1'
CAT_FIX_3='$3'
#
cat <<EOF | sudo tee -a /etc/nginx/conf.d/moodle.conf
upstream php-handler {
    server unix:/var/run/php-fpm/php-fpm.sock;
}

server {
    listen 80;
    server_name $STREAM_WEB_IP_1;

    root $WEB_DIR;
    rewrite ^/(.*\.php)(/)(.*)$ /$CAT_FIX_2?file=/$CAT_FIX_3 last;
    location ^~ / {
            try_files $CAT_FIX_1 $CAT_FIX_1/ /index.php?q=$request_uri;
            index index.php index.html index.htm;
            location ~ \.php$ {
                   include fastcgi.conf;
                   fastcgi_pass php-handler;
            }
    }
}
EOF
#
# Configuration NginX for Load Balancer
#
sudo rm /etc/nginx/nginx.conf
REMOTE_ADDR='$remote_addr'
REMOTE_USER='$remote_user'
TIME='$time_local'
REQUEST='$request'
STATUS='$status'
BODY='$body'
REFERER='$http_referer'
AGENT='$http_user_agent'
FORWARDED='$http_x_forwarded_for'
#
cat <<EOF | sudo tee -a /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$REMOTE_ADDR - $REMOTE_USER [$TIME] "$REQUEST" '
                      '$STATUS $BODY_bytes_sent "$REFERER" '
                      '"$AGENT" "$FORWARDED"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
                        }
    }

}
EOF
#
########################################################################################################
# Install Moodle from CLI ##############################################################################
########################################################################################################
#
echo "Install Moodle from CLI"
#
sudo -u nginx /usr/bin/php ${WEB_DIR}/admin/cli/install.php \
--lang=uk \
--chmod=2777 \
--wwwroot=http://${STREAM_WEB_IP_1}:80 \
--dataroot=${MOODLE_DATA} \
--dbtype=pgsql \
--dbhost=${STREAM_DB_IP} \
--dbport=${STREAM_DB_PORT} \
--dbname=${STREAM_BASE_NAME} \
--dbuser=${STREAM_DB_USER} \
--dbpass=${STREAM_DB_PASS} \
--fullname=Moodle \
--shortname=MD \
--summary=Moodle \
--adminuser=${STREAM_MOODLE_USER} \
--adminpass=${STREAM_MOODLE_PASS} \
--non-interactive \
--agree-license
sudo chmod o+r ${WEB_DIR}/config.php
sudo systemctl restart php-fpm
sudo systemctl restart nginx
#
echo "######################################################"
echo "Moodle Host IP:    ${STREAM_WEB_IP_1}"
echo "Moodle Login:      ${STREAM_MOODLE_USER}"
echo "Moodle Pass:       ${STREAM_MOODLE_PASS}"
echo "######################################################"
echo "Data Base Host IP: ${STREAM_DB_IP}"
echo "Data Base Port:    ${STREAM_DB_PORT}"
echo "Data Base Name:    ${STREAM_BASE_NAME}"
echo "Data Base Login:   ${STREAM_DB_USER}"
echo "Data Base Pass:    ${STREAM_DB_PASS}"
echo "######################################################"