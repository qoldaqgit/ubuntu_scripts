#https://www.youtube.com/watch?v=69dADRzXpqk
#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/NginxProxy.sh | bash
#!/bin/bash
#Confirm user exist, if not create
if ! id "podmanuser" &>/dev/null; then
    sudo useradd -m -s /bin/bash podmanuser
else
    echo "User 'username' already exists."
fi
#Login into user home folder
sudo su podmanuser
cd
#Setup containers Drives
mkdir -p nginx nginx/data nginx/letsencrypt
#Create container compose file
echo "version: '3.8'
services:
  app:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '8080:80'
      - '8081:81'
      - '8443:443'
    volumes:
      - ./nginx/data:/data
      - ./nginx/letsencrypt:/etc/letsencrypt" > /home/podmanuser/nginx/docker-compose.yaml

#Create or add to the containers manager file
cd ~/
FILE="containers-manager.sh"
LINE='/usr/bin/podman-compose -f /home/podmanuser/nginx/docker-compose.yaml up -d'

# Create file if it doesn't exist and set executable permissions
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi

# Append line to the file
echo "$LINE" >> "$FILE"

exit
