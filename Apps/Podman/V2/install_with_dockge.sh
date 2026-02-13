#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt-get -y install podman podman-compose nano qemu-guest-agent

mkdir dockge && cd dockge
echo "services:
  dockge:
    image: louislam/dockge:1
    restart: unless-stopped
    ports:
      # Host Port : Container Port
      - 5001:5001
    volumes:
      - /run/user/1000/podman/podman.sock:/var/run/docker.sock
      - ./data:/app/data
      - /home/podman/dockge/stacks:/root/dockge/stacks
    environment:
      # Tell Dockge where is your stacks directory
      - DOCKGE_STACKS_DIR=/root/dockge/stacks
      # (Optional) Allow console managment
      - DOCKGE_ENABLE_CONSOLE=true
" > compose.yml
cd ~

##### Create the controllers files #######
FILE="containers-manager-up.sh"
LINE="
#Dockge
/usr/bin/podman-compose -f /home/podman/dockge/compose.yml up -d
#Ports #5001"

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
#Dockge
/usr/bin/podman-compose -f /home/podman/dockge/compose.yml down
#Ports #5001"

# Create file if it doesn't exist and set executable permissions
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi

# Append line to the file
echo "$LINE" >> "$FILE"


##### Create Service for auto restart #########
sudo bash -c 'echo "[Unit]
Description=Podman-run
Wants=network-online.target
After=network-online.target

[Service]
User=podman
Group=podman
Type=oneshot
RemainAfterExit=true

ExecStartPre=/usr/bin/podman system prune -f
ExecStart=/home/podman/containers-manager-up.sh     
ExecStop=/home/podman/containers-manager-down.sh     

[Install]
WantedBy=default.target
" > /etc/systemd/system/podman-run.service'

sudo systemctl --system daemon-reload
sudo systemctl enable podman-run.service


