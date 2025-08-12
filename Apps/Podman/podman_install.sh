#https://www.youtube.com/watch?v=69dADRzXpqk
#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/podman_install.sh | bash
#!/bin/bash

sudo apt-get update
sudo apt-get -y install podman podman-compose

#systemctl --user enable --now podman.socket

#Enable docker.io repository
echo "unqualified-search-registries = [\"docker.io\"]" | sudo tee -a /etc/containers/registries.conf

sudo useradd -m -s /bin/bash podmanuser
sudo su podmanuser
cd
#Setup containers Drives
mkdir nginx nginx/data nginx/letsencrypt

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
      - ./nginx/letsencrypt:/etc/letsencrypt" | tee -a docker-compose.yaml
exit
sudo touch /lib/systemd/system/podman-run.service
echo "
[Unit]
Description=Podman-run
Wants=network-online.target
After=network-online.target

[Service]
User=podmanuser
Group=podmanuser
Type=oneshot
RemainAfterExit=true
ExecStartPre=/usr/bin/podman system prune -f
ExecStart=/usr/bin/podman-compose -f /home/podmanuser/docker-compose.yaml up -d
ExecStop=/user/bin/podman-compose down

[Install]
WantedBy=defaul.target" | sudo tee -a /lib/systemd/system/podman-run.service

sudo systemctl --system daemon-reload

sudo systemctl enable podman-run.service
sudo systemctl start podman-run.service


#delete stoped containers
#podman container prune
