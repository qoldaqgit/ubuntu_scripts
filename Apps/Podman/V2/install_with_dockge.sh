#!/bin/bash
#wget https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/V2/install_with_dockge.sh
sudo apt update && sudo apt upgrade -y
sudo apt-get -y install podman podman-compose nano qemu-guest-agent

##### Create Required Dir/Files #####
cd
mkdir .podman containers
touch /home/podman/.podman/find_containers.sh
echo "#!/bin/bash" > /home/podman/.podman/containers-manager-restart.sh

chmod 771 /home/podman/.podman/find_containers.sh
chmod 771 /home/podman/.podman/containers-manager-restart.sh

##### Find Containers to restart on boot #######
##### Scans /home/podman/restart folders for "compose.yaml" ######
cat > /home/podman/.podman/find_containers.sh << 'EOF'
#!/bin/bash

OUTPUT_FILE="/home/podman/.podman/containers-manager-restart.sh"
PREFIX="/usr/bin/podman-compose -f "
SUFFIX=" up -d"

echo "#!/bin/bash"> "$OUTPUT_FILE"

find "/home/podman/containers" -type f \( -name "compose.yaml" -o -name "composer.yml" \) | \
while read -r file; do
    if grep -qE '^ {4}restart: (unless-stopped|always)$' "$file"; then
        echo "${PREFIX}${file}${SUFFIX}" >> "$OUTPUT_FILE"
    fi
done

podman image rm -a
podman stop -a
podman system prune -f
EOF

##### Create Service for AutoRun #########
sudo bash -c 'echo "[Unit]
Description=Podman-autorun
Wants=network-online.target
After=network-online.target

[Service]
User=podman
Group=podman
Type=oneshot
RemainAfterExit=true

ExecStartPre=/usr/bin/podman system prune -f
ExecStart=/home/podman/.podman/containers-manager-restart.sh   
ExecStop=/home/podman/.podman/find_containers.sh

[Install]
WantedBy=default.target
" > /etc/systemd/system/podman-autorun.service'

sudo systemctl --system daemon-reload
sudo systemctl enable podman-autorun.service
sudo systemctl start podman-autorun.service

cd
##### Install Dockge #####
mkdir containers/dockge && cd containers/dockge
echo "services:
  dockge:
    image: louislam/dockge:1
    container_name: dockge
    restart: unless-stopped
    ports:
      # Host Port : Container Port
      - 5001:5001
    volumes:
      - /run/user/1000/podman/podman.sock:/var/run/docker.sock
      - ./data:/app/data
      - ../:/root/dockge/stacks
    environment:
      # Tell Dockge where is your stacks directory
      - DOCKGE_STACKS_DIR=/root/dockge/stacks
      # (Optional) Allow console managment
      - DOCKGE_ENABLE_CONSOLE=true
" > compose.yaml

sudo systemctl stop podman-autorun.service
sudo systemctl start podman-autorun.service

cd ~
clear
echo "Installation Completed"
#Provide info to user
IPHOST=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo -e "\e[0;32m[~] Podman has been successfully installed! :)\e[0m"
echo -e "\e[0;32m[~] Please visit http://$IPHOST:5001 to complete the inital setup wizard.\e[0m\n"
