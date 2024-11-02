mkdir -p gitea/{data,config}
cd gitea
touch docker-compose.yml

echo 'version: "3"

networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:1.16.5
    container_name: gitea
    restart: unless-stopped
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /home/git/.ssh/:/data/git/.ssh
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "80:3000"
      - "2222:22"' > ~/gitea/docker-compose.yml

sudo docker-compose up -d
