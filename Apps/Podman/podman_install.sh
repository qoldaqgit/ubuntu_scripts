#https://www.youtube.com/watch?v=69dADRzXpqk
#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/podman_install.sh | bash
#!/bin/bash

sudo apt-get update
sudo apt-get -y install podman podman-compose

#systemctl --user enable --now podman.socket

#Enable docker.io repository
echo "unqualified-search-registries = [\"docker.io\"]" | sudo tee -a /etc/containers/registries.conf

sudo useradd -m -s /bin/bash podmanuser

echo "For PiHole run"
echo "sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/PiHole.sh | bash"
echo ""
echo "For Nginx Proxy Manager run"
echo "sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/NginxProxy.sh | bash"
#loginctl enable-linger podmanuser
#delete stoped containers
#podman container prune
