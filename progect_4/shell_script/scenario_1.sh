#!/bin/bash
#Login and passwords for services
source /home/vagrant/global_vars.sh
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
sudo -u postgres psql -c "CREATE USER ${STREAM_DB_USER} WITH ENCRYPTED PASSWORD '${STREAM_DB_PASS}';"
sudo -u postgres psql -c "CREATE DATABASE ${STREAM_BASE_NAME} WITH OWNER ${STREAM_DB_USER};"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${STREAM_BASE_NAME} to ${STREAM_DB_USER};"
# PostgreSQL Translation port and Listening Addresses
sudo sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/11/data/postgresql.conf
sudo sed -i -e "s/#port = 5432/port = $STREAM_DB_PORT/g" /var/lib/pgsql/11/data/postgresql.conf
echo "Finished Database section"
sudo cat postgre_access_vars.cfg >> /var/lib/pgsql/11/data/pg_hba.conf
# Start the PostgreSQL service
sudo systemctl restart postgresql-11