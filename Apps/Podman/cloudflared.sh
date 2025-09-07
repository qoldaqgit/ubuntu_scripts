#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/cloudflared.sh | bash
#!/bin/bash
PODUSER="podmanuser"
#Confirm user exist, if not create
if ! id "podmanuser" &>/dev/null; then
    sudo useradd -m -s /bin/bash podmanuser
fi
#Login into user home folder
sudo su podmanuser
cd
#Setup containers Drives
mkdir -p cloudflared
cd cloudflared
#Create container compose file
echo "version: "3.8"
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    environment:
      - TUNNEL_TOKEN=${TOKEN}
    restart: unless-stopped
    command: tunnel --no-autoupdate run
    networks:
      - cloudflarednetwork
networks:
  cloudflarednetwork:
    name: cloudflared" > docker-compose.yaml

#Create or add to the containers manager file
cd
FILE="containers-manager.sh"
LINE="
#Cloudflared - Proxy Tunnel
/usr/bin/podman-compose -f /home/podmanuser/cloudflared/docker-compose.yaml up -d
#Ports --"

# Create file if it doesn't exist and set executable permissions
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi

# Append line to the file
echo "$LINE" >> "$FILE"

exit

sudo systemctl stop podman-run.service
sudo systemctl start podman-run.service
IPHOST=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo -e "\e[0;32m[~] Cloudflared has been successfully installed! :)\e[0m"
