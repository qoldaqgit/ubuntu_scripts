mkdir -p gitea/{data,config}
cd gitea
touch docker-compose.yml

echo 'version: "2"

services:
  server:
    image: gitea/gitea:1.22.3-rootless
    restart: always
    volumes:
      - ./data:/var/lib/gitea
      - ./config:/etc/gitea
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "2222:2222"' > ~/gitea/docker-compose.yml

sudo docker-compose up -d
