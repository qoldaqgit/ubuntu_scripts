#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/V2/cloudflared.sh | bash
#!/bin/bash

cd ~/dockge/stacks
#Setup containers Drives
mkdir -p cloudflared
cd cloudflared
#Create container compose file
echo "
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
    name: cloudflared" > compose.yaml

#Create or add to the containers manager file
cd ~
##### Create the controllers files #######
FILE="containers-manager-up.sh"
LINE="
#Cloudflare
/usr/bin/podman-compose -f /home/podman/dockge/stacks/cloudflared/compose.yaml up -d
#Ports --"

# Create file if it doesn't exist and set executable permissions
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi

# Append line to the file
echo "$LINE" >> "$FILE"

FILE="containers-manager-down.sh"
LINE="
#Cloudflare
/usr/bin/podman-compose -f /home/podman/dockge/stacks/cloudflared/compose.yaml down
#Ports --"

# Create file if it doesn't exist and set executable permissions
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi

# Append line to the file
echo "$LINE" >> "$FILE"
