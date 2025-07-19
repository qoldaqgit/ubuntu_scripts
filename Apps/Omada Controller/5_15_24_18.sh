#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Omada%20Controller/5_15_24_18.sh | bash
#!/bin/bash

#Ubuntu 22.04 
#Omada Controller 5.15.24.18
clear
echo '#######################################################'
echo '##                                                   ##'
echo '##    Installation of Omada Controller 5.15.24.18    ##'
echo '##                                                   ##'
echo '#######################################################'

apt update && apt upgrade -y
apt install openjdk-11-jre-headless
sudo apt install autoconf make gcc
wget https://archive.apache.org/dist/commons/daemon/source/commons-daemon-1.2.4-src.tar.gz
tar zxvf commons-daemon-x.y.z-src.tar.gz
cd commons-daemon-x.y.z-src/src/native/unix
sh support/buildconf.sh
./configure --with-java=/usr/lib/jvm/java-11-openjdk-amd64 (default path of OpenJDK-11-JDK)
make
ln –s /YOUR_ABSOLUTE_PATH/commons-daemon-1.2.4-src/src/native/unix/jsvc /usr/bin/

#Mongo V7
sudo apt-get install gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
--dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt-get update
sudo apt-get install mongodb-org=7.0.7 mongodb-org-database=7.0.7 mongodb-org-server=7.0.7 mongodb-mongosh=7.0.7 mongodb-org-mongos=7.0.7 mongodb-org-tools=7.0.7 -y

#Omado
wget https://static.tp-link.com/upload/software/2025/202507/20250703/omada_v5.15.24.18_linux_x64_20250630184434.deb
sudo dpkg -i omada_v5.15.24.18_linux_x64_20250630184434.deb
