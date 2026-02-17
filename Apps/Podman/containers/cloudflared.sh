#sudo curl -sSL https://raw.githubusercontent.com/qoldaqgit/ubuntu_scripts/refs/heads/main/Apps/Podman/containers/cloudflared.sh | bash
#!/bin/bash

cd ~/containers
#Setup containers Drives
mkdir -p cloudflared
cd cloudflared
#Create container compose file
cat > compose.yaml << 'EOF'
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    environment:
      - TUNNEL_TOKEN=${TOKEN}
    restart: unless-stopped
    command: tunnel --no-autoupdate run
    networks:
      - intra_net
networks:
  intra_net:
    external: true
EOF

#Create .env file
echo "TOKEN=your-tunnel-tokken-here" > .env
