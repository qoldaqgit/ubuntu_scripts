#!/bin/bash
#wget https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/V2/install.sh
sudo apt update && sudo apt upgrade -y
sudo apt-get -y install podman podman-compose nano qemu-guest-agent
echo "unqualified-search-registries = [\"docker.io\"]" | sudo tee -a /etc/containers/registries.conf

##### Create Required Dir/Files #####
sudo mkdir /app /app/stacks /app/.podman /app/data
sudo chmod 755 /app
sudo chown -R $USER:$USER /app/stacks /app/.podman /app/data
touch /app/.podman/find_containers.sh
echo "#!/bin/bash" > /app/.podman/containers-manager-restart.sh

##### Find running Containers to restart on boot (current running)#######
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

##### Setup user enviroment #####
sudo loginctl enable-linger $USER
systemctl --user enable --now podman.socket

##### Create Service for AutoRun #########
sudo bash -c 'echo "[Unit]
Description=Podman-autorun
Wants=network-online.target
After=network-online.target

[Service]
User=1000
Group=1000
Type=oneshot
RemainAfterExit=true

ExecStartPre=
ExecStart=/app/.podman/containers-manager-restart.sh   
ExecStop=/app/.podman/find_containers.sh

[Install]
WantedBy=default.target
" > /etc/systemd/system/podman-autorun.service'

##### Install Dockge #####
cd /app/data
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
      - /app/stacks:/root/dockge/stacks
    environment:
      # Tell Dockge where is your stacks directory
      - DOCKGE_STACKS_DIR=/root/dockge/stacks
      # (Optional) Allow console managment
      # - DOCKGE_ENABLE_CONSOLE=true
networks:
  intra_net:
  ##ip: 10.69.10.2
    external: true
" > compose.yaml
##### Setup Dockge env and start #####
podman network create   --subnet 10.69.10.0/24   --gateway 10.69.10.1   intra_net
podman-compose up -d

##### Setup the auto restart #####
sudo systemctl --system daemon-reload
sudo systemctl enable podman-autorun.service
sudo systemctl start podman-autorun.service
sudo systemctl status podman-autorun.service

cd ~
#clear

##### Provide info to user #####
IPHOST=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo -e "\e[0;32m[~] Podman has been successfully installed!\e[0m"
echo -e "\e[0;32m[~] Please visit http://$IPHOST:5001 to complete the initall setup wizard.\e[0m\n"
