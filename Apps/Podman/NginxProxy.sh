#https://www.youtube.com/watch?v=69dADRzXpqk
#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/NginxProxy.sh | bash
#!/bin/bash
PODUSER="podmanuser"
#MFOLDER="nginx"
#Confirm user exist, if not create
if ! id "podmanuser" &>/dev/null; then
    sudo useradd -m -s /bin/bash podmanuser
else
    echo "User 'podmanuser' already exists."
fi
#Login into user home folder
sudo su podmanuser
cd
#Setup containers Drives
mkdir -p nginx nginx/data nginx/letsencrypt
cd nginx
#Create container compose file
echo "version: '3.8'
services:
  app:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt" > docker-compose.yaml

#Create or add to the containers manager file
cd
FILE="containers-manager.sh"
LINE="
#Nginx Proxy Manager
/usr/bin/podman-compose -f /home/podmanuser/nginx/docker-compose.yaml up -d
#Ports #80,#81,#443"

# Create file if it doesn't exist and set executable permissions
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi

# Append line to the file
echo "$LINE" >> "$FILE"

exit

#uninstall NGINX
#sudo systemctl stop podman-run.service
#sudo sed -i 's/Nginx Proxy Manager
#/usr/bin/podman-compose -f /home/podmanuser/nginx/docker-compose.yaml up -d
#Ports #80,#81,#443//g' /home/podmanuser/containers-manager.sh

#sudo rm -r /home/podmanuser/nginx
#sudo systemctl start podman-run.service

sudo systemctl stop podman-run.service
sudo systemctl start podman-run.service
IPHOST=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo -e "\e[0;32m[~] NGINX Proxy Manager has been successfully installed! :)\e[0m"
echo -e "\e[0;32m[~] Please visit http://$IPHOST:81 to complete the inital setup wizard.\e[0m\n"
echo "username : admin@example.com"
echo "password : changeme"
