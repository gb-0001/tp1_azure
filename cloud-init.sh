#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y g++ curl libssl-dev apache2-utils build-essential
sudo apt install unzip -y
sudo wget http://nodejs.org/dist/v0.10.30/node-v0.10.30.tar.gz
sudo tar -xzf node-v0.10.30.tar.gz
cd node-v0.10.30
sudo ./configure
sudo make
sudo make install
sudo apt-get install -y nginx
sudo service nginx restart
sudo mkdir -p /var/www/myapp
cd /var/www/myapp && wget -O master.zip https://github.com/azure-devops/fabrikam-node/archive/refs/heads/master.zip && /bin/bash install_srv_integration.sh
unzip /var/www/myapp/master.zip -d /var/www/myapp/
cd /var/www/myapp/ && ./deployapp.sh
