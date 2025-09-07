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
sudo loginctl enable-linger podmanuser

# this might be needed for cleaning: ExecStartPre=/usr/bin/podman system prune -f
sudo bash -c 'echo "[Unit]
Description=Podman-run
Wants=network-online.target
After=network-online.target

[Service]
User=podmanuser
Group=podmanuser
Type=oneshot
RemainAfterExit=true

ExecStart=/home/podmanuser/containers-manager.sh     
ExecStop=/usr/bin/podman-compose down 

[Install]
WantedBy=default.target
" > /etc/systemd/system/podman-run.service'

sudo systemctl --system daemon-reload
sudo systemctl enable podman-run.service


#create file to display containers list
echo '
clear
sudo systemd-run --machine=podmanuser@ --quiet --user --collect --pipe --wait podman container ps --all  --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | while read -r name status image; do
  short_image="${image##*/}"  # Strip everything before last /
  
  if [[ "$status" =~ ^Exited ]]; then
    #echo -e "\e[31m$status\t$name\t\t$short_image\e[0m"
    printf "\033[0;31m%-10s %-40s %-30s\033[0m\n" "$status" "$name" "$short_image" 

  else
    #echo -e "$status\t$name\t\t$short_image"
    printf "%-10s %-40s %-30s\n" "$status" "$name" "$short_image"
  fi
done
' > containers-list.sh


echo ""
echo "Install Nginx Proxy Manager"
echo "sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/NginxProxy.sh | bash"
echo ""
echo "Intall Zammad - Ticket System"
echo "sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/Zammad/zammad.sh | bash"
echo ""




#delete stoped containers
#podman container prune
