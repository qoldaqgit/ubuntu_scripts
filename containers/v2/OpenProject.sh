#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/containers/v2/OpenProject.sh | bash
mkdir -p openproject/{data,assets}
cd openproject

echo "version: '3.8'
services:
  openproject:
    image: openproject/openproject:16
    container_name: openproject
    ports:
      - '8180:80'
    environment:
      OPENPROJECT_HOST__NAME: 10.10.10.30:8180
      OPENPROJECT_SECRET_KEY_BASE: mrMI3p1BCMkHNSsxdy1alWH4E94tC7qY
      OPENPROJECT_HTTPS: false
    volumes:
      - ~/openproject/data:/var/openproject/pgdata
      - ~/openproject/assets:/var/openproject/assets
    restart: unless-stopped
" > ~/openproject/docker-compose.yaml

sudo touch /lib/systemd/system/podman-run.service
echo "
[Unit]
Description=Podman-openproject
Wants=network-online.target
After=network-online.target

[Service]
User=podmanuser
Group=podmanuser
Type=oneshot
RemainAfterExit=true
ExecStartPre=/usr/bin/podman system prune -f
ExecStart=/usr/bin/podman-compose -f /home/podmanuser/openproject/docker-compose.yaml up -d
ExecStop=/user/bin/podman-compose down

[Install]
WantedBy=default.target" | sudo tee -a /lib/systemd/system/podman-openproject.service

sudo systemctl --system daemon-reload

sudo systemctl enable podman-openproject.service
sudo systemctl start podman-openproject.service
