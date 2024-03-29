#!/bin/bash

#Simple script to install Graylog

#Update System
sudo apt -y update && sudo apt upgrade

#Install Prereq packages for Debian 11 minimal install
sudo apt -y install apt-transport-https openjdk-17-jre-headless uuid-runtime pwgen dirmngr gnupg wget

#Add MobgoDB Repo
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt update

#install and enable mongodb
sudo apt -y install mongodb-org
sudo systemctl daemon-reload
sudo systemctl enable mongod.service
sudo systemctl restart mongod.service

#add Elasticsearch Repo
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update

#install and enable Elasticsearch
sudo apt -y install elasticsearch-oss

#Edit Elasticsearch config file
sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null << EOT
cluster.name: graylog
action.auto_create_index: false
EOT

#Restart Elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service

#Install Graylog Open Source
wget https://packages.graylog2.org/repo/packages/graylog-4.3-repository_latest.deb
sudo dpkg -i graylog-4.3-repository_latest.deb
sudo apt update
sudo apt -y install graylog-server graylog-integrations-plugins

#Generate Password Secret and save it to conf file
password_secret=$(pwgen -N 1 -s 96)
sudo sed -i "s/password_secret =/password_secret =$password_secret/g" /etc/graylog/server/server.conf

#Generate initial SHA-256 Hash of the root password and save it to conf file
echo -n "Enter Password: "
read password
message=$(echo -n "$password" | sha256sum | awk '{ print $1 }')
sudo sed -i "s/root_password_sha2 =/root_password_sha2 =$message/g" /etc/graylog/server/server.conf

#Set Graylog to listen on localhost at port 9000
sudo sed -i "s/#http_bind_address = 127.0.0.1:9000/http_bind_address = 0.0.0.0:9000/g" /etc/graylog/server/server.conf

#Reload and enable graylog at boot
sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
sudo systemctl restart graylog-server.service
