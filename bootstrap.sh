#!/usr/bin/env bash

# Prevent
export DEBIAN_FRONTEND=noninteractive

# Update Ubuntu
printf "Step 1 of 19: Updating Ubuntu..."
apt-get update -y > /dev/null

# Install Postgres & start service
printf "Step 2 of 19: Installing & starting Postgres..."
apt-get install postgresql libpq-dev -y > /dev/null
sudo service postgresql start

# Setup Postgres with netbox user, database, and permissions
printf "Step 3 of 19: Setup Postgres with netbox user, database, & permissions."
sudo -u postgres psql -c "CREATE DATABASE netbox"
sudo -u postgres psql -c "CREATE USER netbox WITH PASSWORD 'J5brHrAXFLQSif0K'"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox"

# Install nginx
printf "Step 4 of 19: Installing nginx..."
apt-get install nginx -y > /dev/null

# Install Python 2
printf "Step 5 of 19: Installing Python 3 dependencies..."
apt-get install python3 python3-dev python3-pip libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev redis-server -y > /dev/null

# Upgrade pip
printf "Step 6 of 19: Upgrading pip\n"
pip3 install --upgrade pip > /dev/null

# Install gunicorn & supervisor
printf "Step 7 of 19: Installing gunicorn & supervisor..."
pip3 install gunicorn
apt-get install supervisor -y > /dev/null

printf "Step 8 of 19: Cloning NetBox repo latest stable release..."
# git clone netbox master branch
git clone -b master https://github.com/digitalocean/netbox.git /opt/netbox

# Install NetBox requirements
printf "Step 9 of 19: Installing NetBox requirements..."
pip3 install -r /opt/netbox/requirements.txt > /dev/null

# Use configuration.example.py to create configuration.py
printf "Step 10 of 19: Configuring Netbox..."
cp /opt/netbox/netbox/netbox/configuration.example.py /opt/netbox/netbox/netbox/configuration.py
# Update configuration.py with database user, database password, netbox generated SECRET_KEY, & Allowed Hosts
sed -i "s/'USER': '',  /'USER': 'netbox',  /g" /opt/netbox/netbox/netbox/configuration.py
sed -i "s/'PASSWORD': '',  /'PASSWORD': 'J5brHrAXFLQSif0K',  /g" /opt/netbox/netbox/netbox/configuration.py
sed -i "s/ALLOWED_HOSTS \= \[\]/ALLOWED_HOSTS \= \['netbox.internal.local', 'netbox.localhost', 'localhost', '127.0.0.1'\]/g" /opt/netbox/netbox/netbox/configuration.py
SECRET_KEY=$( python3 /opt/netbox/netbox/generate_secret_key.py )
sed -i "s~SECRET_KEY = ''~SECRET_KEY = '$SECRET_KEY'~g" /opt/netbox/netbox/netbox/configuration.py
# Clear SECRET_KEY variable
unset SECRET_KEY

# Setup apache, gunicorn, & supervisord config using premade examples (need to change netbox-setup)
printf "Step 11 of 19: Configuring nginx..."
cp /home/vagrant/config_files/nginx-netbox.example /etc/nginx/sites-available/netbox
printf "Step 12 of 19: Configuring gunicorn..."
cp /home/vagrant/config_files/gunicorn_config.example.py /opt/netbox/gunicorn_config.py
printf "Step 13 of 19: Configuring supervisor..."
cp /home/vagrant/config_files/supervisord-netbox.example.conf /etc/supervisor/conf.d/netbox.conf

# Apache Setup (enable the proxy and proxy_http modules, and reload Apache)
printf "Step 14 of 19: Completing web service setup..."
cd /etc/nginx/sites-enabled/
rm default
ln -s /etc/nginx/sites-available/netbox
service nginx restart
service supervisor restart

# Install the database schema
printf "Step 15 of 19: Install the database schema..."
python3 /opt/netbox/netbox/manage.py migrate > /dev/null

# Create admin / admin superuser
printf "Step 16 of 19: Create NetBox superuser..."
echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'admin@example.com', 'admin')" | python3 /opt/netbox/netbox/manage.py shell  > /dev/null

# Collect Static Files
printf "Step 17 of 19: collectstatic"
python3 /opt/netbox/netbox/manage.py collectstatic --no-input <<<yes > /dev/null

# Load Initial Data (Optional) Comment out if you like
printf "Step 18 of 19: Load intial data."
python3 /opt/netbox/netbox/manage.py loaddata initial_data > /dev/null

# Install NAPALM Drivers
printf "Step 19 of 19: Installing NAPALM Drivers"
pip3 install napalm

# Fix permissions to folder
chown -R www-data /opt/netbox/netbox/media/image-attachments/

# Status Complete
printf "%s\nCOMPLETE: NetBox-Demo Provisioning COMPLETE!!"
printf "%s\nTo login to the Vagrant VM use vagrant ssh in the current directory"
printf "%s\nSee NAPALM and Netbox documentation to get NAPALM working with Netbox and your environment"
printf "%s\nTo login to the Netbox-Demo web portal go to http://netbox.localhost:8080"
printf "%s\nWeb portal superuser credentials are admin / admin"
