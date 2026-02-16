#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt-get -y install podman podman-compose nano qemu-guest-agent

##### Create Required Dir/Files #####
cd
mkdir podman .podman podman/auto_restart podman/manual_start
touch /home/podman/.podman/find_containers.sh
echo "#!/bin/bash" > /home/podman/.podman/containers-manager-restart.sh

chmod 771 /home/podman/.podman/find_containers.sh
chmod 771 /home/podman/.podman/containers-manager-restart.sh

##### Find Containers to restart on boot #######
##### Scans /home/podman/restart folders for "compose.yaml" ######
echo '#!/bin/bash

OUTPUT_FILE="/home/podman/.podman/containers-manager-restart.sh"
PREFIX="/usr/bin/podman-compose -f "
SUFFIX=" up -d"

echo "#!/bin/bash"> "$OUTPUT_FILE"

find "/home/podman/podman/auto_restart" -type f -name "compose.yaml" \
  | sed "s|^|$PREFIX|" \
  | sed "s|$|$SUFFIX|" \
  >> "$OUTPUT_FILE"

podman stop -a
  ' >> /home/podman/.podman/find_containers.sh

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
