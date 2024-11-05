#/bin/bash

# bash -c "$(wget -qLO - )"
if [[ $# -eq 1 ]]
then
sudo apt update && sudo apt upgrade -y
sudo adduser $1
sudo usermod aG sudo $1
sudo apt clean
sudo apt autoremove
sudo rm /etc/ssh/ssh_host_*
sudo trunncate -ss 0 /etc/machine-id
sudo shutdown 0

else
echo "please provide a [[username]]"
fi
