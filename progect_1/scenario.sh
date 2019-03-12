#!/bin/bash
#Login and passwords for services
ROOT_PASS="Test01_ROOTpass"
DB_NAME="moodle_task1"
DB_USER="admin_task1"
DB_PASS="Test01_DBpass"
MOODLE_USER="Admin"
MOODLE_PASS="Test01_MOODLEpass"
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
echo "Install MariaDB 10.3"
# MariaDB 10.3 YUM repo
cat <<EOF | sudo tee -a /etc/yum.repos.d/MariaDB.repo
# MariaDB 10.3 CentOS repository list - created 2019-02-24 10:16 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
# Install MariaDB
sudo yum install MariaDB-server MariaDB-client -y
# Start the MariaDB service
sudo systemctl start mariadb.service
#Enable MariaDB to auto-start on boot
sudo systemctl enable mariadb.service
# Ensure it is running
sudo /etc/init.d/mysql restart
# set root password
sudo /usr/bin/mysqladmin -u root password ${ROOT_PASS}
echo "Check & Install updates"
# Create a MariaDB database for Moodle
mysql -u root -p${ROOT_PASS} -e \
"CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET UTF8 COLLATE utf8_unicode_ci;\
CREATE USER '${DB_USER}' IDENTIFIED BY '${DB_PASS}';\
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}' IDENTIFIED BY '${DB_PASS}' WITH GRANT OPTION;\
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${ROOT_PASS}' WITH GRANT OPTION;\
FLUSH PRIVILEGES;"
# Drop the anonymous users
mysql -u root -p${ROOT_PASS} -e "DROP USER ''@'localhost';"
mysql -u root -p${ROOT_PASS} -e "DROP USER ''@'$(hostname)';"
# Drop the demo database
mysql -u root -p${ROOT_PASS} -e "DROP DATABASE test;"
# Restart 
sudo /etc/init.d/mysql restart
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
sudo rm -rf /var/www/html/
sudo tar -zxvf moodle-latest.tgz -C /var/www/
sudo mv /var/www/moodle /var/www/html
sudo rm -rf /temp
# Create a dedicated data directory for Moodle
sudo mkdir /var/moodledata
sudo chown -R apache:apache /var/moodledata
sudo systemctl restart httpd
# Configure a virtual host for Moodle
cat <<EOF | sudo tee -a /etc/httpd/conf.d/moodle.conf
<VirtualHost *:80>
ServerAdmin admin@ss-test.com
DocumentRoot /var/www/html/
ServerName moodle.ss-test.com
ServerAlias www.moodle.ss-test.com
<Directory /var/www/html/>
Options FollowSymLinks
AllowOverride All
Order allow,deny
allow from all
</Directory>
ErrorLog /var/log/httpd/moodle.ss-test.com-error_log
CustomLog /var/log/httpd/moodle.ss-test.com-access_log common
</VirtualHost>
EOF
echo "Cofigure SElinux for Moodle"
# Install required SELinux management tools:
sudo yum install -y policycoreutils policycoreutils-python -y
# Add Moodle files
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/html/(/.*)?'
sudo restorecon -Rv '/var/www/html/'
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/var/moodledata(/.*)?'
sudo restorecon -Rv '/var/moodledata'
# Copy Configuration File
echo "Install Moodle from CLI"
sudo chown -R apache:apache /var/www/html
sudo -u apache /usr/bin/php /var/www/html/admin/cli/install.php \
--lang=uk \
--chmod=2777 \
--wwwroot=http://192.168.56.2:80 \
--dataroot=/var/moodledata \
--dbtype=mariadb \
--dbhost=localhost \
--dbport=3306 \
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
