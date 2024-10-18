#!/bin/bash

#Ubuntu 22.04 
#Omada Controller 5.14.26.1

apt update && apt upgrade -y
apt install openjdk-8-jre-headless gnupg2 jsvc curl -y

curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org=7.0.14 mongodb-org-database=7.0.14 mongodb-org-server=7.0.14 mongodb-mongosh mongodb-org-mongos=7.0.14 mongodb-org-tools=7.0.14
wget https://static.tp-link.com/upload/software/2024/202407/20240710/Omada_SDN_Controller_v5.14.26.1_linux_x64.deb
sudo dpkg -i Omada_SDN_Controller_v5.14.26.1_linux_x64.deb
