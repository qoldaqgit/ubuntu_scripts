#!/bin/bash
#wget https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/V2/install.sh
sudo apt update && sudo apt upgrade -y
sudo apt-get -y install podman podman-compose nano qemu-guest-agent
echo "unqualified-search-registries = [\"docker.io\"]" | sudo tee -a /etc/containers/registries.conf
##### Create Required Dir/Files #####
cd
mkdir /app /app/stacks /app/.podman
sudo chmod 755 /app
sudo chown -R $USER:$USER /app/stacks /app/.podman
touch /app/.podman/find_containers.sh
echo "#!/bin/bash" > /app/.podman/containers-manager-restart.sh

##### Find running Containers to restart on boot #######
cat > /app/.podman/find_containers.sh << 'EOF'
#!/bin/bash

OUTPUT_FILE="/app/.podman/containers-manager-restart.sh"

echo "#!/bin/bash
" > "$OUTPUT_FILE"
podman ps --format "{{.Names}}" | while IFS= read -r line; do printf "podman start %s\n" "$line"; done >> "$OUTPUT_FILE"
podman stop -a
EOF

#### Set proper permission to files #####
chmod 771 /app/.podman/find_containers.sh
chmod 771 /app/.podman/containers-manager-restart.sh

##### Allow Lower ports for rootless Containers from (>1024) to (>=80) #####
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80
echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee -a /etc/sysctl.conf

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

ExecStartPre=
ExecStart=/app/.podman/containers-manager-restart.sh   
ExecStop=/app/.podman/find_containers.sh

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
      - /app/data:/app/data
      - ../:/root/dockge/stacks
    environment:
      # Tell Dockge where is your stacks directory
      - DOCKGE_STACKS_DIR=/root/dockge/stacks
      # (Optional) Allow console managment
      # - DOCKGE_ENABLE_CONSOLE=true
networks:
  intra_net:
    external: true
" > compose.yaml


##### Setup user enviroment #####
sudo loginctl enable-linger $USER
systemctl --user enable --now podman.socket

sudo systemctl stop podman-autorun.service
sudo systemctl start podman-autorun.service
sudo systemctl status podman-autorun.service

cd ~
#clear

#Provide info to user
IPHOST=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo -e "\e[0;32m[~] Podman has been successfully installed!\e[0m"
echo -e "\e[0;32m[~] Please visit http://$IPHOST:5001 to complete the initall setup wizard.\e[0m\n"#!/bin/bash
#wget https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/V2/install_with_dockge.sh
sudo apt update && sudo apt upgrade -y
sudo apt-get -y install podman podman-compose nano qemu-guest-agent
echo "unqualified-search-registries = [\"docker.io\"]" | sudo tee -a /etc/containers/registries.conf
##### Create Required Dir/Files #####
cd
mkdir .podman containers
touch /app/.podman/find_containers.sh
echo "#!/bin/bash" > /app/.podman/containers-manager-restart.sh

##### Find Containers to restart on boot #######
##### Scans /app/containers folders for "compose.yaml" ######
cat > /app/.podman/find_containers.sh << 'EOF'
#!/bin/bash

OUTPUT_FILE="/app/.podman/containers-manager-restart.sh"
PREFIX="/usr/bin/podman-compose -f "
SUFFIX=" up -d"

echo "#!/bin/bash
podman network create   --subnet 10.69.10.0/24   --gateway 10.69.10.1   intra_net"> "$OUTPUT_FILE"

find "/app/containers" -type f \( -name "compose.yaml" -o -name "composer.yml" \) | \
while read -r file; do
    if grep -qE '^ {4}restart: (unless-stopped|always)$' "$file"; then
        echo "${PREFIX}${file}${SUFFIX}" >> "$OUTPUT_FILE"
    fi
done

podman stop -a
EOF

#### Set proper permission to files #####
chmod 771 /app/.podman/find_containers.sh
chmod 771 /app/.podman/containers-manager-restart.sh

##### Allow Lower ports for rootless Containers from (>1024) to (>=80) #####
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80
echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee -a /etc/sysctl.conf

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
ExecStart=/app/.podman/containers-manager-restart.sh   
ExecStop=/app/.podman/find_containers.sh

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
      # - DOCKGE_ENABLE_CONSOLE=true
networks:
  intra_net:
    external: true
" > compose.yaml


##### Setup user enviroment #####
sudo loginctl enable-linger $USER
systemctl --user enable --now podman.socket

sudo systemctl stop podman-autorun.service
sudo systemctl start podman-autorun.service
sudo systemctl status podman-autorun.service

cd ~
#clear

#Provide info to user
IPHOST=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo -e "\e[0;32m[~] Podman has been successfully installed!\e[0m"
echo -e "\e[0;32m[~] Please visit http://$IPHOST:5001 to complete the initall setup wizard.\e[0m\n"
