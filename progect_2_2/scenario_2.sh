#!/bin/bash
#Login and passwords for services
DB_HOST="192.168.56.10"
DB_NAME="moodle_task3"
DB_USER="admin1task3"
DB_PASS="Test03_DBpass"
DB_PORT="5432"
MOODLE_IP="192.168.56.11"
MOODLE_USER1="Admin_1"
MOODLE_PASS="Test03_MOODLEpass"
WEB_DIR="/var/www/html"
MOODLE_DATA="/var/moodledata"
echo "Check & Install updates"
# Install EPEL, update all and restart to apply
sudo yum install epel-release -y
sudo yum update -y
echo "Install Nginx"
sudo yum install nginx -y
# Start the Nginx service
sudo systemctl start nginx
# Enable it to auto-start on boot
sudo systemctl enable nginx
echo "Install PHP 7.2"
# Enable the Remo repository for PHP 7.2
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
sudo yum-config-manager --enable remi-php72
# Install yum-utils
sudo yum install yum-utils -y
# Install PHP 7.2
sudo yum --enablerepo=remi,remi-php72 install -y php php-fpm \
         php-common php-pear php-opcache php-mcrypt php-cli php-pspell php-gd php-curl php-pecl-memcached \
         php-mysql php-ldap php-zip php-fileinfo php-xml php-intl php-pecl-memcache php-readline \
         php-mbstring php-xmlrpc php-soap php-pdo php-pgsql php-pecl-apcu php-json
sudo sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sudo sed -i -e 's+listen = 127.0.0.1:9000+listen = /var/run/php-fpm/php-fpm.sock+g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;env/env/g' /etc/php-fpm.d/www.conf
sudo sed -i -e 's/;security.limit_extensions = .php .php3 .php4 .php5 .php7/security.limit_extensions = .php/g' /etc/php-fpm.d/www.conf
# Create a new directory for the php session path
mkdir -p /var/lib/php/session/
chown -R nginx:nginx /var/lib/php/session/
# Change owner of the php-fpm socket file directory to nginx
chown -R nginx:nginx /var/run/php-fpm/
# Start the PHP-FPM service
sudo systemctl enable php-fpm
# Enable it to auto-start on boot
sudo systemctl start php-fpm
echo "Install Moodle"
# Install wget to download moodle
sudo yum install wget -y
#Create temp foalder
sudo mkdir /temp
cd /temp
sudo wget https://download.moodle.org/download.php/direct/stable35/moodle-latest-35.tgz -O moodle-latest.tgz
sudo rm -rf ${WEB_DIR}
sudo setsebool httpd_can_network_connect true
sudo tar -zxvf moodle-latest.tgz -C /temp
sudo mv /temp/moodle ${WEB_DIR}
# Create a dedicated data directory for Moodle and giving permissions for files
sudo mkdir ${MOODLE_DATA}
sudo chown -R nginx:nginx ${MOODLE_DATA}
sudo chown -R nginx:nginx ${WEB_DIR}
sudo chcon -R -t httpd_sys_rw_content_t ${MOODLE_DATA}
sudo chcon -R -t httpd_sys_rw_content_t ${WEB_DIR}
sudo setsebool httpd_can_network_connect true
# Configure a virtual host for Moodle
# CAT SomeWay Everithing with $ is  a interpritation thats why:
CAT_FIX_1='$uri'
CAT_FIX_2='$1'
CAT_FIX_3='$3'
cat <<EOF | sudo tee -a /etc/nginx/conf.d/moodle.conf
upstream php-handler {
    server unix:/var/run/php-fpm/php-fpm.sock;
}
server {
    listen 80;
    server_name $MOODLE_IP;
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
# Restart PHP-FPM and NginX
sudo systemctl restart php-fpm
sudo systemctl restart nginx
echo "Install Moodle from CLI"
sudo -u nginx /usr/bin/php ${WEB_DIR}/admin/cli/install.php \
--lang=uk \
--chmod=2777 \
--wwwroot=http://${MOODLE_IP}:80 \
--dataroot=${MOODLE_DATA} \
--dbtype=pgsql \
--dbhost=${DB_HOST} \
--dbport=${DB_PORT} \
--dbname=${DB_NAME} \
--dbuser=${DB_USER} \
--dbpass=${DB_PASS} \
--fullname=Moodle \
--shortname=MD \
--summary=Moodle \
--adminuser=${MOODLE_USER1} \
--adminpass=${MOODLE_PASS} \
--non-interactive \
--agree-license
sudo chmod o+r ${WEB_DIR}/config.php
sudo systemctl restart nginx
sudo systemctl restart php-fpm
echo "###"
echo "Moodle Host IP:    ${MOODLE_IP}"
echo "Moodle Login:      ${MOODLE_USER1}"
echo "Moodle Pass:       ${MOODLE_PASS}"
echo "###"
echo "Data Base Host IP: ${DB_HOST}"
echo "Data Base Port:    ${DB_PORT}"
echo "Data Base Name:    ${DB_NAME}"
echo "Data Base Login:   ${DB_USER}"
echo "Data Base Pass:    ${DB_PASS}"
echo "###"