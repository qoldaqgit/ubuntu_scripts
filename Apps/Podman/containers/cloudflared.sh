#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/containers/cloudflared.sh | bash
#!/bin/bash

cd ~/containers
#Setup containers Drives
mkdir -p cloudflared
cd cloudflared
#Create container compose file
echo "
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    environment:
      - TUNNEL_TOKEN=${TOKEN}
    restart: unless-stopped
    command: tunnel --no-autoupdate run
    networks:
      - cloudflarednetwork
networks:
  cloudflarednetwork:
    name: cloudflared" > compose.yaml

#Create .env file
echo "TOKEN=your-tunnel-tokken-here" > .env
