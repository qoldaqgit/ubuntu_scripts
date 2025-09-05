#https://www.youtube.com/watch?v=69dADRzXpqk
#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/Portainer.sh | bash
#!/bin/bash
PODUSER="podmanuser"
#MFOLDER="portainer"
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
mkdir -p portainer portainer/data
cd portainer
#Create container compose file
echo "version: '3.3'
services:
  app:
    image: 'docker.io/portainer/portainer-ce:latest'
    restart: unless-stopped
    ports:
      - '8000:8000'
      - '9000:9000'
    volumes:
      - /var/run/docker.sock:/vavr/run/docker.sock
      - ./data:/data" > docker-compose.yaml

#Create or add to the containers manager file
cd
FILE="containers-manager.sh"
LINE="
#Ngix Proxy Manager
/usr/bin/podman-compose -f /home/podmanuser/portainer/docker-compose.yaml up -d
#Ports #8000,#9000"

# Create file if it doesn't exist and set executable permissions
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi

# Append line to the file
echo "$LINE" >> "$FILE"

exit
echo -e "\e[0;32m[~] Portainer has been successfully installed! :)\e[0m"
echo -e "\e[0;32m[~] Please visit https://${hostIP}:9000 to complete the inital setup wizard.\e[0m\n"
