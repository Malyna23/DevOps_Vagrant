#!/bin/bash
#Login and passwords for services
ROOT_PASS="Test01_ROOTpass"
DB_NAME="moodle_task1"
DB_USER="admin_task1"
DB_PASS="Test01_DBpass"
MOODLE_HOST="192.168.56.11"
MOODLE_USER="Admin"
MOODLE_PASS="Test01_MOODLEpass"
echo "Check & Install updates"
# Install EPEL, update all and restart to apply
sudo yum update -y
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
# Create a MariaDB database for Moodle
mysql -u root -p${ROOT_PASS} -e \
"CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET UTF8 COLLATE utf8_unicode_ci;\
CREATE USER '${DB_USER}' IDENTIFIED BY '${DB_PASS}';\
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}' IDENTIFIED BY '${DB_PASS}' WITH GRANT OPTION;\
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${ROOT_PASS}' WITH GRANT OPTION;\
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}@${MOODLE_HOST}' IDENTIFIED BY '${DB_PASS}' WITH GRANT OPTION;;\
FLUSH PRIVILEGES;"
# Drop the anonymous users
mysql -u root -p${ROOT_PASS} -e "DROP USER ''@'localhost';"
mysql -u root -p${ROOT_PASS} -e "DROP USER ''@'$(hostname)';"
# Drop the demo database
mysql -u root -p${ROOT_PASS} -e "DROP DATABASE test;"
# Restart 
sudo /etc/init.d/mysql restart