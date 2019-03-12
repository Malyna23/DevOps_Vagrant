#!/bin/bash
#Login and passwords for services
DB_PORT="5432"
DB_NAME="moodle_task3"
DB_USER="admin1task3"
DB_PASS="Test03_DBpass"
MOODLE_HOST="192.168.56.11"
echo "Check & Install updates"
# Install update all and restart to apply
sudo yum update -y
echo "Install PostgreSQL"
# Install PostgreSQL
sudo yum install -y https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-redhat11-11-2.noarch.rpm
sudo yum install -y postgresql11-server
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
# Start the PostgreSQL service
sudo systemctl start postgresql-11
#Enable PostgreSQL to auto-start on boot
sudo systemctl enable postgresql-11
# Create a PostgreSQL database for Moodle
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME WITH OWNER $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME to $DB_USER;"
# PostgreSQL Translation port and Listening Addresses
sudo sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/11/data/postgresql.conf
sudo sed -i -e "s/#port = 5432/port = 5432/g" /var/lib/pgsql/11/data/postgresql.conf
echo "Finished Database section"
cat <<EOF | sudo tee -a /var/lib/pgsql/11/data/pg_hba.conf
host    all             all              $MOODLE_HOST/24        password
EOF
# Start the PostgreSQL service
sudo systemctl restart postgresql-11