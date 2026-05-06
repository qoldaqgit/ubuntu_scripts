#!/bin/bash
#wget https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/V2/install.sh

echo "Let's install Podman Rootless! but before we need to answer the following questions."

# Ask questions
read -p "Need PORTS under 1024 open (Restricted by default)? (y/n) " RESTRICTED_PORTS
read -p "Need composer/npm? (y/n) " EXTRA_TOOLS
read -p "Want to install Dockge (Podman Web UI)? (y/n) " DOCKGE

# Confirm input
echo ""
echo "Summary:"
echo "Need PORTS under 1024: $RESTRICTED_PORTS"
echo "Need composer/npm: $EXTRA_TOOLS"
echo "install Dockge: $DOCKGE"
echo ""

read -p "Proceed with these settings? (y/n) " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborted."
    exit 1
fi



sudo apt update && sudo apt upgrade -y
sudo apt-get -y install podman podman-compose nano qemu-guest-agent
if [[ "$EXTRA_TOOLS" == "y" ]]; then
sudo apt-get -y install composer npm
fi
echo "unqualified-search-registries = [\"docker.io\"]" | sudo tee -a /etc/containers/registries.conf

##### Create Required Dir/Files #####
sudo mkdir /app /app/stacks /app/.podman /app/data
sudo chmod 755 /app
sudo chown -R $USER:$USER /app/stacks /app/.podman /app/data
sudo chmod 700 /app/stacks /app/.podman /app/data

echo "#!/bin/bash" > /app/.podman/container-start.sh
echo "#!/bin/bash" > /app/.podman/container-start.sh

cat > ~/containers2restart.sh << 'EOF'
#!/bin/bash
if [ "$#" -eq 2 ]; then

    if [ ! -f "/app/.podman/container-start.sh" ]; then
        echo "#!/bin/bash
        " > /app/.podman/container-start.sh
        sudo chmod 771 /app/.podman/container-start.sh
        echo "/app/.podman/container-start.sh created"
    fi
    if [ ! -f "/app/.podman/container-stop.sh" ]; then
        echo "#!/bin/bash
        " >  /app/.podman/container-stop.sh
        sudo chmod 771 /app/.podman/container-stop.sh
        echo "/app/.podman/container-stop.sh created"
    fi

    if [ "$1" = "-start" ]; then
        if [[ -f $2 && ( $2 == *.yml || $2 == *.yaml ) ]]; then

            if ! grep -Fxq "/usr/bin/podman-compose -f $2 up -d" "/app/.podman/container-start.sh"; then
                echo "/usr/bin/podman-compose -f $2 up -d" >> "/app/.podman/container-start.sh"
                echo "Added to container-start"
            else
                echo "Skipping, already exist in container-start"
            fi

            if ! grep -Fxq "/usr/bin/podman-compose -f $2 down" "/app/.podman/container-stop.sh"; then
                echo "/usr/bin/podman-compose -f $2 down" >> "/app/.podman/container-stop.sh"
                echo "Added to container-stop"
            else
                echo "Skipping, already exist in container-stop"
            fi

        else
            echo "Invalid or missing file"
        fi
    fi

    if [ "$1" = "-stop" ]; then
    
        grep -Fv "/usr/bin/podman-compose -f $2 up -d" /app/.podman/container-start.sh > tmp && mv tmp /app/.podman/container-start.sh
        grep -Fv "/usr/bin/podman-compose -f $2 down" /app/.podman/container-stop.sh > tmp && mv tmp /app/.podman/container-stop.sh
        echo "Removed"
    fi

else
    echo "[-start/-stop] [path/to/compose/file]"
fi
EOF

#### Set proper permission to files #####
sudo chmod 771 /app/.podman/container-start.sh
sudo chmod 771 /app/.podman/container-start.sh
sudo chmod 771 ~/containers2restart.sh

##### Allow Lower ports for rootless Containers from (>1024) to (>=80) #####
if [[ "$RESTRICTED_PORTS" == "y" ]]; then
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80
echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee -a /etc/sysctl.conf
fi
##### Setup user enviroment #####
sudo loginctl enable-linger $USER
systemctl --user enable --now podman.socket

##### Create Service for AutoRun #########
bash -c 'echo "[Unit]
Description=Podman container-traefik.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=podman.service

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
Type=oneshot
RemainAfterExit=true

TimeoutStopSec=70
ExecStart=/app/.podman/container-start.sh 
ExecStop=/app/.podman/container-stop.sh 

[Install]
WantedBy=default.target
" > podman-autorun.service'

mv podman-autorun.service /home/vision/.config/systemd/user/podman-autorun.service
systemctl --user daemon-reload
systemctl --user enable podman-autorun.service
systemctl --user start podman-autorun.service



##### Install Dockge #####

if [[ "$DOCKGE" == "y" ]]; then
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
      - /app/stacks:/app/stacks
    environment:
      # Tell Dockge where is your stacks directory
      - DOCKGE_STACKS_DIR=/app/stacks
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

cd ~

##### Provide info to user #####
IPHOST=$(ip route get 1 | awk '{print $(NF-2); exit}')
echo "Finishing ....."
sleep 10
if curl -s --head http://$IPHOST:5001 | head -n 1 | grep "200" > /dev/null; then
  clear
  echo -e "\e[0;32m[~] Podman has been successfully installed!\e[0m"
  echo -e "\e[0;32m[~] Please visit http://$IPHOST:5001 to complete the initall setup wizard.\e[0m\n"
else
  echo "Install Failed"
fi
else
  clear
  podman ps
  echo -e "\e[0;32m[~] Podman Rootless has been successfully installed!\e[0m"
fi

