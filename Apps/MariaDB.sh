sudo apt update && sudo apt upgrade -y
sudo apt install qemu-guest-agent


sudo apt install mariadb-server mariadb-client -y
sudo mysql_secure_installation

#Change the root password? [Y/n] n
#Remove anonymous users? [Y/n] y
#Disallow root login remotely? [Y/n] y
#Remove test database and access to it? [Y/n] y
#Reload privilege tables now? [Y/n] y

sudo mysql
  CREATE USER 'newuser'@'localhost' IDENTIFIED BY '1234';
  GRANT ALL PRIVILEGES ON *.* TO 'newuser'@'localhost';
  FLUSH PRIVILEGES;


CREATE USER 'dbmaster'@'%' IDENTIFIED VIA mysql_native_password USING '1234';
GRANT ALL PRIVILEGES ON *.* TO 'dbmaster'@'%';

sudo sed -i 's/bind-address = 127.0.0.1/bind-address = 0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf


sudo apt install apache2 php libapache2-mod-php php-mysql phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y

sudo ufw allow 3306/tcp
