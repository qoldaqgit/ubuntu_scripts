#/bin/bash

# wget https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Promox/ct_template_cleaner.sh
if [[ $# -eq 1 ]]
then
sudo apt update && sudo apt upgrade -y
sudo adduser $1
sudo usermod -aG sudo $1
sudo apt clean
sudo apt autoremove
sudo rm /etc/ssh/ssh_host_*
sudo truncate -s 0 /etc/machine-id

touch ssh_config.sh
echo "sudo dpkg-reconfigure openssh-server" > ssh_config.sh

rm ct_template_cleaner.sh
sudo shutdown 0

else
echo "please provide a [[username]]"
fi