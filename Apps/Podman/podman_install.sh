#https://www.youtube.com/watch?v=69dADRzXpqk
#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/podman_install.sh | bash
#!/bin/bash

sudo apt-get update
sudo apt-get -y install podman podman-compose nano qemu-guest-agent

#Enable docker.io repository
echo "unqualified-search-registries = [\"docker.io\"]" | sudo tee -a /etc/containers/registries.conf
echo "net.ipv4.ip_unprivileged_port_start=40" | sudo tee -a /etc/sysctl.d/98-containers.conf
sudo sysctl --system

systemctl --user enable --now podman.socket

sudo useradd -m -s /bin/bash podmanuser

## Creating autorun
FILE="/home/podmanuser/containers-manager.sh"
if [ ! -f "$FILE" ]; then
    sudo touch "$FILE"
    sudo chmod +x "$FILE"
    sudo bash -c 'echo "#!/bin/bash" > "$FILE"'
fi

sudo bash -c 'echo "[Unit]
Description=Podman-run
Wants=network-online.target
After=network-online.target

[Service]
User=podmanuser
Group=podmanuser
Type=oneshot
RemainAfterExit=true
ExecStartPre=/usr/bin/podman system prune -f
ExecStart=/home/podmanuser/containers-manager.sh     
ExecStop=/usr/bin/podman-compose down 

[Install]
WantedBy=default.target
" > /etc/systemd/system/podman-run.service'

sudo systemctl --system daemon-reload
sudo systemctl enable podman-run.service
sudo systemctl start podman-run.service

echo "For PiHole run"
echo "sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/PiHole.sh | bash"
echo ""
echo "For Nginx Proxy Manager run"
echo "sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/NginxProxy.sh | bash"
#loginctl enable-linger podmanuser
#delete stoped containers
#podman container prune
