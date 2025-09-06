#https://www.youtube.com/watch?v=69dADRzXpqk
#  curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/podman_install.sh | bash
#!/bin/bash

  apt-get update
  apt-get -y install podman podman-compose nano qemu-guest-agent

#Enable docker.io repository
echo "unqualified-search-registries = [\"docker.io\"]" |   tee -a /etc/containers/registries.conf
echo "net.ipv4.ip_unprivileged_port_start=40" |   tee -a /etc/sysctl.d/98-containers.conf
  sysctl --system

systemctl --user enable --now podman.socket

  useradd -m -s /bin/bash podmanuser

## Creating autorun
FILE="/home/podmanuser/containers-manager.sh"
if [ ! -f "$FILE" ]; then
    touch "$FILE"
    chmod +x "$FILE"
    echo "#!/bin/bash" > "$FILE"
fi

echo "[Unit]
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
" > /etc/systemd/system/podman-run.service

  systemctl --system daemon-reload
  systemctl enable podman-run.service
  systemctl start podman-run.service

echo "For PiHole run"
echo "  curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/PiHole.sh | bash"
echo ""
echo "For Nginx Proxy Manager run"
echo "  curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/NginxProxy.sh | bash"
#loginctl enable-linger podmanuser
#delete stoped containers
#podman container prune
