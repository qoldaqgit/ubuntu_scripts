#https://www.youtube.com/watch?v=69dADRzXpqk
#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/Zammad/zammad.sh | bash
#!/bin/bash
PODUSER="podmanuser"
#MFOLDER="zammad"
#Confirm user exist, if not create
if ! id "podmanuser" &>/dev/null; then
    sudo useradd -m -s /bin/bash podmanuser
fi
#Login into user home folder
sudo su podmanuser
cd
#Setup containers Drives
mkdir -p zammad zammad/zammad-storage zammad/zammad-backup zammad/elasticsearch-data  zammad/postgresql-data zammad/redis-data zammad/
cd zammad
#Create container compose file
wget https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/Zammad/docker-compose.yml
wget https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/Zammad/.env

#Create or add to the containers manager file
cd
FILE="containers-manager.sh"
LINE="
#Zammad - Ticket System
/usr/bin/podman-compose -f /home/podmanuser/zammad/docker-compose.yml up -d
#Ports #8080"

# Create file if it doesn't exist and set executable permissions
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi
# Append line to the file
echo "$LINE" >> "$FILE"
exit

#Adjust your host’s settings to run Elasticsearch properly:
sysctl -w vm.max_map_count=262144
#Restart the service
sudo systemctl stop podman-run.service
sudo systemctl start podman-run.service
#Provide info to user
IPHOST=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo -e "\e[0;32m[~] Zammad has been successfully installed! :)\e[0m"
echo -e "\e[0;32m[~] Please visit http://$IPHOST:8080 to complete the inital setup wizard.\e[0m\n"
