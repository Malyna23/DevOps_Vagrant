#!/bin/bash
#Login and passwords for services
ROOT_PASS="Test01_ROOTpass"
DB_HOST="192.168.56.10"
DB_NAME="moodle_task1"
DB_USER="admin_task1"
DB_PASS="Test01_DBpass"
DB_PORT=3306
WEB_DIR="/var/www/html"
MOODLE_DATA="/var/moodledata"
MOODLE_USER="Admin"
MOODLE_PASS="Test01_MOODLEpass"
MOODLE_IP="192.168.56.11"
echo "Check & Install updates"
# Install EPEL, update all and restart to apply
sudo yum install epel-release -y
sudo yum update -y
echo "Install Apache"
sudo yum install httpd -y
# Remove pre-seted welcome page
sudo rm /etc/httpd/conf.d/welcome.conf
# Start the Apache service
sudo systemctl enable httpd
# Enable it to auto-start on boot
sudo systemctl start httpd
echo "Install PHP_7.1"
# Add PHP Repo
sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
# Install PHP 7.1 and modules for Moodle
sudo yum install mod_php71w php71w-common php71w-mbstring php71w-xmlrpc php71w-soap php71w-gd php71w-xml php71w-intl php71w-mysqlnd php71w-cli php71w-mcrypt php71w-ldap -y
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
# Create a dedicated data directory for Moodle
sudo mkdir ${MOODLE_DATA}
sudo chown -R apache:apache ${MOODLE_DATA}
sudo systemctl restart httpd
# Configure a virtual host for Moodle
cat <<EOF | sudo tee -a /etc/httpd/conf.d/moodle.conf
<VirtualHost *:80>
ServerAdmin admin@ss-test.com
DocumentRoot ${WEB_DIR}
ServerName moodle.ss-test.com
ServerAlias www.moodle.ss-test.com
<Directory ${WEB_DIR}>
Options FollowSymLinks
AllowOverride All
Order allow,deny
allow from all
</Directory>
ErrorLog /var/log/httpd/moodle-error_log
CustomLog /var/log/httpd/moodle-access_log common
</VirtualHost>
EOF
echo "Cofigure SElinux for Moodle"
# Install required SELinux management tools:
sudo yum install -y policycoreutils policycoreutils-python -y
# Add Moodle files
sudo semanage fcontext -a -t httpd_sys_rw_content_t '$/var/www/html(/.*)?'
sudo restorecon -Rv ${WEB_DIR}
sudo semanage fcontext -a -t httpd_sys_rw_content_t '$/var/moodledata(/.*)?'
sudo restorecon -Rv ${MOODLE_DATA}
# Copy Configuration File
echo "Install Moodle from CLI"
sudo chown -R apache:apache ${WEB_DIR}
sudo -u apache /usr/bin/php ${WEB_DIR}/admin/cli/install.php \
--lang=uk \
--chmod=2777 \
--wwwroot=http://${MOODLE_IP}:80 \
--dataroot=${MOODLE_DATA} \
--dbtype=mariadb \
--dbhost=${DB_HOST} \
--dbport=${DB_PORT} \
--dbname=${DB_NAME} \
--dbuser=${DB_USER} \
--dbpass=${DB_PASS} \
--fullname=Moodle \
--shortname=MD \
--summary=Moodle \
--adminuser=${MOODLE_USER} \
--adminpass=${MOODLE_PASS} \
--non-interactive \
--agree-license
sudo systemctl restart httpd
